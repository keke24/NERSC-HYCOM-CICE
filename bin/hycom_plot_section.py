#!/usr/bin/env python
import modeltools.hycom
import modeltools.tools
import argparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot
import abfile
import numpy
from mpl_toolkits.basemap import Basemap
import netCDF4
import logging
import re
import os.path
import gridxsec

# Set up logger
_loglevel=logging.INFO
logger = logging.getLogger(__name__)
logger.setLevel(_loglevel)
formatter = logging.Formatter("%(asctime)s - %(name)10s - %(levelname)7s: %(message)s")
ch = logging.StreamHandler()
ch.setLevel(_loglevel)
ch.setFormatter(formatter)
logger.addHandler(ch)
logger.propagate=False



def main(lon1,lat1,lon2,lat2,variable,files,filetype="archive",clim=None,sectionid="",
      ijspace=False,xaxis="distance",section_map=False,dpi=180) :

   logger.info("Filetype is %s"% filetype)
   gfile = abfile.ABFileGrid("regional.grid","r")
   plon=gfile.read_field("plon")
   plat=gfile.read_field("plat")
   qlon=gfile.read_field("qlon")
   qlat=gfile.read_field("qlat")

   # Set up section info
   if ijspace :
      sec = gridxsec.SectionIJSpace([lon1,lon2],[lat1,lat2],plon,plat)
   else  :
      sec = gridxsec.Section([lon1,lon2],[lat1,lat2],plon,plat)
   I,J=sec.grid_indexes
   dist=sec.distance
   slon=sec.longitude
   slat=sec.latitude

   # In testing
   #J,I,slon,slat,case,dist=sec.find_intersection(qlon,qlat)
   #print I,J
   #raise NameError,"test"



   logger.info("Min max I-index (starts from 0):%d %d"%(I.min(),I.max()))
   logger.info("Min max J-index (starts from 0):%d %d"%(J.min(),J.max()))


   if section_map :
      ll_lon=slon.min()-10.
      ur_lon=slon.max()+10.
      ll_lat=numpy.maximum(-90.,slat.min()-10.)
      ur_lat=numpy.minimum(90. ,slat.max()+10.)
      m = Basemap(projection='mill', llcrnrlon=ll_lon, llcrnrlat=ll_lat, urcrnrlon=ur_lon, urcrnrlat=ur_lat, resolution='l')
      (x,y) = m(slon,slat)
      figure = matplotlib.pyplot.figure()
      ax=figure.add_subplot(111)
      m.drawcoastlines()
      #m.fillcontinents(color='coral',lake_color='aqua')
      m.drawparallels(numpy.arange(-90.,120.,30.),labels=[1,0,0,0]) # draw parallels
      m.drawmeridians(numpy.arange(0.,420.,60.),labels=[0,0,0,1]) # draw meridians
      m.drawmapboundary() # draw a line around the map region
      m.plot(x,y,"r",lw=3)
      m.etopo()
      #m.scatter(x,y,s=20,c=dist)
      pos = ax.get_position()
      #print pos
      asp=pos.height/pos.width
      #print asp
      w=figure.get_figwidth()
      #print w
      h=asp*w
      figure.set_figheight(h)
      if sectionid :
         figure.canvas.print_figure("map_%s.png"%sectionid,dpi=dpi)
      else :
         figure.canvas.print_figure("map.png",dpi=dpi)

   # Get layer thickness variable used in hycom
   dpname = modeltools.hycom.layer_thickness_variable[filetype]
   logger.info("Filetype %s: layer thickness variable is %s"%(filetype,dpname))


   if xaxis == "distance" :
      x=dist/1000.
      xlab="Distance along section[km]"
   elif xaxis == "i" :
      x=I
      xlab="i-index"
   elif xaxis == "j" :
      x=J
      xlab="j-index"
   elif xaxis == "lon" :
      x=slon
      xlab="longitude"
   elif xaxis == "lat" :
      x=slat
      xlab="latitude"
   else :
      logger.warning("xaxis must be i,j,lo,lat or distance")
      x=dist/1000.
      xlab="Distance along section[km]"

   # Loop over archive files
   figure = matplotlib.pyplot.figure()
   ax=figure.add_subplot(111)
   pos = ax.get_position()
   for fcnt,myfile0 in enumerate(files) :

      # Remove [ab] ending if present
      m=re.match("(.*)\.[ab]",myfile0)
      if m :
         myfile=m.group(1)
      else :
         myfile=myfile0

      # Add more filetypes if needed. By def we assume archive
      if filetype == "archive" :
         i_abfile = abfile.ABFileArchv(myfile,"r")
      elif filetype == "restart" :
         i_abfile = abfile.ABFileRestart(myfile,"r",idm=gfile.idm,jdm=gfile.jdm)
      else :
         raise NotImplementedError,"Filetype %s not implemented"%filetype

      # kdm assumed to be max level in ab file
      kdm=max(i_abfile.fieldlevels)

      # Set up interface and daat arrays
      intfsec=numpy.zeros((kdm+1,I.size))
      datasec=numpy.zeros((kdm+1,I.size))

      # Loop over layers in file. 
      logger.info("File %s"%(myfile))
      for k in range(kdm) :
         logger.debug("File %s, layer %03d/%03d"%(myfile,k,kdm))

         # Get 2D fields
         dp2d=i_abfile.read_field(dpname,k+1)
         data2d=i_abfile.read_field(variable,k+1)
         dp2d=numpy.ma.filled(dp2d,0.)/modeltools.hycom.onem
         data2d=numpy.ma.filled(data2d,1e30)

         # Place data into section arrays
         intfsec[k+1,:] = intfsec[k,:] + dp2d[J,I]
         if k==0 : datasec[k,:] = data2d[J,I]
         datasec[k+1,:] = data2d[J,I]

      i_maxd=numpy.argmax(numpy.abs(intfsec[kdm,:]))
      #print i_maxd
      
      # Set up section plot
      #datasec = numpy.ma.masked_where(datasec==1e30,datasec)
      datasec = numpy.ma.masked_where(datasec>0.5*1e30,datasec)
      #print datasec.min(),datasec.max()
      #figure = matplotlib.pyplot.figure()
      #ax=figure.add_subplot(111)
      #P=ax.pcolormesh(dist/1000.,-intfsec,datasec)
      P=ax.pcolormesh(x,-intfsec,datasec)
      if clim is not None : P.set_clim(clim)

      # Plot layer interfaces
      for k in range(1,kdm+1) :
         if k%10 == 0 : 
            PL=ax.plot(x,-intfsec[k,:],"-",color="k")
         elif k%5 == 0 : 
            PL=ax.plot(x,-intfsec[k,:],"--",color="k")
         else :
            PL=ax.plot(x,-intfsec[k,:],"-",color=".5")

         textx = x[i_maxd]
         texty = -0.5*(intfsec[k-1,i_maxd] + intfsec[k,i_maxd])
         ax.text(textx,texty,str(k),verticalalignment="center",horizontalalignment="center",fontsize=6)
      cb=ax.figure.colorbar(P)
      ax.set_title(myfile)
      ax.set_ylabel(variable)
      ax.set_xlabel(xlab)
      #ax.set_position(pos)
      #matplotlib.pyplot.tight_layout()

      # Print in different y-lims 
      suff=os.path.basename(myfile)
      if sectionid : suff=suff+"_"+sectionid
      figure.canvas.print_figure("sec_%s_full_%s.png"%(variable,suff),dpi=dpi)
      ax.set_ylim(-1000,0)
      figure.canvas.print_figure("sec_%s_1000m_%s.png"%(variable,suff),dpi=dpi)
      ax.set_ylim(-300,0)
      figure.canvas.print_figure("sec_%s_300m_%s.png"%(variable,suff),dpi=dpi)

      # Close input file
      i_abfile.close()

      #
      ax.clear()
      cb.remove()




