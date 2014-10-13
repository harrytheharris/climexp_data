#!/bin/sh
yr=`date +%Y`
mo=`date +%m`
if [ -f downloaded_$yr$mo ]; then
  echo "Already downloaded GHCN-D this month"
  exit
fi
# get data
base=ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/
cp ghcnd-countries.txt ghcnd-countries.txt.old
wget -q -N $base/ghcnd-countries.txt
cp ghcnd-stations.txt ghcnd-stations.txt.old
wget -q -N $base/ghcnd-stations.txt
cp ghcnd_all.tar.gz ghcnd_all.tar.gz.old
wget -q -N $base/ghcnd_all.tar.gz
cmp ghcnd_all.tar.gz ghcnd_all.tar.gz.old
if [ $? = 0 ]; then
  echo ghcnd_all.tar.gz unchanged
  exit
fi
wget -q --continue $base/ghcnd_all.tar.gz
wget -q --continue $base/ghcnd_all.tar.gz
cmp ghcnd_all.tar.gz ghcnd_all.tar.gz.old
if [ $? = 0 ]; then
  echo ghcnd_all.tar.gz unchanged
  exit
fi
# check integrity
gzip -t ghcnd_all.tar.gz
if [ $? != 0 ]; then
  echo ghcnd_all.tar.gz corrupt
  mv ghcnd_all.tar.gz.old ghcnd_all.tar.gz
  exit
fi

# extract data
echo "uncompressing and extracting tar file"
tar zxf ghcnd_all.tar.gz

# and compress all files individually
echo "and compressing all data files again"
gzip -r -f ghcnd_all

# swap
rm -rf ghcnd.old
mv ghcnd ghcnd.old
mv ghcnd_all ghcnd

# update metadata
echo "update metadata"
make addyears
./addyears

# copy to climexp
echo "copy to climexp"
$HOME/NINO/copyfiles.sh -r ghcnd
$HOME/NINO/copyfiles.sh ghcnd-countries.txt ghcnd-stations.txt ghcnd2.inv.withyears
date > downloaded_$yr$mo