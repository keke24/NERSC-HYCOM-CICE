module mod_rotate

real, parameter, private :: undef=-1e14

contains
SUBROUTINE rotate(ud,vd,mlat,mlon,nx,ny,dir)
! Rotates a vector field from a grid in geographical coordinates
! into or from the grid defined by the lat,lon in the input variables.
! C-grid is assumed.                     
!  
! Input: mlat, mlon: position in scalar point
!        nx,ny:     dimension of the model grid.
!        ud,vd:  Unrotated vector components,  where ud is the EW
!                component and vd is the NS component 
!        dir:    l2m (latlon to general)
!                m2l (general to latlon)
!
! Output: ud,vd: Rotated vector components, where  ud is along the
!                i-axis and vd is along the j-axis.
! ----------------------------------------------------------------------
   implicit none
   integer, intent(in) :: nx
   integer, intent(in) :: ny
   real, intent(inout) :: ud(nx,ny),vd(nx,ny)
   real, intent(in)    :: mlon(nx,ny)
   real, intent(in)    :: mlat(nx,ny)
   character(len=3), intent(in) :: dir

   integer i,j,im,jm,ip,jp
   real pi,pi2,radian,radinv,fli,flj
   real u_up,v_up,u_vp,v_vp,theta_up,theta_vp,up,vp
   real dlon,dlat
   real, allocatable :: urot(:,:),vrot(:,:)

   data radian/57.29578/,pi/3.14159265/
   pi2 = pi/2.
   radinv=1./radian

! ----------------------------------------------------------
! Assumes that all parameters are provided in scalar point 
! and interpolates into the U- and V (C-grid) points, and
! perform the rotation rquired in curvlinear grid.
! -------------------------------------------------------   
   

   allocate(urot(nx,ny))
   allocate(vrot(nx,ny))
   urot=0.0 
   vrot=0.0
   if (dir == 'l2m') then
      do j=2,ny
         do i=2,nx
! Rotation angle in u-point 


            dlon=(mlon(i,j)-mlon(i-1,j))
            dlat=(mlat(i,j)-mlat(i-1,j))
            if(dlon.LT.180.)dlon=360.0+dlon
            if(dlon.GT.180.)dlon=dlon-360.0
            theta_up = atan2(dlat,dlon*cos(radinv*.5*(mlat(i,j)+mlat(i-1,j))) )
    
! Rotation angle in v-point 
            dlon=(mlon(i,j)-mlon(i,j-1))
            dlat=mlat(i,j)-mlat(i,j-1)

    
            if(dlon.LT.180.)dlon=360.0+dlon
            if(dlon.GT.180.)dlon=dlon-360.0
            theta_vp = atan2(dlat,dlon*cos(radinv*.5*(mlat(i,j)+mlat(i,j-1))) )


            u_up=.5*(ud(i,j)+ud(i-1,j)) !Unrotated vel. in u-point
            v_up=.5*(vd(i,j)+vd(i-1,j))
    
            u_vp=.5*(ud(i,j)+ud(i,j-1)) !Unrotated vel. in v-point
            v_vp=.5*(vd(i,j)+vd(i,j-1))

!            print *,'4',theta_up,theta_vp,u_up,u_vp,v_up,v_vp

            urot(i,j)= u_up*COS(theta_up)+ v_up*SIN(theta_up)
            vrot(i,j)= u_vp*COS(theta_vp)+ v_vp*SIN(theta_vp)
         enddo 
      enddo


   elseif (dir == 'm2l') then
      do j=2,ny-1
         do i=2,nx-1
! Rotation angle in p-point 
            dlon=mlon(i+1,j)-mlon(i-1,j)
            dlat=mlat(i+1,j)-mlat(i-1,j)
            if(dlon.LT.180.)dlon=360.0+dlon
            if(dlon.GT.180.)dlon=dlon-360.0
            theta_up = atan2(dlat,dlon*cos(radinv*.5*(mlat(i-1,j)+mlat(i+1,j))) )
    
! Rotation angle in p-point 
            dlon=mlon(i,j+1)-mlon(i,j-1)
            dlat=mlat(i,j+1)-mlat(i,j-1)
            if(dlon.LT.180.)dlon=360.0+dlon
            if(dlon.GT.180.)dlon=dlon-360.0
            theta_vp = atan2(dlat,dlon*cos(radinv*.5*(mlat(i,j-1)+mlat(i,j+1))) )


!Unrotated vel. in p-point
            if (abs(ud(i,j))>=abs(undef).and.abs(ud(i+1,j))>=abs(undef)) then
               urot(i,j)= undef
               vrot(i,j)= undef
            else if (abs(vd(i,j))>=abs(undef).and.abs(vd(i,j+1))>=abs(undef)) then
               urot(i,j)= undef
               vrot(i,j)= undef
            else if (abs(ud(i,j))>=abs(undef).or.abs(ud(i+1,j))>=abs(undef)) then
               up=max(ud(i,j),ud(i+1,j))
               if (abs(vd(i,j))>=abs(undef).or.abs(vd(i,j+1))>=abs(undef)) then
                  vp=max(vd(i,j),vd(i,j+1))
               else
                  vp=.5*(vd(i,j)+vd(i,j+1))
               end if
               urot(i,j)= up*cos(theta_up)+ vp*cos(theta_vp)
               vrot(i,j)= up*sin(theta_up)+ vp*sin(theta_vp)
            else if (abs(vd(i,j))>=abs(undef).or.abs(vd(i,j+1))>=abs(undef)) then
               vp=max(vd(i,j),vd(i,j+1))
               if (abs(ud(i,j))>=abs(undef).or.abs(ud(i+1,j))>=abs(undef)) then
                  up=max(ud(i,j),ud(i+1,j))
               else
                  up=.5*(ud(i,j)+ud(i+1,j))
               end if
               urot(i,j)= up*cos(theta_up)+ vp*cos(theta_vp)
               vrot(i,j)= up*sin(theta_up)+ vp*sin(theta_vp)
            else
               up=.5*(ud(i,j)+ud(i+1,j))
               vp=.5*(vd(i,j)+vd(i,j+1))

               urot(i,j)= up*cos(theta_up)+ vp*cos(theta_vp)
               vrot(i,j)= up*sin(theta_up)+ vp*sin(theta_vp)
            end if
         enddo 
      enddo
   else
      stop 'rotate'
   endif
   ud=urot
   vd=vrot
   deallocate(urot)
   deallocate(vrot)

