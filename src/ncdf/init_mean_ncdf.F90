#include "cppdefs.h"
!-----------------------------------------------------------------------
!BOP
!
! !IROUTINE: Initialise mean netCDf variables
!
! !INTERFACE:
   subroutine init_mean_ncdf(fn,title,starttime)
!
! !DESCRIPTION:
!
! !USES:
   use netcdf
   use exceptions
   use ncdf_common
   use ncdf_mean
   use domain, only: ioff,joff
   use domain, only: imin,imax,jmin,jmax,kmax
   use domain, only: vert_cord
   use m3d, only: calc_temp,calc_salt
#ifdef GETM_BIO
   use bio_var, only: numc,var_names,var_units,var_long
#endif
#ifdef _FABM_
   use getm_fabm, only: model,fabm_pel,output_none
#endif
   use getm_version
!
   IMPLICIT NONE
!
! !INPUT PARAMETERS:
   character(len=*), intent(in)        :: fn,title,starttime
!
! !DEFINED PARAMETERS:
   logical,    parameter               :: init3d=.true.
!
! !REVISION HISTORY:
!  Original author(s): Adolf Stips & Karsten Bolding
!
!  Revision 1.1  2004/03/29 15:38:10  kbk
!  possible to store calculated mean fields
!
! !LOCAL VARIABLES:
   integer                   :: n
   integer                   :: err
   integer                   :: scalar(1),f3_dims(3),f4_dims(4)
   REALTYPE                  :: fv,mv,vr(2)
   character(len=80)         :: history,tts
!EOP
!-------------------------------------------------------------------------
!BOC
!  create netCDF file
   err = nf90_create(fn, NF90_CLOBBER, ncid)
   if (err .NE. NF90_NOERR) go to 10

!  initialize all time-independent, grid related variables
   call init_grid_ncdf(ncid,init3d,x_dim,y_dim,z_dim)

!  define unlimited dimension
   err = nf90_def_dim(ncid,'time',NF90_UNLIMITED,time_dim)
   if (err .NE. NF90_NOERR) go to 10

!  netCDF dimension vectors
   f3_dims(3)= time_dim
   f3_dims(2)= y_dim
   f3_dims(1)= x_dim

   f4_dims(4)= time_dim
   f4_dims(3)= z_dim
   f4_dims(2)= y_dim
   f4_dims(1)= x_dim


!  globall settings
   history = 'GETM - www.getm.eu'
   tts = 'seconds since '//starttime

!  time
   err = nf90_def_var(ncid,'time',NF90_DOUBLE,time_dim,time_id)
   if (err .NE. NF90_NOERR) go to 10
   call set_attributes(ncid,time_id,units=trim(tts),long_name='time')


!  short wave radiation
   fv = swr_missing; mv = swr_missing; vr(1) = 0; vr(2) = 1500.
   err = nf90_def_var(ncid,'swrmean',NCDF_FLOAT_PRECISION,f3_dims,swrmean_id)
   if (err .NE. NF90_NOERR) go to 10
   call set_attributes(ncid,swrmean_id,  &
          long_name='mean short wave radiation',units='W/m2', &
          FillValue=fv,missing_value=mv,valid_range=vr)

! Ustar at bottom
   fv = vel_missing; mv = vel_missing; vr(1) = -1; vr(2) = 1.
   err = nf90_def_var(ncid,'ustarmean',NCDF_FLOAT_PRECISION,f3_dims,ustarmean_id)
   if (err .NE. NF90_NOERR) go to 10
   call set_attributes(ncid,ustarmean_id,  &
          long_name='bottom friction velocity',units='m/s', &
          FillValue=fv,missing_value=mv,valid_range=vr)

! Standard deviation of ustar
   fv = vel_missing; mv = vel_missing; vr(1) = 0; vr(2) = 1.
   err = nf90_def_var(ncid,'ustar2mean',NCDF_FLOAT_PRECISION,f3_dims,ustar2mean_id)
   if (err .NE. NF90_NOERR) go to 10
   call set_attributes(ncid,ustar2mean_id,  &
          long_name='stdev of bottom friction velocity',units='m/s', &
          FillValue=fv,missing_value=mv,valid_range=vr)

   select case (vert_cord)
      case (_SIGMA_COORDS_)
      case (_Z_COORDS_)
         call getm_error("init_3d_ncdf()","saving of z-levels disabled")
      case default
         fv = hh_missing
         mv = hh_missing
         err = nf90_def_var(ncid,'hmean',NCDF_FLOAT_PRECISION,f4_dims,hmean_id)
         if (err .NE. NF90_NOERR) go to 10
         call set_attributes(ncid,hmean_id, &
                             long_name='mean layer thickness',  &
                             units='meters',FillValue=fv,missing_value=mv)
   end select

   fv = vel_missing
   mv = vel_missing
   vr(1) = -3.
   vr(2) =  3.

