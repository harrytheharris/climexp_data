#!/bin/sh
###set -x

yrnow=`date +%Y`
###echo "Please download the file PIOMAS.vol.daily.1979.*.dat by hand from http://psc.apl.washington.edu/wordpress/research/projects/arctic-sea-ice-volume-anomaly/data/"
wget -N http://psc.apl.uw.edu/wordpress/wp-content/uploads/schweiger/ice_volume/PIOMAS.vol.daily.1979.$yrnow.Current.v2.1.dat.gz
zfile=`ls -t PIOMAS.vol.daily.1979.*.dat.gz | head -1`
[ -s "$zfile" ] && gunzip -f $zfile
file=`ls -t PIOMAS.vol.daily.1979.*.dat | head -1`
if [ $file -nt piomas_dy.dat ]; then
	make piomas2dat
	./piomas2dat $file > piomas_dy.dat
	daily2longer piomas_dy.dat 12 mean > piomas_mo.dat
fi
$HOME/NINO/copyfilesall.sh piomas_??.dat

cp PDO.latest.txt PDO.latest.old
wget -N http://research.jisao.washington.edu/pdo/PDO.latest.txt
diff PDO.latest.txt PDO.latest.old
if [ $? != 0 -o "$1" = force ]; then
    # metadata structured from the file dd 4-feb-2018
    cat > pdo.dat <<EOF
# PDO [1] Pacific Decadal Oscillation index
# from <a href="http://research.jisao.washington.edu/pdo/">JISAO</a>
# insitution :: University of Washington, JISAO
# author :: Nate Mantua
# contact :: nate.mantua@noaa.gov
# link :: http://research.jisao.washington.edu/pdo/
# source :: http://research.jisao.washington.edu/pdo/PDO.latest
# reference :: Zhang, Y., J.M. Wallace, D.S. Battisti, 1997: ENSO-like interdecadal variability: 1900-93. J. Climate, 10, 1004-1020. 
# reference :: Mantua, N.J. and S.R. Hare, Y. Zhang, J.M. Wallace, and R.C. Francis, 1997: A Pacific interdecadal climate oscillation with impacts on salmon production. BAMS, 78, 1069-1079.
# data_source :: UKMO Historical SST data set for 1900-81, Reynold's Optimally Interpolated SST (V1) for January 1982-Dec 2001, OI SST Version 2 (V2) beginning January 2002
# history :: retrieved at `date`
EOF
    egrep '^[12]' PDO.latest.txt | tr -d '*' | sed -e 's/-9999/-999.9/' -e 's/0.18   0.09$/0.18   0.09 -999.9 -999.9 -999.9/' >> pdo.dat
    $HOME/NINO/copyfilesall.sh pdo.dat
fi

FORM_field=hadsst3
. $HOME/climexp/queryfield.cgi
series=`ls -t ~/climexp/UKMOData/hadcrut4*_ns_avg.dat | head -1`
if [ -z "$series" ]; then
    echo "$0: error: cannot find ~/climexp/UKMOData/hadcrut4*_ns_avg.dat"
    exit -1
fi
subfieldseries ~/climexp/$file $series ./hadsst3-tglobal.nc
rm eof1_hadsst.nc
eof ./hadsst3-tglobal.nc 1 normalize varspace mon 1 ave 12 lon1 100 lon2 260 lat1 20 lat2 65 begin 1900 eof1_hadsst.nc
patternfield hadsst3-tglobal.nc eof1_hadsst.nc eof1 1 > aap.dat
scaleseries 3 aap.dat > pdo_hadsst3.dat
$HOME/NINO/copyfilesall.sh pdo_hadsst3.dat

FORM_field=ersstv5a
. $HOME/climexp/queryfield.cgi
extend_series ~/climexp/NCDCData/ncdc_gl.dat > ncdc_gl1.dat
subfieldseries ~/climexp/$file ncdc_gl1.dat ./ersst-tglobal.nc
rm eof1_ersst.nc
eof ./ersst-tglobal.nc 1 normalize varspace anom mon 1 ave 12 lon1 100 lon2 260 lat1 20 lat2 65 eof1_ersst.nc
patternfield ersst-tglobal.nc eof1_ersst.nc eof1 1 > aap.dat
plotdat anom aap.dat > noot.dat
scaleseries -3.5 noot.dat > pdo_ersst.dat
$HOME/NINO/copyfilesall.sh pdo_ersst.dat