END subroutine rotate



SUBROUTINE rotate_general(ud,vd,yp,xp,nx,ny,dir)
! Rotates a vector field from a grid in general coordinates
! into or from the grid defined by xproj,yproj in the input variables.
! C-grid is assumed.                     
!  
! Input: yp, xp: position in scalar point
!        nx,ny:     dimension of the model grid.
!        ud,vd:  Unrotated vector components,  where ud is the EW
!                component and vd is the NS component 
!        dir:    l2m (latlon to general)
!                m2l (general to latlon)
!
! Output: ud,vd: Rotated vector components, where  ud is along the
!                i-axis and vd is along the j-axis.
! ----------------------------------------------------------------------
   implicit none
   integer, intent(in) :: nx
   integer, intent(in) :: ny
   real, intent(inout) :: ud(nx,ny),vd(nx,ny)
   real, intent(in)    :: xp(nx,ny)
   real, intent(in)    :: yp(nx,ny)
   character(len=3), intent(in) :: dir

   integer i,j,im,jm,ip,jp
   real pi,pi2,radian,radinv,fli,flj
   real u_up,v_up,u_vp,v_vp,theta_up,theta_vp,up,vp
   real dx,dy
   real, allocatable :: urot(:,:),vrot(:,:)

   data radian/57.29578/,pi/3.14159265/
   pi2 = pi/2.
   radinv=1./radian

! ----------------------------------------------------------
! Assumes that all parameters are provided in scalar point 
! and interpolates into the U- and V (C-grid) points, and
! perform the rotation rquired in curvlinear grid.
! -------------------------------------------------------   
   

   allocate(urot(nx,ny))
   allocate(vrot(nx,ny))
   urot=0.0 
   vrot=0.0
   if (dir == 'l2m') then
      do j=2,ny
         do i=2,nx
! Rotation angle in u-point 


            dx=(xp(i,j)-xp(i-1,j))
            dy=(yp(i,j)-yp(i-1,j))
            !theta_up = atan2(dy,dx*cos(radinv*.5*(yp(i,j)+yp(i-1,j))) )
            theta_up = atan2(dy,dx)
    
! Rotation angle in v-point 
            dx=(xp(i,j)-xp(i,j-1))
            dy=yp(i,j)-yp(i,j-1)

    
            !theta_vp = atan2(dy,dx*cos(radinv*.5*(yp(i,j)+yp(i,j-1))) )
            theta_vp = atan2(dy,dx)


            u_up=.5*(ud(i,j)+ud(i-1,j)) !Unrotated vel. in u-point
            v_up=.5*(vd(i,j)+vd(i-1,j))
    
            u_vp=.5*(ud(i,j)+ud(i,j-1)) !Unrotated vel. in v-point
            v_vp=.5*(vd(i,j)+vd(i,j-1))

!            print *,'4',theta_up,theta_vp,u_up,u_vp,v_up,v_vp

            urot(i,j)= u_up*COS(theta_up)+ v_up*SIN(theta_up)
            vrot(i,j)= u_vp*COS(theta_vp)+ v_vp*SIN(theta_vp)
         enddo 
      enddo


   elseif (dir == 'm2l') then
      do j=2,ny-1
         do i=2,nx-1
! Rotation angle in p-point 
            dx=xp(i+1,j)-xp(i-1,j)
            dy=yp(i+1,j)-yp(i-1,j)
            !theta_up = atan2(dy,dx*cos(radinv*.5*(yp(i-1,j)+yp(i+1,j))) )
            theta_up = atan2(dy,dx)
    
! Rotation angle in p-point 
            dx=xp(i,j+1)-xp(i,j-1)
            dy=yp(i,j+1)-yp(i,j-1)
            !theta_vp = atan2(dy,dx*cos(radinv*.5*(yp(i,j-1)+yp(i,j+1))) )
            theta_vp = atan2(dy,dx)

!Unrotated vel. in p-point
            up=.5*(ud(i,j)+ud(i+1,j))
            vp=.5*(vd(i,j)+vd(i,j+1))
    
            urot(i,j)= up*cos(theta_up)+ vp*cos(theta_vp)
            vrot(i,j)= up*sin(theta_up)+ vp*sin(theta_vp)
         enddo 
      enddo
   else
      stop 'rotate'
   endif
   ud=urot
   vd=vrot
   deallocate(urot)
   deallocate(vrot)
END subroutine rotate_general

end module mod_rotate