!  zonal velocity
   err = nf90_def_var(ncid,'uumean',NCDF_FLOAT_PRECISION,f4_dims,uumean_id)
   if (err .NE. NF90_NOERR) go to 10
   call set_attributes(ncid,uumean_id, &
          long_name='mean zonal vel.',units='m/s', &
          FillValue=fv,missing_value=mv,valid_range=vr)

!  meridional velocity
   err = nf90_def_var(ncid,'vvmean',NCDF_FLOAT_PRECISION,f4_dims,vvmean_id)
   if (err .NE. NF90_NOERR) go to 10
   call set_attributes(ncid,vvmean_id, &
          long_name='mean meridional vel.',units='m/s', &
          FillValue=fv,missing_value=mv,valid_range=vr)

!  vertical velocity
   err = nf90_def_var(ncid,'wmean',NCDF_FLOAT_PRECISION,f4_dims,wmean_id)
   if (err .NE. NF90_NOERR) go to 10
   call set_attributes(ncid,wmean_id, &
          long_name='mean vertical vel.',units='m/s', &
          FillValue=fv,missing_value=mv,valid_range=vr)

#ifndef NO_BAROCLINIC
   if (calc_salt) then
      fv = salt_missing
      mv = salt_missing
      vr(1) =  0.
      vr(2) = 40.
      err = nf90_def_var(ncid,'saltmean',NCDF_FLOAT_PRECISION,f4_dims,saltmean_id)
      if (err .NE. NF90_NOERR) go to 10
      call set_attributes(ncid,saltmean_id, &
             long_name='mean salinity',units='PSU', &
             FillValue=fv,missing_value=mv,valid_range=vr)
   end if

   if (calc_temp) then
      fv = temp_missing
      mv = temp_missing
      vr(1) = -2.
      vr(2) = 40.
      err = nf90_def_var(ncid,'tempmean',NCDF_FLOAT_PRECISION,f4_dims,tempmean_id)
      if (err .NE. NF90_NOERR) go to 10
      call set_attributes(ncid,tempmean_id, &
             long_name='mean temperature',units='degC',&
             FillValue=fv,missing_value=mv,valid_range=vr)
   end if
