#!/usr/bin/env python
import modeltools.hycom
import argparse
import datetime
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import modeltools.forcing.bathy
#import modeltools.hycom.io
import abfile
import numpy
import netCDF4
import logging
import re

"""Program to calculate fft on regional grid"""

# Set up logger
_loglevel=logging.DEBUG
logger = logging.getLogger(__name__)
logger.setLevel(_loglevel)
formatter = logging.Formatter("%(asctime)s - %(name)10s - %(levelname)7s: %(message)s")
ch = logging.StreamHandler()
ch.setLevel(_loglevel)
ch.setFormatter(formatter)
logger.addHandler(ch)
logger.propagate=False

gfile=abfile.ABFileGrid("regional.grid","r")
plon=gfile.read_field("plon")
plat=gfile.read_field("plat")
scpx=gfile.read_field("scpx")
scpy=gfile.read_field("scpy")
width=numpy.median(scpx)
resolution=None
logger.info("Grid median resolution:%8.2f km "%(width/1000.))
bathyDir="/nobackup/prod2/sm_grasu/ModelInput/bathymetry/GEBCO/"
# GEBCO only - TODO: move logic to gebco set
if resolution is None  :
   if width  > 20 :
      dfile=bathyDir+"GEBCO_2014_2D_median20km.nc"
   elif width > 8 :
      dfile=bathyDir+"GEBCO_2014_2D_median8km.nc"
   elif width > 4 :
      dfile=bathyDir+"GEBCO_2014_2D_median4km.nc"
   else :
      dfile=bathyDir+"GEBCO_2014_2D.nc"
   logger.info ("Source resolution not set - choosing datafile %s"%dfile)
else :
   dfile=bathyDir+"GEBCO_2014_2D_median%dkm.nc" % resolution
   logger.info ("Source resolution set to %d - trying to use datafile %s"%dfile)
gebco = modeltools.forcing.bathy.GEBCO2014(filename=dfile)

nx, ny = plon.shape
glon,glat = numpy.meshgrid(gebco._lon, gebco._lat)
for i in [400]:
    for j in [400]:
       dy = numpy.radians(glat-plat[i,j])*111*1000
       dx = numpy.radians(numpy.mod(glon-plon[i,j],360.))*111*1000
       ind = numpy.where(numpy.logical_and(numpy.abs(dx) <= scpx[i,j], \
               numpy.abs(dy) <= scpy[i,j]))
       xx = numpy.radians(glat[ind] - plat[i,j])*111*1e3
       yy = numpy.radians(glon[ind] - plon[i,j])*111*1e3
       logger.debug("shape of xx is {}".format(xx.shape))
       plt.figure()
       plt.plot(xx,yy)
       plt.savefig('test.png')
       #h = gebco._elevation[ind]

 