if __name__ == "__main__" :
   class ClimParseAction(argparse.Action) :
     def __call__(self, parser, args, values, option_string=None):
       tmp = values.split(",")
       print "tmp is {}".format(tmp)
       tmp[0]=float(tmp[0][1:])
       tmp[1]=float(tmp[1][:-1])
       #tmp = [float(elem) for elem in tmp[0:2]]
       setattr(args, self.dest, tmp)
   #class ClimParseAction(argparse.Action) :
   #  def __call__(self, parser, args, values, option_string=None):
   #    tmp = values.split(",")
   #    tmp = [float(elem) for elem in tmp[0:2]]
   #    setattr(args, self.dest, tmp)


   parser = argparse.ArgumentParser(description='')
   parser.add_argument('--dpi',     type=int,default=180)
   parser.add_argument('--clim',     action=ClimParseAction,default=None)
   parser.add_argument('--filetype'    ,     type=str, help='',default="archive")
   parser.add_argument('--ij'      , action="store_true",default=False)
   parser.add_argument('--sectionid'      , type=str,default="") 
   parser.add_argument('--xaxis'          , type=str,default="distance") 
   parser.add_argument('--section_map'    , action="store_true",default=False,help="Produces a simple map of the section")
   parser.add_argument('lon1',     type=int, help='')
   parser.add_argument('lat1',     type=int, help='')
   parser.add_argument('lon2',     type=int, help='')
   parser.add_argument('lat2',     type=int, help='')
   parser.add_argument('variable', type=str, help='')
   parser.add_argument('files',nargs="+")

   args = parser.parse_args()

   main(args.lon1,args.lat1,args.lon2,args.lat2,args.variable,args.files,filetype=args.filetype,clim=args.clim,sectionid=args.sectionid,ijspace=args.ij,
         xaxis=args.xaxis,section_map=args.section_map,
         dpi=args.dpi) 
