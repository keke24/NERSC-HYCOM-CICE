#! /bin/bash
# Name: make_nemo_archives.py
# Purpose: Convert MMERCATOR data to HYCOM archive files in isopycnal coordinates
# Author: Mostafa Bakhoday-Paskyabi (Mostafa.Bakhoday@nersc.no)
# Created: November 2017
# Copyright: (c) NERSC Norway 2017
# Licence:
# This script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
# http://www.gnu.org/licenses/gpl-3.0.html
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Adapted by Graig Sutherland (graigorys@met.no) to work in operational setup

options=$(getopt -o:  -- "$@")
maxinc=50
eval set -- "$options"
while true; do
    case "$1" in
    -m)
       shift;
       maxinc=$1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

if [ $# -lt 1 ] ; then
    echo "This script will set up the final nesting files from MERCATOR 1/12 degree to be used by HYCOM."
    echo "The code contains the following steps:"
    echo "(1) Create archive [ab] files from the MERCATOR netcdf file."
    echo "    The final archive files includes all 2D fields (filled with zero except baraotropic velocities)."
    echo "    and 3D fields of temperaure, salinity, thickness, and two components of velocities."
    echo "(2) Based on generated archive files in (1) the grid and topography files are generated."
    echo "    Note that the grids are non-native and interpolated into a rectilinear mercator grids horizontally."
    echo ""
    echo "Example:"
    echo "   nemo2hycom_TP5.sh global_analysis_forecast_phy_yyyymmdd.nc"
    exit 1
fi

ncfiles=$@

if [ $# -eq 1 ] ; then
    echo "There is $# ncfile input to nesting program"
else
    echo "There are $# ncfiles input to nesting program"
fi
#echo $ncfiles

#exit 0

# Must be in expt dir to run this script
if [ -f EXPT.src ] ; then
    export BASEDIR=$(cd .. && pwd)
else
    echo "Could not find EXPT.src. This script must be run in expt dir"
    exit 1
fi

source EXPT.src || { echo "Could not source ./EXPT.src" ; exit 1 ; }
source ${BASEDIR}/REGION.src || { echo "Could not source ${BASEDIR}/REGION.src" ; exit 1 ; }

# add MESH file for root directory for nesting
CDF_NEMO=${NESTROOT}/topo/GLO_MFC_001_24_MESH.nc

# add nesting directory
NESTDIR=${NESTROOT}/expt_${NESTEXPT}


## get variables from blkdat.input
iexpt=`grep "'iexpt ' =" blkdat.input | awk '{printf("%1d", $1)}'`
iversn=`grep "'iversn' =" blkdat.input | awk '{printf("%1d", $1)}'`
yrflag=`grep "'yrflag' =" blkdat.input | awk '{printf("%1d", $1)}'`
idm=`grep "'idm   ' =" blkdat.input | awk '{printf("%1d", $1)}'`
jdm=`grep "'jdm   ' =" blkdat.input | awk '{printf("%1d", $1)}'`

echo "iexpt = $iexpt"
echo "iversn = $iversn"
echo "yrflag = $yrflag"
echo "idm = $idm"
echo "jdm = $jdm"

## loop through ncfiles
for source_archv in $ncfiles ; do
	echo ${source_archv}
    infile=$(basename $source_archv)
    year=$(echo ${infile} | cut -c30-33)
    month=$(echo ${infile} | cut -c34-35)
    day=$(echo ${infile} | cut -c36-37)
    # there seems to be a 1 day offset between this and forecast scripts
    jday=$(date2julday $year $month $day)
    doy=$(echo $jday | ${MAINDIR}/Subprogs/julday2dayinyear_out)
    doy=$(echo 00$doy | tail -4c)
    nemo_archv=archv.${year}_${doy}_00
    echo "nemo_archv = $nemo_archv"
    #
	# (1) Create archive [ab] files from the MERCATOR netcdf file.
	#
	echo "Calling nemo2archvz_TP5.py"
	nemo2archvz_TP5.py ${CDF_NEMO} ${NESTDIR} $source_archv --iexpt ${iexpt} --iversn ${iversn} --yrflag ${yrflag}
	
	#
	# (2) Based on generated archive files in (1) the grid and topography files are generated.
	#
	echo "Calling remap_nemo_TP5.sh"
	#remap_nemo_TP5.sh $(cat archvname.txt)
    echo "infput file $source_archv"
    echo "what I think it should be $nemo_archv"
	remap_nemo_TP5.sh ${nemo_archv}
done
