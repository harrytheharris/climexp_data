#!/bin/sh

# get the CMORPH 1.0 data once
if [ ! -s downloaded_old_cmorph_data ]; then
    wget -N -r ftp://ftp.cpc.ncep.noaa.gov/precip/CMORPH_V1.0/RAW/0.25deg-DLY_00Z/
    date > downloaded_old_cmorph_data
fi
yr=`date +%Y`
yr1=$((yr-1))
date=`date +%Y%m%d`
if [ ! -s downloaded_cmorph_$date ]; then
    # the remainder of v1.0
    wget -N -r ftp://ftp.cpc.ncep.noaa.gov/precip/CMORPH_V1.0/RAW/0.25deg-DLY_00Z/$yr1/${yr1}12
    wget -N -r ftp://ftp.cpc.ncep.noaa.gov/precip/CMORPH_V1.0/RAW/0.25deg-DLY_00Z/$yr/
    # v0.x for the rest
    wget -N -r ftp://ftp.cpc.ncep.noaa.gov/precip/CMORPH_V0.x/RAW/0.25deg-DLY_00Z/$yr1/${yr1}12
    wget -N -r ftp://ftp.cpc.ncep.noaa.gov/precip/CMORPH_V0.x/RAW/0.25deg-DLY_00Z/$yr/

    # get GrADS control files
    wget -N -r ftp://ftp.cpc.ncep.noaa.gov/precip/CMORPH_V0.x/CTL
    wget -N -r ftp://ftp.cpc.ncep.noaa.gov/precip/CMORPH_V1.0/CTL

    date > downloaded_cmorph_$date
fi

# convert to monthly netcdf files
[ ! -d CMORPH ] && mkdir CMORPH
ncfiles=""
nc1files=""
root=ftp.cpc.ncep.noaa.gov/precip/CMORPH_V1.0/RAW/0.25deg-DLY_00Z
yyyy=1998
m=1
mm=01
version="1.0"
ok=true
while [ $ok = true ]; do
    ###echo $yyyy$mm
    file=$root/$yyyy/$yyyy$mm/CMORPH_V1.0_RAW_0.25deg-DLY_00Z_${yyyy}${mm}01
    if [ -s ${file}.gz ]; then
        ext=gz
    elif [ -s ${file}.bz2 ]; then
        ext=bz2
    else
        file=`echo $file | sed -e 's/V1.0/V0.x/g'`
        version="0.x"
        if [ -s $file.bz2 ]; then
            ext=bz2
        else
            echo "$0: cannot find $file"
            ok=false
        fi
    fi
    if [ $ok = true ]; then
        ncfiles="$ncfiles CMORPH/cmorph_$yyyy$mm.nc"
        nc1files="$nc1files CMORPH/cmorph_$yyyy${mm}_05.nc"
    fi
    if [ $ok = true -a \( ! -s CMORPH/cmorph_$yyyy$mm.nc -o $yyyy = $yr \) ]; then
        case $m in
            1) month=jan;dpm=31;;
            2) month=feb;dpm=28;;
            3) month=mar;dpm=31;;
            4) month=apr;dpm=30;;
            5) month=may;dpm=31;;
            6) month=jun;dpm=30;;
            7) month=jul;dpm=31;;
            8) month=aug;dpm=31;;
            9) month=sep;dpm=30;;
            10) month=oct;dpm=31;;
            11) month=nov;dpm=30;;
            12) month=dec;dpm=31;;
            *) echo "error bhfwigfwj";exit -1;;
        esac
        if [ $dpm = 28 -a $((yyyy%4)) = 0 ]; then
            dpm=29
        fi
        echo "making CMORPH/cmorph_$yyyy$mm.nc"
        d=1
        dd=`printf %02i $d`
        dfile=${file%01}$dd
        list=""
        while [ -s $dfile.$ext ]; do
            if [ $ext = gz ]; then
                ###echo "gunzip $dfile.$ext"
                gunzip -c $dfile.$ext > $dfile
            elif [ $ext = bz2 ]; then
                ###echo "bunzip2 $dfile.$ext"
                bunzip2 -c $dfile.$ext > $dfile
            else
                echo "unknown ext $ext"; exit -1
            fi
            list="$list $dfile"
            d=$((d+1))
            dd=`printf %02i $d`
            dfile=${file%01}$dd
            if [ ! -s $dfile.$ext -a $yyyy -lt $yr -a $d -le $dpm ]; then
                echo "$0: inserting day of undefs at $yyyy$mm$dd"
                makeundef 1440 480 1 -999.0 $dfile
                if [ $ext = gz ]; then
                    gzip $dfile
                elif [ $ext = bz2 ]; then
                    bzip2 $dfile
                fi
            fi
        done
        if [ $d -le $dpm -a $yyyy -lt $yr ]; then
            echo "$0: something went wrong in $yyyy$mm, cannot find or make $dfile.$ext"
            exit -1
        fi
        ###echo "cat $list"
        cat $list > CMORPH/cmorph_$yyyy$mm.grd
        rm $list
        cat > CMORPH/cmorph_$yyyy$mm.ctl <<EOF
DSET ^cmorph_$yyyy$mm.grd
TITLE CMORPH Version $version, RAW daily precip from 00Z-24Z
OPTIONS little_endian
UNDEF  -999.0
XDEF 1440 LINEAR    0.125  0.25
YDEF  480 LINEAR  -59.875  0.25
ZDEF   01 LEVELS 0
TDEF $((d-1)) LINEAR  01$month$yyyy 1dy
VARS 1
prcp   1   99 daily precipitation [mm/dy]  
ENDVARS
EOF
        echo "grads2nc CMORPH/cmorph_$yyyy$mm.ctl CMORPH/cmorph_$yyyy$mm.nc"
        grads2nc CMORPH/cmorph_$yyyy$mm.ctl aap.nc
        # save lots of disk space
        cdo -r -f nc4 -z zip copy aap.nc CMORPH/cmorph_${yyyy}${mm}.nc
        ###ls -l aap.nc CMORPH/cmorph_${yyyy}${mm}.nc
        rm CMORPH/cmorph_$yyyy$mm.ctl CMORPH/cmorph_$yyyy$mm.grd aap.nc
        averagefieldspace CMORPH/cmorph_$yyyy$mm.nc 2 2 aap.nc
        cdo -r -f nc4 -z zip copy aap.nc CMORPH/cmorph_$yyyy${mm}_05.nc
    fi
    m=$((m+1))
    if [ $m = 13 ]; then
        m=$((m-12))
        yyyy=$((yyyy+1))
    fi
    mm=`printf %02i $m`
done
echo cdo -r -f nc4 -z zip copy $nc1files cmorph_daily_05.nc
cdo -r -f nc4 -z zip copy $nc1files cmorph_daily_05.nc
$HOME/NINO/copyfiles.sh cmorph_daily_05.nc
echo cdo -r -f nc4 -z zip copy $ncfiles cmorph_daily.nc
cdo -r -f nc4 -z zip copy $ncfiles cmorph_daily.nc
$HOME/NINO/copyfiles.sh cmorph_daily.nc
