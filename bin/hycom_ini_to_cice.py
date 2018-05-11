#!/usr/bin/env python

import netCDF4
import numpy as np
import sys

import matplotlib.pyplot as plt

def set_to_val(nc,variable,icemask,val=0.0,n=-999):
    var    = nc.variables[variable]
    if n < 0:
        var[:] = val*icemask
    else:
        var[n,:] = val*icemask

# Make initialization of new cice-file...

if len(sys.argv[:]) < 3:
    print "Usage: python roms_ini_to_cice.py <romsifile> <romsgrid> <ciceofile>"
    sys.exit()



hycomfile = sys.argv[1] #'/disk1/CICE_ini/ocean_ini.nc'
cicefile = sys.argv[2] #'/disk1/CICE_ini/iced.1997-01-01-00000.nc'
cicegridfile=sys.argv[3] #'../topo/cice_grid.nc'

print 'hycom file is {}'.format(hycomfile)
print 'cice file is {}'.format(cicefile)

NCAT = [0, 0.6445072, 1.391433, 2.470179, 4.567288, 1e+08] #upper limits of ice categories
varlist2d_null = ['uvel','vvel','swvdr','swvdf','swidr','swidf','strocnxT','strocnyT',
                  'stressp_1','stressp_2','stressp_3','stressp_4','stressm_1','stressm_2','stressm_3',
                  'stressm_4','stress12_1','stress12_2','stress12_3','stress12_4','iceumask','fsnow']
varlist3d_null = ['vsnon','iage','apnd','hpnd','ipnd','dhs','ffrac','qsno001']
varlist3d_sice = ['sice001', 'sice002', 'sice003', 'sice004', 'sice005', 'sice006', 'sice007']
sice_val = 5.0
varlist3d_qice = ['qice001', 'qice002', 'qice003', 'qice004', 'qice005', 'qice006', 'qice007']
qice_val = -2.0e8
varlist_lvl = ['alvl', 'vlvl']
lvl_val = 1.0


nc_hycom   = netCDF4.Dataset(hycomfile)
print nc_hycom.file_format
nc_cice   = netCDF4.Dataset(cicefile,'r+')
nc_ciceg = netCDF4.Dataset(cicegridfile)

aice_h    = nc_hycom.variables['fice'][:]   # mean ice concentration for grid cell
hice_h    = nc_hycom.variables['hice'][:]
lat_h = nc_hycom.variables['latitude'][:]
lon_h = nc_hycom.variables['longitude'][:]
time_h = nc_hycom.variables['time'][:]
nc_hycom.close()
# convert masked to array to array
aice_h = aice_h.filled(fill_value=0.0)
hice_h = hice_h.filled(fill_value=0.0)
# topaz file needs to be averaged
aice_h2 = (0.5*(aice_h[0,:,:]+aice_h[1,:,:]))
hice_h2 = (0.5*(hice_h[0,:,:]+hice_h[1,:,:]))
ny_h, nx_h = aice_h2.shape
print type(aice_h2)
print type(hice_h2)


# cice stuff
aicen_c   = nc_cice.variables['aicen']  # ice concentration per category in grid cell
vicen_c   = nc_cice.variables['vicen']  # volume per unit area of ice (in category n)
tsfcn_c   = nc_cice.variables['Tsfcn']
lat_c = nc_ciceg.variables['lat'][:]
lon_c = nc_ciceg.variables['lon'][:]
ny_c, nx_c = lat_c.shape
nc_ciceg.close()

print 'shape of topaz is {}x{}'.format(ny_h, nx_h)
print 'shape of cice is {}x{}'.format(ny_c, nx_c)
print aicen_c.shape

aice_hi=np.zeros((ny_c, nx_c))
hice_hi=np.zeros((ny_c, nx_c))

# average over navg adjacent grid points on hycom grid
navg=2
    