#endif

   if (save_numerical_analyses) then

      fv = nummix_missing
      mv = nummix_missing
      vr(1) = -100.0
      vr(2) =  100.0
      err = nf90_def_var(ncid,'numdis3d',NCDF_FLOAT_PRECISION,f4_dims,nm3d_id)
      if (err .NE. NF90_NOERR) go to 10
      call set_attributes(ncid,nm3d_id, &
          long_name='mean numerical dissipation', &
          units='W/kg',&
          FillValue=fv,missing_value=mv,valid_range=vr)

      err = nf90_def_var(ncid,'numdis2d',NCDF_FLOAT_PRECISION,f3_dims,nm2d_id)
      if (err .NE. NF90_NOERR) go to 10
      call set_attributes(ncid,nm2d_id, &
          long_name='mean, vert. integrated numerical dissipation', &
          units='Wm/kg',&
          FillValue=fv,missing_value=mv,valid_range=vr)

      if (calc_salt) then
         err = nf90_def_var(ncid,'nummix3d_S',NCDF_FLOAT_PRECISION,f4_dims,nm3dS_id)
         if (err .NE. NF90_NOERR) go to 10
         call set_attributes(ncid,nm3dS_id, &
             long_name='mean numerical mixing of salinity', &
             units='psu**2/s',&
             FillValue=fv,missing_value=mv,valid_range=vr)

         err = nf90_def_var(ncid,'phymix3d_S',NCDF_FLOAT_PRECISION,f4_dims,pm3dS_id)
         if (err .NE. NF90_NOERR) go to 10
         call set_attributes(ncid,pm3dS_id, &
             long_name='mean physical mixing of salinity', &
             units='psu**2/s',&
             FillValue=fv,missing_value=mv,valid_range=vr)

         err = nf90_def_var(ncid,'nummix2d_S',NCDF_FLOAT_PRECISION,f3_dims,nm2dS_id)
         if (err .NE. NF90_NOERR) go to 10
         call set_attributes(ncid,nm2dS_id, &
             long_name='mean, vert.integrated numerical mixing of salinity', &
             units='psu**2 m/s',&
             FillValue=fv,missing_value=mv,valid_range=vr)

         err = nf90_def_var(ncid,'phymix2d_S',NCDF_FLOAT_PRECISION,f3_dims,pm2dS_id)
         if (err .NE. NF90_NOERR) go to 10
         call set_attributes(ncid,pm2dS_id, &
             long_name='mean, vert.integrated physical mixing of salinity', &
             units='psu**2 m/s',&
             FillValue=fv,missing_value=mv,valid_range=vr)
      end if

      if (calc_temp) then
         err = nf90_def_var(ncid,'nummix3d_T',NCDF_FLOAT_PRECISION,f4_dims,nm3dT_id)
         if (err .NE. NF90_NOERR) go to 10
         call set_attributes(ncid,nm3dT_id, &
             long_name='mean numerical mixing of temperature', &
             units='degC**2/s',&
             FillValue=fv,missing_value=mv,valid_range=vr)

         err = nf90_def_var(ncid,'phymix3d_T',NCDF_FLOAT_PRECISION,f4_dims,pm3dT_id)
         if (err .NE. NF90_NOERR) go to 10
         call set_attributes(ncid,pm3dT_id, &
             long_name='mean physical mixing of temperature', &
             units='degC**2/s',&
             FillValue=fv,missing_value=mv,valid_range=vr)

         err = nf90_def_var(ncid,'nummix2d_T',NCDF_FLOAT_PRECISION,f3_dims,nm2dT_id)
         if (err .NE. NF90_NOERR) go to 10
         call set_attributes(ncid,nm2dT_id, &
             long_name='mean, vert.integrated numerical mixing of temperature', &
             units='degC**2 m/s',&
             FillValue=fv,missing_value=mv,valid_range=vr)

         err = nf90_def_var(ncid,'phymix2d_T',NCDF_FLOAT_PRECISION,f3_dims,pm2dT_id)
         if (err .NE. NF90_NOERR) go to 10
         call set_attributes(ncid,pm2dT_id, &
             long_name='mean, vert.integrated physical mixing of temperature', &
             units='degC**2 m/s',&
             FillValue=fv,missing_value=mv,valid_range=vr)
      end if

   end if

#ifdef GETM_BIO
   allocate(biomean_id(numc),stat=err)
   if (err /= 0) stop 'init_3d_ncdf(): Error allocating memory (bio_ids)'

   fv = bio_missing
   mv = bio_missing
   vr(1) = -50.
   vr(2) = 9999.
   do n=1,numc
      err = nf90_def_var(ncid,trim(var_names(n)) // '_mean',NCDF_FLOAT_PRECISION, &
                         f4_dims,biomean_id(n))
      if (err .NE.  NF90_NOERR) go to 10
      call set_attributes(ncid,biomean_id(n), &
                          long_name=trim(var_long(n)), &
                          units=trim(var_units(n)), &
                          FillValue=fv,missing_value=mv,valid_range=vr)
   end do
