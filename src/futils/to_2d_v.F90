#include "cppdefs.h"
!-----------------------------------------------------------------------
!BOP
!
! !ROUTINE: Mask V-velocity and interpolate to T-points
!
! !INTERFACE:
   subroutine to_2d_v(imin,jmin,imax,jmax,az,v,DV,missing,              &
                      il,jl,ih,jh,vel)
!
! !DESCRIPTION:
! This routine linearly interpolates the vertically integrated velocity
! at $V$-points to the $T$-points, whenever the mask at the $T$-points is different
! from zero. Otherwise, the values are filled with a "missing value", {\tt missing}.
! The result is written to the output argument {\tt vel}, which is single precision
! vector for storage in netCDF.
!
! !USES:
   IMPLICIT NONE
!
! !INPUT PARAMETERS:
   integer,  intent(in)                :: imin,jmin,imax,jmax
   integer,  intent(in)                :: az(E2DFIELD)
   REALTYPE, intent(in)                :: v(E2DFIELD)
   REALTYPE, intent(in)                :: DV(E2DFIELD)
   REALTYPE, intent(in)                :: missing
   integer,  intent(in)                :: il,jl,ih,jh

! !OUTPUT PARAMETERS:
   REALTYPE, intent(out)               :: vel(E2DFIELD)
!
! !REVISION HISTORY:
!  Original author(s): Lars Umlauf
!
! !LOCAL VARIABLES:
   integer                             :: i,j
!EOP
!-----------------------------------------------------------------------
!BOC
   do j=jl,jh
      do i=il,ih
         if (az(i,j) .gt. 0) then
            vel(i,j) = 0.5*( v(i,j-1)/DV(i,j-1)                        &
                         +   v(i,j  )/DV(i,j  ) )
         else
            vel(i,j) = missing
         end if
      end do
   end do
   return
   end subroutine to_2d_v
!EOC

!-----------------------------------------------------------------------
! Copyright (C) 2001 - Hans Burchard and Karsten Bolding (BBH)         !
!-----------------------------------------------------------------------
