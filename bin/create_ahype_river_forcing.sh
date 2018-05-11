#!/bin/bash

# program to create the correct ahype river forcing files for hycom

if [ -f EXPT.src ] ; then
   EXPTDIR=${PWD}
   pushd ../
   BASEDIR=${PWD}
   popd
else
   echo "Could not find EXPT.src. This script must be run in expt dir"
   exit 1
fi

source ${BASEDIR}/REGION.src         || { echo "Could not source ${BASEDIR}/REGION.src" ; exit 1 ; }

# now go through years for mixclim and ahype
year0=1979
nyears=35

for ((i=0;i<nyears;i+=1)); do
   year=$((year0+i))
   echo "Calculating ahype river for mixclim year=${year}"
   ${NHCBINDIR}/river_ahype_mixclim.sh 100 300 ${year}
   echo "Calculating ahype river for year=${year}"
   ${NHCBINDIR}/river_ahype.sh 100 300 ${year}
done
