!-------------------------------------- LICENCE BEGIN -------------------------
!Environment Canada - Atmospheric Science and Technology License/Disclaimer,
!                     version 3; Last Modified: May 7, 2008.
!This is free but copyrighted software; you can use/redistribute/modify it under the terms
!of the Environment Canada - Atmospheric Science and Technology License/Disclaimer
!version 3 or (at your option) any later version that should be found at:
!http://collaboration.cmc.ec.gc.ca/science/rpn.comm/license.html
!
!This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
!without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
!See the above mentioned License/Disclaimer for more details.
!You should have received a copy of the License/Disclaimer along with this software;
!if not, you can write to: EC-RPN COMM Group, 2121 TransCanada, suite 500, Dorval (Quebec),
!CANADA, H9P 1J3; or send e-mail to service.rpn@ec.gc.ca
!-------------------------------------- LICENCE END ---------------------------

subroutine mfoeic(ei,tt,ni,nk,n)
   use, intrinsic :: iso_fortran_env, only: REAL64
   use tdpack
   implicit none
!!!#include <arch_specific.hf>
   !@object calcule tension de vapeur saturante ei. (glace seulement)
   !       calculate the saturation vapour pressure. (Ice phase
   !       considered only for all temperatures)
   !@rguments
   !          - Output -
   ! ei       saturated vapour pressure in Pa
   !          - Input -
   ! tt       temperature in K
   ! ni       horizontal dimension
   ! nk       vertical dimension
   ! n        number of points to process
   integer ni, nk, n
   real ei(ni,nk), tt(ni,nk)
   !@author A. Plante (June 2003) - based on MFOEWA from N. Brunet  (Jan91)
   ! V.Lee (Dec 2021) - remove vexp, correction to use NI, not N for I loop
   integer i, k
   real(REAL64), dimension(ni,nk) :: work
   !--------------------------------------------------------------------
   do k=1,nk
      do i=1,ni
         work(i,k)=fesif(tt(i,k))
         work(i,k)=exp(work(i,k))
         ei(i,k)=aerk1i*work(i,k)
      enddo
   enddo
   !--------------------------------------------------------------------
   return
end subroutine mfoeic
