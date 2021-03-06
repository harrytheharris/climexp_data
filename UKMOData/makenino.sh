#!/bin/sh
for nino in 12 3 3.4 4
do
  lat1="-5"
  lat2="5"
  case $nino in
      12) lon1="-90"; lon2="-80"; lat1="-10"; lat2="0";;
      3) lon1="-150"; lon2="-90";;
      3.4) lon1="-170"; lon2="-120";;
      4) lon1="-200"; lon2="-150";;
      *) echo help;exit -1;;
  esac
  echo $nino
  get_index HadISST_sst.nc $lon1 $lon2 $lat1 $lat2 > hadisst1_nino${nino}.dat
  fgrep '#' hadisst1_nino${nino}.dat | fgrep -v ' [' > hadisst1_nino${nino}a.dat
  echo '# SSTA normalized to 1971-2000' >> hadisst1_nino${nino}a.dat
  echo "# Nino$nino [K] HadISST1 Nino$nino index" >> hadisst1_nino${nino}a.dat
  plotdat anomal 1971 2000 hadisst1_nino${nino}.dat | egrep -v '^#' | fgrep -v repeat >> hadisst1_nino${nino}a.dat
done