for j in range(ny_c):
    for i in range(nx_c):
        distance = np.sqrt( (lat_c[j,i]-lat_h)**2 + (lon_c[j,i]-lon_h)**2 )
        j_h, i_h = np.where(distance == distance.min())
        j_h = int(j_h[0])
        i_h = int(i_h[0])
        if j_h > navg-1 and j_h < ny_h-navg+1 and i_h > navg-1 and i_h < nx_h-navg+1 :
            aice_hi[j,i] = np.mean(aice_h2[j_h-navg:j_h+navg,i_h-navg:i_h+navg])
            hice_hi[j,i] = np.mean(hice_h2[j_h-navg:j_h+navg,i_h-navg:i_h+navg])
        else :
            aice_hi[j,i] = aice_h2[j_h,i_h]
            hice_hi[j,i] = hice_h2[j_h,i_h]

        for n in range(len(NCAT[1:])):
            if hice_hi[j,i] > NCAT[n] and hice_hi[j,i] < NCAT[n+1] :
                aicen_c[n,j,i] = aice_hi[j,i]
                vicen_c[n,j,i] = aice_hi[j,i]*hice_hi[j,i]
            else :
                aicen_c[n,j,i] = 0.0
                vicen_c[n,j,i] = 0.0
            if aice_hi[j,i] > 0.1 :
                tsfcn_c[n,j,i] = -5.0

# calculate ice mask
mask_h = np.where(aice_hi[:] > 0.1, 1, 0)

# loop over positions
for n in range(len(NCAT[1:])):
    print 'Upper limit: '+str(NCAT[n+1])
    for s in varlist3d_null:
        set_to_val(nc_cice,s,mask_h,0.0,n)
    for s in varlist3d_sice:
        set_to_val(nc_cice,s,mask_h,sice_val,n)
    for s in varlist3d_qice:
        set_to_val(nc_cice,s,mask_h,qice_val,n)
    for s in varlist_lvl:
        set_to_val(nc_cice,s,mask_h,lvl_val,n)
    #set_to_val(nc_cice,'Tsfcn',mask_h,-3.0,n)
    

for s in varlist2d_null:
    print s
    set_to_val(nc_cice,s,mask_h,0.0)
    
#nc_cice.istep1 = 0
#nc_cice.time = 0
#nc_cice.time_forc = 0
#nc_cice.nyr = 1
#nc_cice.month = 1
#nc_cice.mday = 1
#nc_cice.sec = 0


nc_cice.close()

#from mpl_toolkilts.basemap import Basemap
#bnd_lat=50.0
#lon0=-45.

#lev=np.array([0.2,0.5,0.7,1.0])
#plt.figure()
#m = Basemap(projection='npstere', lon_0=lon0, boundinglat=bnd_lat, resolution='l')
#x, y = m(lon_c, lat_c)
#m.drawcoastlines()
#m.fillcontinents(color='lightgrey')
#cs = m.contourf(x,y,aice_hi, levels=lev, cmap=plt.cm.bone)
#cbar=m.colorbar(cs)
#
#plt.figure()
#m = Basemap(projection='npstere', lon_0=lon0, boundinglat=bnd_lat, resolution='l')
#x, y = m(lon_h, lat_h)
#m.drawcoastlines()
#m.fillcontinents(color='lightgrey')
#cs = m.contourf(x,y,aice_h2, levels=lev, cmap=plt.cm.bone)
#cbar=m.colorbar(cs)

if False:
    plt.figure()
    plt.imshow(aice_hi, cmap=plt.cm.bone)
    plt.clim(0,1)
    plt.colorbar()
    plt.title('aice int')
    plt.figure()
    plt.imshow(aice_h2, cmap=plt.cm.bone)
    plt.clim(0,1)
    plt.colorbar()
    plt.title('aice topaz')
    plt.figure()
    plt.imshow(hice_hi, cmap=plt.cm.Blues)
    plt.clim(0,3)
    plt.colorbar()
    plt.title('hice int')
    plt.figure()
    plt.imshow(hice_h2, cmap=plt.cm.Blues)
    plt.clim(0,3)
    plt.colorbar()
    plt.title('hice topaz')

plt.show()

print 'done'
