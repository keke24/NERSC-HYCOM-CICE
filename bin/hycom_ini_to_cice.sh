#!/bin/bash

# wrapper for hycom_ini_cice.py

# Must be in expt dir to run this script
if [ -f EXPT.src ] ; then
    export BASEDIR=$(cd .. && pwd)
else
    echo "Could not find EXPT.src. This script must be run in expt dir"
    exit 1
fi

source EXPT.src || { echo "Could not source ./EXPT.src" ; exit 1 ; }
source ${BASEDIR}/REGION.src || { echo "Could not source ${BASEDIR}/REGION.src" ; exit 1 ; }

# define grids
# first copy original to cice_file
cice_file='data/cice/iced.1993-09-01-00000.nc'
rsync -avh ${cice_file}.orig ${cice_file}
cice_grid='../topo/hycom_bathymetry.nc'
topaz_file=${HOME}/topaz_reanalysis_1993-09.nc

echo ${topaz_file}

hycom_ini_to_cice.py ${topaz_file} ${cice_file} ${cice_grid}

exit
