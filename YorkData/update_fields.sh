#!/bin/sh
base=http://www-users.york.ac.uk/~kdc3/papers/coverage2013
for file in had4_krig_v2_0_0.nc
do
    cp $file $file.old
    wget -N -q $base/$file.gz
    cmp $file.gz $file.gz.old
    if [ $? != 0 ]; then
        gunzip -f $file.gz
        cdo delname,year,month $file aap.nc
        mv aap.nc $file
    fi
done
$HOME/NINO/copyfiles.sh *.nc