#!/bin/csh
#
#set echo
#
# --- Usage:  ./Make_ncdf.com >& Make_ncdf.log
#
# --- make all netCDF relax executables
#
# --- set NCDF to the root directory for netCDF.
# --- available from: http://www.unidata.ucar.edu/packages/netcdf/
#
#
# --- set ARCH to the correct value for this machine.
#
setenv ARCH intelICE
setenv NCDF ${NETCDF_DIR}
setenv EXTRANCDF "-lnetcdf -lnetcdff"
#
echo "NCDF = " $NCDF
echo "ARCH = " $ARCH
#
if (! -e ../../config/${ARCH}_setup) then
  echo "ARCH = " $ARCH "  is not supported"
  exit 1
endif
#
# --- softlink to netCDF module and library (and typesizes.mod for OSF1 only)
#
/bin/rm -f netcdf.mod libnetcdf.a libnetcdff.a
/bin/rm -f typesizes.mod
#
ln -s ${NCDF}/include/netcdf.mod   .
ln -s ${NCDF}/include/typesizes.mod   .
ln -s ${NCDF}/lib/libnetcdf.a .
ln -s ${NCDF}/lib/libnetcdff.a .
foreach m ( z_woa13 )
  make ${m} ARCH=${ARCH} >&! Make_${m}
  if ($status) then
    echo "Make failed:" ${m}
  else
    echo "Make worked:" ${m}
  endif
end