#endif
#ifdef _FABM_
   if (allocated(fabm_pel)) then
      allocate(fabmmean_ids(size(model%state_variables)),stat=err)
      if (err /= 0) stop 'init_mean_ncdf(): Error allocating memory (fabmmean_ids)'
      fabmmean_ids = -1
      do n=1,size(model%state_variables)
         if (model%state_variables(n)%output==output_none) cycle
         err = nf90_def_var(ncid,model%state_variables(n)%name,NCDF_FLOAT_PRECISION,f4_dims,fabmmean_ids(n))
         if (err .NE.  NF90_NOERR) go to 10
         call set_attributes(ncid,fabmmean_ids(n), &
                          long_name    =trim(model%state_variables(n)%long_name), &
                          units        =trim(model%state_variables(n)%units),    &
                          FillValue    =model%state_variables(n)%missing_value,  &
                          missing_value=model%state_variables(n)%missing_value,  &
                          valid_min    =model%state_variables(n)%minimum,        &
                          valid_max    =model%state_variables(n)%maximum)
      end do

      allocate(fabmmean_ids_ben(size(model%bottom_state_variables)),stat=err)
      if (err /= 0) stop 'init_mean_ncdf(): Error allocating memory (fabmmean_ids_ben)'
      fabmmean_ids_ben = -1
      do n=1,size(model%bottom_state_variables)
         if (model%bottom_state_variables(n)%output==output_none) cycle
         err = nf90_def_var(ncid,model%bottom_state_variables(n)%name,NCDF_FLOAT_PRECISION,f3_dims,fabmmean_ids_ben(n))
         if (err .NE.  NF90_NOERR) go to 10
         call set_attributes(ncid,fabmmean_ids_ben(n), &
                       long_name    =trim(model%bottom_state_variables(n)%long_name), &
                       units        =trim(model%bottom_state_variables(n)%units),    &
                       FillValue    =model%bottom_state_variables(n)%missing_value,  &
                       missing_value=model%bottom_state_variables(n)%missing_value,  &
                       valid_min    =model%bottom_state_variables(n)%minimum,        &
                       valid_max    =model%bottom_state_variables(n)%maximum)
      end do

      allocate(fabmmean_ids_diag(size(model%diagnostic_variables)),stat=err)
      if (err /= 0) stop 'init_mean_ncdf(): Error allocating memory (fabmmean_ids_diag)'
      fabmmean_ids_diag = -1
      do n=1,size(model%diagnostic_variables)
         if (model%diagnostic_variables(n)%output==output_none) cycle
         err = nf90_def_var(ncid,model%diagnostic_variables(n)%name,NCDF_FLOAT_PRECISION,f4_dims,fabmmean_ids_diag(n))
         if (err .NE.  NF90_NOERR) go to 10
         call set_attributes(ncid,fabmmean_ids_diag(n), &
                       long_name    =trim(model%diagnostic_variables(n)%long_name), &
                       units        =trim(model%diagnostic_variables(n)%units),    &
                       FillValue    =model%diagnostic_variables(n)%missing_value,  &
                       missing_value=model%diagnostic_variables(n)%missing_value,  &
                       valid_min    =model%diagnostic_variables(n)%minimum,        &
                       valid_max    =model%diagnostic_variables(n)%maximum)
      end do

      allocate(fabmmean_ids_diag_hz(size(model%horizontal_diagnostic_variables)),stat=err)
      if (err /= 0) stop 'init_mean_ncdf(): Error allocating memory (fabmmean_ids_diag_hz)'
      fabmmean_ids_diag_hz = -1
      do n=1,size(model%horizontal_diagnostic_variables)
         if (model%horizontal_diagnostic_variables(n)%output==output_none) cycle
         err = nf90_def_var(ncid,model%horizontal_diagnostic_variables(n)%name,NCDF_FLOAT_PRECISION,f3_dims,fabmmean_ids_diag_hz(n))
         if (err .NE.  NF90_NOERR) go to 10
         call set_attributes(ncid,fabmmean_ids_diag_hz(n), &
                       long_name    =trim(model%horizontal_diagnostic_variables(n)%long_name), &
                       units        =trim(model%horizontal_diagnostic_variables(n)%units),    &
                       FillValue    =model%horizontal_diagnostic_variables(n)%missing_value,  &
                       missing_value=model%horizontal_diagnostic_variables(n)%missing_value,  &
                       valid_min    =model%horizontal_diagnostic_variables(n)%minimum,        &
                       valid_max    =model%horizontal_diagnostic_variables(n)%maximum)
      end do
   end if
#endif

!  globals
   err = nf90_put_att(ncid,NF90_GLOBAL,'title',trim(title))
   if (err .NE. NF90_NOERR) go to 10

   err = nf90_put_att(ncid,NF90_GLOBAL,'model ',trim(history))
   if (err .NE. NF90_NOERR) go to 10

#if 0
   err = nf90_put_att(ncid,NF90_GLOBAL,'git hash:   ',trim(git_commit_id))
   if (err .NE. NF90_NOERR) go to 10
   err = nf90_put_att(ncid,NF90_GLOBAL,'git branch: ',trim(git_branch_name))
   if (err .NE. NF90_NOERR) go to 10
#endif

!   history = FORTRAN_VERSION
!   err = nf90_put_att(ncid,NF90_GLOBAL,'compiler',trim(history))
!   if (err .NE. NF90_NOERR) go to 10

   ! leave define mode
   err = nf90_enddef(ncid)
   if (err .NE. NF90_NOERR) go to 10

   return

   10 FATAL 'init_mean_ncdf: ',nf90_strerror(err)
   stop 'init_mean_ncdf'
   end subroutine init_mean_ncdf
!EOC

!-----------------------------------------------------------------------
! Copyright (C) 2004 - Adolf Stips and Karsten Bolding (BBH)           !
!-----------------------------------------------------------------------
