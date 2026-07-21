!     Last change:  MR   15 Jan 2001   12:07 pm
        module selroutines

        use selparameters
        use seltools

        implicit none

        contains

subroutine invrt(a,ia,n)
!
!     purpose : invert a non-symmetric matrix of order n
!               matrix must be non-singular (program stops if singularity is
!               encountered), but can be non-positive definite
!     strategy : use gauss-jordan algorithm
!                (with partial pivoting)
!                time required is proportional to the cubic power of theorder
!                of the matrix.
!                programmed after stoer,j. and bulirsch,r. : introduction to
!                numerical analysis. springer verlag 1980, pp. 169-172.
!                the original matrix is stored within the routine andmultiplied
!                with its inverse, the product is checked for deviationsfrom
!                the identity matrix
!     parameters :
!           - a  : matrix to be inverted, double precision, declared with
!                  row dimension ia and column dimension at least n in
!                  calling program;
!                  overwritten with inverse
!           - ia : row dimension of a (as declared)
!           - n  : order of the matrix to be inverted, must be stored in
!                  first n rows and columns of a
!     error stops : - matrix singular
!                   - program dimensions exceeded
!     routines required : none
!===============================================================================
!      implicit double precision (a-h,o-z)
!      dimension a(ia,n),b(49,49),vec(49),iflag(49)

	integer :: ia,i,j,k,n,mtrait,imax,isave
        integer, dimension(n) :: iflag
	real*8 :: xx,zz,diag,off,saved,zero
        real*8, dimension(n) :: vec
	real*8, dimension(n,n) :: a,b

!	mtrait=49
 !	if(n.gt.mtrait)stop "routine invert : program dimensions exceeded"

	!      minimum value to be distinguished from 0.e0
	zero=1.e-12
	diag=0.e0
	off=0.e0
        do i=1,n
          iflag(i)=i
	end do

	!      store matrix prior to inversion

   !     print *,"matrix a "
        do i=1,n
    !      print *, (a(i,k), k=1,n)
          do j=1,n
            b(j,i)=a(j,i)
	  end do
	end do
     !   print *," "

        !      find maximum element in the column (start at i-th el. only)
	do i=1,n
	  xx=abs(a(i,i))
	  imax=i
	  do j=i+1,n
	    zz=abs(a(j,i))
	      if(zz.gt.xx)then
	        xx=zz
	        imax=j
	      end if
	  end do
	     !      check for singularity
	  if(xx.lt.zero) then
	    print *," -error-10- : matrix is singular"
            stop
	  end if

	!     interchange row i and row with max. element in the column
	  if(imax.gt.i)then
	    do k=1,n
	      saved=a(i,k)
	      a(i,k)=a(imax,k)
	      a(imax,k)=saved
	    end do
	    isave=iflag(i)
	    iflag(i)=iflag(imax)
	    iflag(imax)=isave
	  end if

	!     transform the matrix
	  saved=1.e0/a(i,i)
	  do j=1,n
	    a(j,i)=a(j,i)*saved
	  end do
          a(i,i)=saved
          do k=1,n
            if(k.eq.i) then
	      go to 6
	    end if
            do j=1,n
              if(j.ne.i) then
	        a(j,k)=a(j,k)-a(j,i)*a(i,k)
	      end if
	    end do
	    a(i,k)=-a(i,k)*saved
 6	  end do
	end do

	!      interchange columns (analogous to previous row changes )
        do i=1,n
          do k=1,n
            j=iflag(k)
            vec(j)=a(i,k)
	  end do
          do k=1,n
            a(i,k)=vec(k)
	  end do
        end do

	!     multiply matrix with its inverse, check elements
        do i=1,n
          do j=1,n
            xx=0.e0
            do k=1,n
              xx=xx+a(k,j)*b(i,k)
	    end do
            if(i.eq.j)then
              diag=diag+xx
            else
              off=off+xx
            end if
          end do
	end do

      end subroutine invrt

!=======================================================

          subroutine trunc(pval,xval,zval,ival,kval)
	!==============================================================================
	!   subroutine trunc
	!   calculates standard selection parameters for upper tail truncation
	!   f90 revision: john a. woolliams 13/11/96
	!==============================================================================

          use seltools
          implicit none
          integer :: ix
          real, intent(in) :: pval
          real, intent(inout), optional :: xval,zval,ival,kval
          real :: zero=0.0,one=1.0,two=2.0,pi,x,z,i

          pi=two*acos(zero)
          select case ((pval.ge.zero).and.(pval.le.one))

            case(.true.)
            x=-gcef(pval,ix)
            z=exp(-x*x/two)/sqrt(two*pi)
            i=z/pval
            if(present(xval)) xval=x
            if(present(zval)) zval=z
            if(present(ival)) ival=i
            if(present(kval)) kval=i*(i-x)

            case default
            print *, " -error-20- : P-value out of bounds"
            stop
          end select
        end subroutine trunc

!=====================================================

	subroutine intro(loczzz)
          use selparameters

	  implicit none
          integer :: loczzz

	  if (loczzz.eq.1) then
	    print *," "
            print *," "
            print *,"                  **************************************************"
            print *,"                  *   Multi-Trait Index Selection Software MSSEL   *"
            print *,"                  *                 developed by:                  *"
            print *,"                  *                                                *"
            print *,"                  *        Marc J.M. Rutten and Piter Bijma        *"
            print *,"                  *                                                *"
            print *,"                  *                  version 1.1                   *"
            print *,"                  *                                                *"
            print *,"                  *       Animal Breeding and Genetics Group       *"
            print *,"                  *          Wageningen University, 2000           *"
            print *,"                  **************************************************"
            print *," "
            print *," "
	  else
            write(unit=20, fmt=*) " "
            write(unit=20, fmt=*) "            *************************************************"
            write(unit=20, fmt=*) "            *   Multi-Trait Index Selection Software MSSEL  *"
            write(unit=20, fmt=*) "            *                 developed by:                 *"
            write(unit=20, fmt=*) "            *                                               *"
            write(unit=20, fmt=*) "            *        Marc J.M. Rutten and Piter Bijma       *"
            write(unit=20, fmt=*) "            *                                               *"
            write(unit=20, fmt=*) "            *                  version 1.1                  *"
            write(unit=20, fmt=*) "            *                                               *"
            write(unit=20, fmt=*) "            *       Animal Breeding and Genetics Group      *"
            write(unit=20, fmt=*) "            *          Wageningen University, 2000          *"
            write(unit=20, fmt=*) "            *************************************************"
            write(unit=20, fmt=*) " "
            write(unit=20, fmt=*) " "
	  end if

	end subroutine intro

!==========================================================

	subroutine note_pheninfo(localxtraits,localinit)

       	  implicit none

	  character (len=1) :: localinit
	  character (len=8), intent(in) :: localxtraits

	  print *," "
	  print *,"warning: "
	  print *," "
	  print *,localxtraits," has got no phenotypic information sources."
	  print *,"it also has got no genetic correlation with other traits"
	  print *,"which do have phenotypic information sources."
	  print *,"the genetic variances of ",localxtraits
	  print *,"will drop to zero eventually, and this results in a"
	  print *,"singular p-matrix. since a singular matrix can't be"
	  print *,"inverted, the calculations will stall."
	  print *," "
	  print *,"either include phenotypic information sources for"
	  print *,localxtraits," or give ",localxtraits," a genetic"
	  print *,"correlation with another trait which does have phenotypic"
	  print *,"information sources."
          print *," "

33000	  print *,"edit information sources(i) or edit correlations(c)"
          print *," "
 	  read *,localinit
          write(unit=10, fmt=12000) localinit

12000   format(a10," ! information sources or correlation to be changed")

	  if (localinit.eq."i") then
	    continue
	  else if (localinit.eq."c") then
	    continue
	  else
	    goto 33000
	  end if

	end subroutine note_pheninfo

!==========================================================

	subroutine note_matrat

	  implicit none

          print *," "
          print *,"warning: "
          print *," "
	  print *,"a mating ratio of 1 has been given as input value"
	  print *,"implications:"
          print *," "
	  print *,"* all offspring are full-sibs, half-sib information"
	  print *,"is thus not possible, and will be removed."
          print *," "
          print *," "
          
        end subroutine note_matrat

!=============================================================

	subroutine info_sources(locp,locxtraits,loctempsource,locits,loctempsourceres, &
             & locitsres,locpheninfo,locproginfo,locinitindsel,locindexdiff,locntraits, &
             & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams,hsgroupsoff, &
             & proggroupsdams,proggroupsoff,nstag)

	implicit none

        integer :: locits,locproginfo,locp,i,locntraits,locitsres
        integer :: fsgroups,hsgroups,proggroups,j,k,l,nstag
        real, dimension(20) :: fsgroupsoff,hsgroupsdams,hsgroupsoff
        real, dimension(20) :: proggroupsdams,proggroupsoff
        integer, dimension(20) :: loctempsource3
        integer, dimension(84) :: loctempsource2,tempsort
        integer, dimension(locntraits,84) :: loctempsource
        integer, dimension(locntraits,84) :: loctempsourceres
        character(len=1) :: locpheninfo,locindexdiff,locinitindsel,initblup
        character(len=8) :: locxtraits

        if (nstag.eq.0) then
          if (locinitindsel.eq."s" .and. locindexdiff.eq."y") then
            print *,"information sources for the sires"
          else if (locinitindsel.eq."d" .and. locindexdiff.eq."y") then
            print *,"information sources for the dams"
          else
            print *,"information sources"
          end if
        end if

        if (nstag.eq.1) then
          if (locinitindsel.eq."s" .and. locindexdiff.eq."y") then
            print *,"information sources for the sires for stage 1"
          else if (locinitindsel.eq."d" .and. locindexdiff.eq."y") then
            print *,"information sources for the dams for stage 1"
          else
            print *,"information sources for stage 1"
          end if
        end if

	if (locits.ne.0) then
	  print *,"current information sources for ",locxtraits,":"
	  do i=1,locits-1
	    if (loctempsource(locp,i).eq.1) then
	      print *,loctempsource(locp,i)," = own performance"
	    else if (loctempsource(locp,i).eq.2) then
              print *,loctempsource(locp,i)," = BLUP breeding values"
	    else if (loctempsource(locp,i).ge.4 .and. loctempsource(locp,i).le.23) then
	      print *,loctempsource(locp,i)," = full-sib group ",loctempsource(locp,i)-3
	    else if (loctempsource(locp,i).ge.24 .and. loctempsource(locp,i).le.43) then
	      print *,loctempsource(locp,i)," = half-sib group ",loctempsource(locp,i)-23
	    else if (loctempsource(locp,i).ge.64 .and. loctempsource(locp,i).le.83) then
	      print *,loctempsource(locp,i)," = progeny group ",loctempsource(locp,i)-63
            else
              continue
            end if
	  end do
	end if

 12900  locpheninfo="n"
        do i=1,84
          loctempsource(locp,i)=0
        end do
        loctempsource2=0
        loctempsource3=0
        print *,"                        ",locxtraits,":"
        print *,"  1 = own performance"
        print *,"  2 = BLUP breeding values"
        do i=1,fsgroups
          print *," ",i+3,"= full-sib group ",i," with ",fsgroupsoff(i)," animals"
        end do
        do i=1,hsgroups
          print *," ",i+23,"= half-sib group ",i," with ",hsgroupsdams(i)," dams, producing ",hsgroupsoff(i),"animals"
        end do
        do i=1,proggroups
          print *," ",i+63,"= progeny group ",i," with ",proggroupsdams(i)," dams, producing",proggroupsoff(i),"progeny"
        end do
        print *," "
        print *," which information sources are available?"
        print *,"  -1 = end of input"
        print *," "

	! read source array
	locits=1
        read *,loctempsource(locp,locits)
        do while (loctempsource(locp,locits).ne.-1)
	  locits=locits+1
	  read *,loctempsource(locp,locits)
	end do

        ! sort source array
        tempsort=0
        if (locits.gt.2) then
          do j=1,84
            tempsort(j)=loctempsource(locp,j)
          end do
          call sort(tempsort,locits)
          do j=1,84
            loctempsource(locp,j)=tempsort(j)
          end do
        end if

        loctempsourceres=loctempsource
        locitsres=locits
        j=1
        k=1
        do i=1,locits
          if (loctempsource(locp,i).eq.2) then
            initblup="y"
            loctempsource2(j)=loctempsource(locp,i)
            if (locindexdiff.eq."y" .and. locinitindsel.eq."s") then
              write(unit=10, fmt=13001) loctempsource2(j),locxtraits
            else if (locindexdiff.eq."y" .and. locinitindsel.eq."d") then
              write(unit=10, fmt=13002) loctempsource2(j),locxtraits
            else
              write(unit=10, fmt=13000) loctempsource2(j),locxtraits
            end if
            j=j+1
            loctempsource2(j)=3
            j=j+1
          else if (loctempsource(locp,i).ge.24 .and. loctempsource(locp,i).le.43 .and. initblup.eq."y") then
            loctempsource2(j)=loctempsource(locp,i)
            if (locindexdiff.eq."y" .and. locinitindsel.eq."s") then
              write(unit=10, fmt=13001) loctempsource2(j),locxtraits
            else if (locindexdiff.eq."y" .and. locinitindsel.eq."d") then
              write(unit=10, fmt=13002) loctempsource2(j),locxtraits
            else
              write(unit=10, fmt=13000) loctempsource2(j),locxtraits
            end if
            j=j+1
            loctempsource3(k)=loctempsource(locp,i)
            k=k+1
            if (loctempsource(locp,i+1).ge.64 .or. loctempsource(locp,i+1).eq.-1) then
              do l=1,k-1
                loctempsource2(j)=(loctempsource3(l)+20)
                j=j+1
              end do
            end if
          else
            loctempsource2(j)=loctempsource(locp,i)
            if (locindexdiff.eq."y" .and. locinitindsel.eq."s") then
              write(unit=10, fmt=13001) loctempsource2(j),locxtraits
            else if (locindexdiff.eq."y" .and. locinitindsel.eq."d") then
              write(unit=10, fmt=13002) loctempsource2(j),locxtraits
            else
              write(unit=10, fmt=13000) loctempsource2(j),locxtraits
            end if
            j=j+1
          end if
        end do
        initblup="n"

        locits=j-1
        do i=1,84
          loctempsource(locp,i)=loctempsource2(i)
        end do

        do i=1,locits
          if (loctempsource(locp,i).eq.1) then
            locpheninfo="y"
          else if (loctempsource(locp,i).ge.4 .and. loctempsource(locp,i).le.43) then
            locpheninfo="y"
          else if (loctempsource(locp,i).ge.64 .and. loctempsource(locp,i).le.83) then
            locpheninfo="y"
          else
            continue
          end if
        end do
  !     print *,"locpheninfo ",locpheninfo

  !     print *,"loctempsource in routines",loctempsource
   !    print *,"locits in routines",locits

     !  print *,"loctempsource zonder blup in routines",loctempsourceres
      ! print *,"locitsres in routines",locitsres

13000   format(i10," ! info source ",a8)
13001   format(i10," ! info source ",a8," for males")
13002   format(i10," ! info source ",a8," for females")

	end subroutine info_sources

!=============================================================

	subroutine info_sourcesovlp(locp,locq,locxtraits,loctempsource,locits, &
             & locpheninfo,locproginfo,locntraits,locnclass, &
             & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams,hsgroupsoff, &
             & proggroupsdams,proggroupsoff)
             ! locp=trait locq=class
	implicit none

        integer :: locits,locproginfo,locp,i,locntraits,locq,locnclass
        integer :: fsgroups,hsgroups,proggroups,j,k,l,nstag
        real, dimension(20) :: fsgroupsoff,hsgroupsdams,hsgroupsoff
        real, dimension(20) :: proggroupsdams,proggroupsoff
        integer, dimension(20) :: loctempsource3
        integer, dimension(84) :: loctempsource2,tempsort
        integer, dimension(2*locnclass,locntraits,84) :: loctempsource
        character(len=1) :: locpheninfo,locindexdiff,initblup
        character(len=8) :: locxtraits

	if (locits.ne.0) then
	  print *,"current information sources for ",locxtraits," in age-class ",locq
	  do i=1,locits-1
	    if (loctempsource(locq,locp,i).eq.1) then
	      print *,loctempsource(locq,locp,i)," = own performance"
	    else if (loctempsource(locq,locp,i).eq.2) then
              print *,loctempsource(locq,locp,i)," = BLUP breeding values"
	    else if (loctempsource(locq,locp,i).ge.4 .and. loctempsource(locq,locp,i).le.23) then
	      print *,loctempsource(locq,locp,i)," = full-sib group ",loctempsource(locq,locp,i)-3
	    else if (loctempsource(locq,locp,i).ge.24 .and. loctempsource(locq,locp,i).le.43) then
	      print *,loctempsource(locq,locp,i)," = half-sib group ",loctempsource(locq,locp,i)-23
	    else if (loctempsource(locq,locp,i).ge.64 .and. loctempsource(locq,locp,i).le.83) then
	      print *,loctempsource(locq,locp,i)," = progeny group ",loctempsource(locq,locp,i)-63
            else
              continue
            end if
	  end do
        else
	  print *,"information sources for ",locxtraits," in age-class ",locq
        end if

 12900  locpheninfo="n"
        do i=1,84
          loctempsource(locq,locp,i)=0
        end do
        loctempsource2=0
        loctempsource3=0
        print *,"                        ",locxtraits,":"
        print *,"  1 = own performance"
        print *,"  2 = BLUP breeding values"
        do i=1,fsgroups
          print *," ",i+3,"= full-sib group ",i," with ",fsgroupsoff(i)," animals"
        end do
        do i=1,hsgroups
          print *," ",i+23,"= half-sib group ",i," with ",hsgroupsdams(i)," dams, producing ",hsgroupsoff(i),"animals"
        end do
        do i=1,proggroups
          print *," ",i+63,"= progeny group ",i," with ",proggroupsdams(i)," dams, producing",proggroupsoff(i),"progeny"
        end do
        print *," "
        print *," which information sources are available?"
        print *,"  -1 = end of input"
        print *," "

  	! read source array
	locits=1
        read *,loctempsource(locq,locp,locits)
        do while (loctempsource(locq,locp,locits).ne.-1)
	  locits=locits+1
	  read *,loctempsource(locq,locp,locits)
	end do

        ! sort source array
        tempsort=0
        if (locits.gt.2) then
          do j=1,84
            tempsort(j)=loctempsource(locq,locp,j)
          end do
          call sort(tempsort,locits)
          do j=1,84
            loctempsource(locq,locp,j)=tempsort(j)
          end do
        end if

        ! insert BLUP codes
        loctempsource2=0
        loctempsource3=0
        j=1
        k=1
        do i=1,locits
          if (loctempsource(locq,locp,i).eq.2) then
            initblup="y"
            loctempsource2(j)=loctempsource(locq,locp,i)
            write(unit=10, fmt=13000) loctempsource2(j),locxtraits,locq
            j=j+1
            loctempsource2(j)=3
            j=j+1
          else if (loctempsource(locq,locp,i).ge.24 .and. loctempsource(locq,locp,i).le.43 .and. initblup.eq."y") then
            loctempsource2(j)=loctempsource(locq,locp,i)
            write(unit=10, fmt=13000) loctempsource2(j),locxtraits,locq
            j=j+1
            loctempsource3(k)=loctempsource(locq,locp,i)
            k=k+1
            if (loctempsource(locq,locp,i+1).ge.64 .or. loctempsource(locq,locp,i+1).eq.-1) then
              do l=1,k-1
                loctempsource2(j)=(loctempsource3(l)+20)
                j=j+1
              end do
            end if
          else
            loctempsource2(j)=loctempsource(locq,locp,i)
            write(unit=10, fmt=13000) loctempsource2(j),locxtraits,locq
            j=j+1
          end if
        end do
        initblup="n"

        locits=j-1
        do i=1,84
          loctempsource(locq,locp,i)=loctempsource2(i)
        end do

        do i=1,locits
          if (loctempsource(locq,locp,i).eq.1) then
            locpheninfo="y"
          else if (loctempsource(locq,locp,i).ge.4 .and. loctempsource(locq,locp,i).le.43) then
            locpheninfo="y"
          else if (loctempsource(locq,locp,i).ge.64 .and. loctempsource(locq,locp,i).le.83) then
            locpheninfo="y"
          else
            continue
          end if
        end do

13000   format(i10," ! info source ",a8," for age class ",i3)

	end subroutine info_sourcesovlp


!=============================================================
        subroutine sort(array,elements)
        implicit none

        integer :: i,value,elements,maxvalue
        integer, dimension(84) :: array

        ! first find maximum element and place it last in array
        maxvalue=maxval(array)
        value=array(elements-1)
        array(elements-1)=maxvalue
        do i=1,elements-1
          if (array(i).eq.maxvalue) then
            array(i)=value
            goto 27000
          end if
        end do

27000   if (elements.gt.3) then
          do i=1,elements-3
            if (array(elements-1-i).gt.array(elements-2-i)) then
              continue
            else
              value=array(elements-1-i)
              array(elements-1-i)=array(elements-2-i)
              array(elements-2-i)=value
              goto 27000
            end if
          end do
        end if

        end subroutine sort

!=============================================================
   	subroutine info_sources2(locp,locxtraits,loctempsource,locits,loctempsourcems2, &
             & locits2,locpheninfo,locproginfo,locinitindsel,locindexdiff,locntraits, &
             & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams,hsgroupsoff, &
             & proggroupsdams,proggroupsoff)

	implicit none

        integer :: locits,locproginfo,locp,i,locntraits,telrem
        integer :: fsgroups,hsgroups,proggroups,j,k,l,locits2
        real, dimension(20) :: fsgroupsoff,hsgroupsdams,hsgroupsoff
        real, dimension(20) :: proggroupsdams,proggroupsoff
        integer, dimension(84) :: tempsort,loctempsource2
        integer, dimension(20) :: loctempsource3
        integer, dimension(locntraits,84) :: loctempsource,loctempsourcems2
        character(len=1) :: locpheninfo,locindexdiff,locinitindsel,initblup,presone,prestwo
        character(len=1), dimension(20) :: presfs,preshs,presprog
        character(len=8) :: locxtraits

      ! print *,"locits",locits
   !    print *,"loctempsource",loctempsource
    !   print *,"locits2",locits2
     !  print *,"loctempsourcems2",loctempsourcems2

        if (locinitindsel.eq."s" .and. locindexdiff.eq."y") then
          print *,"information sources for the sires"
        else if (locinitindsel.eq."d" .and. locindexdiff.eq."y") then
          print *,"information sources for the dams"
        else
          print *,"information sources"
        end if

12900   continue
	! loctempsource2=0
       ! loctempsource3=0
        presone="n"
        prestwo="n"
        presfs="n"
        preshs="n"
        presprog="n"
        do i=1,84
          loctempsourcems2(locp,i)=loctempsource(locp,i)
        end do
        if (locits.eq.0) then
          locits2=1
        else
          locits2=locits
        end if
        print *,"information sources for ",locxtraits," in stage 2:"
        print *," "
        telrem=0
        do i=1,locits-1
          if (loctempsource(locp,i).eq.1) then
            presone="y"
          end if
        end do
        if (presone.eq."n") then
          print *,"  1 = own performance"
          telrem=telrem+1
        end if
        do i=1,locits-1
          if (loctempsource(locp,i).eq.2) then
            prestwo="y"
          end if
        end do
        if (prestwo.eq."n") then
          print *,"  2 = BLUP breeding values"
          telrem=telrem+1
        end if
        do i=1,locits-1
          if (loctempsource(locp,i).ge.4 .and. loctempsource(locp,i).le.23) then
            presfs(loctempsource(locp,i)-3)="y"
          end if
        end do
        do j=1,fsgroups
          if (presfs(j).eq."n") then
            print *,"  ",j+3,"= full-sib group ",j," with ",fsgroupsoff(j)," animals"
            telrem=telrem+1
          end if
        end do
        do i=1,locits-1
          if (loctempsource(locp,i).ge.24 .and. loctempsource(locp,i).le.43) then
            preshs(loctempsource(locp,i)-23)="y"
          end if
        end do
        do j=1,hsgroups
          if (preshs(j).eq."n") then
            print *,"  ",j+23,"= half-sib group ",j," with ",hsgroupsdams(j)," dams, producing ",hsgroupsoff(j),"animals"
            telrem=telrem+1
          end if
        end do
        do i=1,locits-1
          if (loctempsource(locp,i).ge.64 .and. loctempsource(locp,i).le.83) then
            presprog(loctempsource(locp,i)-63)="y"
          end if
        end do
        do j=1,proggroups
          if (presprog(j).eq."n") then
            print *,"  ",j+63,"= progeny group ",j," with ",proggroupsdams(j)," dams, producing ",proggroupsoff(j),"progeny"
            telrem=telrem+1
          end if
        end do
        print *," "
        print *," which additional information sources are available for stage 2 ?"
        print *,"  -1 = end of input"
        print *," "

        ! read source array for stage 2
        if (telrem.eq.0) then
          print *," no remaining information sources for",locxtraits
        else
          read *,loctempsourcems2(locp,locits2)
          if (locindexdiff.eq."y" .and. locinitindsel.eq."s") then
            write(unit=10, fmt=13001) loctempsourcems2(locp,locits2),locxtraits
          else if (locindexdiff.eq."y" .and. locinitindsel.eq."d") then
            write(unit=10, fmt=13002) loctempsourcems2(locp,locits2),locxtraits
          else
            write(unit=10, fmt=13000) loctempsourcems2(locp,locits2),locxtraits
          end if
          do while (loctempsourcems2(locp,locits2).ne.-1)
            locits2=locits2+1
            read *,loctempsourcems2(locp,locits2)
            if (locindexdiff.eq."y" .and. locinitindsel.eq."s") then
              write(unit=10, fmt=13001) loctempsourcems2(locp,locits2),locxtraits
            else if (locindexdiff.eq."y" .and. locinitindsel.eq."d") then
              write(unit=10, fmt=13002) loctempsourcems2(locp,locits2),locxtraits
            else
              write(unit=10, fmt=13000) loctempsourcems2(locp,locits2),locxtraits
            end if
          end do
        end if
!        print *,"voor sort"
 !       print *,"locits2 voor sort",locits2
 !      print *,"loctempsourcems2 na lezen",loctempsourcems2
  !     print *,"locits2 na lezen",locits2
        tempsort=0
        if (locits2.gt.2) then
          do j=1,84
            tempsort(j)=loctempsourcems2(locp,j)
          end do
          call sort(tempsort,locits2)
          do j=1,84
            loctempsourcems2(locp,j)=tempsort(j)
          end do
        end if
!      print *,"loctempsourcems2 na sort",loctempsourcems2
        loctempsource=loctempsourcems2 ! let op===========
     !  print *,"na sort"
        locits=locits2

        ! insert BLUP codes after stage 2
        loctempsource2=0
        loctempsource3=0
        j=1
        k=1
        do i=1,locits2
          if (loctempsourcems2(locp,i).eq.2) then
            initblup="y"
            loctempsource2(j)=loctempsourcems2(locp,i)
            j=j+1
            loctempsource2(j)=3
            j=j+1
          else if (loctempsourcems2(locp,i).ge.24 .and. loctempsourcems2(locp,i).le.43 .and. initblup.eq."y") then
            loctempsource2(j)=loctempsourcems2(locp,i)
            j=j+1
            loctempsource3(k)=loctempsourcems2(locp,i)
            k=k+1
            if (loctempsourcems2(locp,i+1).ge.64 .or. loctempsourcems2(locp,i+1).eq.-1) then
              do l=1,k-1
                loctempsource2(j)=(loctempsource3(l)+20)
                j=j+1
              end do
            end if
          else
            loctempsource2(j)=loctempsourcems2(locp,i)
            j=j+1
          end if
        end do
        initblup="n"
        locits2=j-1
    !   print *,"na insert blup locits2",locits2
        do j=1,84
          loctempsourcems2(locp,j)=loctempsource2(j)
        end do
 !      print *,"loctempsourcems2 na blup",loctempsourcems2

        do i=1,locits2
          if (loctempsourcems2(locp,i).eq.1) then
            locpheninfo="y"
          else if (loctempsourcems2(locp,i).ge.4 .and. loctempsourcems2(locp,i).le.43) then
            locpheninfo="y"
          else if (loctempsourcems2(locp,i).ge.64 .and. loctempsourcems2(locp,i).le.83) then
            locpheninfo="y"
          else
            continue
          end if
        end do
      ! print *,"locpheninfo ",locpheninfo

13000   format(i10," ! info source ",a8," in stage 2")
13001   format(i10," ! info source ",a8," in stage 2 for males")
13002   format(i10," ! info source ",a8," in stage 2 for females")

	end subroutine info_sources2

!=============================================================

   	subroutine info_sources3(locp,locxtraits,loctempsource,locits,loctempsourcems2, &
             & locits2,locpheninfo,locproginfo,locinitindsel,locindexdiff,locntraits, &
             & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams,hsgroupsoff, &
             & proggroupsdams,proggroupsoff)

	implicit none

        integer :: locits,locproginfo,locp,i,locntraits,telrem
        integer :: fsgroups,hsgroups,proggroups,j,k,l,locits2
        real, dimension(20) :: fsgroupsoff,hsgroupsdams,hsgroupsoff
        real, dimension(20) :: proggroupsdams,proggroupsoff
        integer, dimension(84) :: tempsort,loctempsource2
        integer, dimension(20) :: loctempsource3
        integer, dimension(locntraits,84) :: loctempsource,loctempsourcems2
        character(len=1) :: locpheninfo,locindexdiff,locinitindsel,initblup,presone,prestwo
        character(len=1), dimension(20) :: presfs,preshs,presprog
        character(len=8) :: locxtraits

      ! print *,"locits",locits
   !    print *,"loctempsource",loctempsource
    !   print *,"locits2",locits2
     !  print *,"loctempsourcems2",loctempsourcems2

        if (locinitindsel.eq."s" .and. locindexdiff.eq."y") then
          print *,"information sources for the sires"
        else if (locinitindsel.eq."d" .and. locindexdiff.eq."y") then
          print *,"information sources for the dams"
        else
          print *,"information sources"
        end if

12900   continue
	! loctempsource2=0
       ! loctempsource3=0
        presone="n"
        prestwo="n"
        presfs="n"
        preshs="n"
        presprog="n"
        do i=1,84
          loctempsourcems2(locp,i)=loctempsource(locp,i)
        end do
        if (locits.eq.0) then
          locits2=1
        else
          locits2=locits
        end if
        print *,"information sources for ",locxtraits," in stage 3:"
        print *," "
        telrem=0
        do i=1,locits-1
          if (loctempsource(locp,i).eq.1) then
            presone="y"
          end if
        end do
        if (presone.eq."n") then
          print *,"  1 = own performance"
          telrem=telrem+1
        end if
        do i=1,locits-1
          if (loctempsource(locp,i).eq.2) then
            prestwo="y"
          end if
        end do
        if (prestwo.eq."n") then
          print *,"  2 = BLUP breeding values"
          telrem=telrem+1
        end if
        do i=1,locits-1
          if (loctempsource(locp,i).ge.4 .and. loctempsource(locp,i).le.23) then
            presfs(loctempsource(locp,i)-3)="y"
          end if
        end do
        do j=1,fsgroups
          if (presfs(j).eq."n") then
            print *,"  ",j+3,"= full-sib group ",j," with ",fsgroupsoff(j)," animals"
            telrem=telrem+1
          end if
        end do
        do i=1,locits-1
          if (loctempsource(locp,i).ge.24 .and. loctempsource(locp,i).le.43) then
            preshs(loctempsource(locp,i)-23)="y"
          end if
        end do
        do j=1,hsgroups
          if (preshs(j).eq."n") then
            print *,"  ",j+23,"= half-sib group ",j," with ",hsgroupsdams(j)," dams, producing ",hsgroupsoff(j),"animals"
            telrem=telrem+1
          end if
        end do
        do i=1,locits-1
          if (loctempsource(locp,i).ge.64 .and. loctempsource(locp,i).le.83) then
            presprog(loctempsource(locp,i)-63)="y"
          end if
        end do
        do j=1,proggroups
          if (presprog(j).eq."n") then
            print *,"  ",j+63,"= progeny group ",j," with ",proggroupsdams(j)," dams, producing ",proggroupsoff(j),"progeny"
            telrem=telrem+1
          end if
        end do
        print *," "
        print *," which additional information sources are available for stage 3 ?"
        print *,"  -1 = end of input"
        print *," "

        ! read source array for stage 2
        if (telrem.eq.0) then
          print *," no remaining information sources for",locxtraits
        else
          read *,loctempsourcems2(locp,locits2)
          if (locindexdiff.eq."y" .and. locinitindsel.eq."s") then
            write(unit=10, fmt=13001) loctempsourcems2(locp,locits2),locxtraits
          else if (locindexdiff.eq."y" .and. locinitindsel.eq."d") then
            write(unit=10, fmt=13002) loctempsourcems2(locp,locits2),locxtraits
          else
            write(unit=10, fmt=13000) loctempsourcems2(locp,locits2),locxtraits
          end if
          do while (loctempsourcems2(locp,locits2).ne.-1)
            locits2=locits2+1
            read *,loctempsourcems2(locp,locits2)
            if (locindexdiff.eq."y" .and. locinitindsel.eq."s") then
              write(unit=10, fmt=13001) loctempsourcems2(locp,locits2),locxtraits
            else if (locindexdiff.eq."y" .and. locinitindsel.eq."d") then
              write(unit=10, fmt=13002) loctempsourcems2(locp,locits2),locxtraits
            else
              write(unit=10, fmt=13000) loctempsourcems2(locp,locits2),locxtraits
            end if
          end do
        end if
!        print *,"voor sort"
 !       print *,"locits2 voor sort",locits2
    !   print *,"loctempsourcems2 na lezen",loctempsourcems2
     !  print *,"locits2 na lezen",locits2
        tempsort=0
        if (locits2.gt.2) then
          do j=1,84
            tempsort(j)=loctempsourcems2(locp,j)
          end do
          call sort(tempsort,locits2)
          do j=1,84
            loctempsourcems2(locp,j)=tempsort(j)
          end do
        end if
     ! print *,"loctempsourcems2 na sort",loctempsourcems2
        loctempsource=loctempsourcems2 ! let op===========
     !  print *,"na sort"
        locits=locits2

        ! insert BLUP codes after stage 3
        loctempsource2=0
        loctempsource3=0
        j=1
        k=1
        do i=1,locits2
          if (loctempsourcems2(locp,i).eq.2) then
            initblup="y"
            loctempsource2(j)=loctempsourcems2(locp,i)
            j=j+1
            loctempsource2(j)=3
            j=j+1
          else if (loctempsourcems2(locp,i).ge.24 .and. loctempsourcems2(locp,i).le.43 .and. initblup.eq."y") then
            loctempsource2(j)=loctempsourcems2(locp,i)
            j=j+1
            loctempsource3(k)=loctempsourcems2(locp,i)
            k=k+1
            if (loctempsourcems2(locp,i+1).ge.64 .or. loctempsourcems2(locp,i+1).eq.-1) then
              do l=1,k-1
                loctempsource2(j)=(loctempsource3(l)+20)
                j=j+1
              end do
            end if
          else
            loctempsource2(j)=loctempsourcems2(locp,i)
            j=j+1
          end if
        end do
        initblup="n"
        locits2=j-1
    !   print *,"na insert blup locits2",locits2
        do j=1,84
          loctempsourcems2(locp,j)=loctempsource2(j)
        end do
    !   print *,"loctempsourcems2 na blup",loctempsourcems2

        do i=1,locits2
          if (loctempsourcems2(locp,i).eq.1) then
            locpheninfo="y"
          else if (loctempsourcems2(locp,i).ge.4 .and. loctempsourcems2(locp,i).le.43) then
            locpheninfo="y"
          else if (loctempsourcems2(locp,i).ge.64 .and. loctempsourcems2(locp,i).le.83) then
            locpheninfo="y"
          else
            continue
          end if
        end do
    !   print *,"locpheninfo ",locpheninfo

13000   format(i10," ! info source ",a8," in stage 3")
13001   format(i10," ! info source ",a8," in stage 3 for males")
13002   format(i10," ! info source ",a8," in stage 3 for females")


        end subroutine info_sources3

!=====================================================

        subroutine traitinfo

        use selparameters

        implicit none

	! get trait info and destination
        counth=0
        countb=0
        if (indexdiff.eq."y") then
          if (nstag.eq.1) then
            print *,"trait information for the sires for stage 1"
          else
            print *,"trait information for the sires"
          end if
        else
          if (nstag.eq.1) then
            print *,"trait information for stage 1"
          else
            print *,"trait information"
            print *," "
          end if
        end if

	do i=1,ntraits
	  print *,"name of trait ",i," ? (max 8 characters)"
          print *," "
	  read *,xtraits(i)
          write(unit=10, fmt=14000) xtraits(i),i
700       if (ntraits.eq.1) then
            sdesttraits(1)="b"
            goto 702
          else
	    print *,"use ",xtraits(i),": in the index (i),"
	    print *,"              in the breeding goal (h),"
	    print *,"              in the index AND breeding goal (b),"
	    print *,"              or not at this moment (n) ?"
          end if
          print *," "
          read *,sdesttraits(i)
          write(unit=10, fmt=14001) sdesttraits(i),xtraits(i)
702       if (sdesttraits(i).eq."n") then
            print *," "
            print *,xtraits(i)," not used"
          else if (sdesttraits(i).eq."i") then
            print *," "
	    print *,xtraits(i)," used in index"
          else if (sdesttraits(i).eq."h") then
            print *," "
	    print *,xtraits(i)," used in breeding goal"
703         print *,"relative economic value of ",xtraits(i)," ?"
            print *," "
            read *,tempev(i,1)
            write(unit=10, fmt=14002) tempev(i,1),xtraits(i)
            if (tempev(i,1).eq.0) then
              print *,"economic value of 0 is not allowed"
              goto 703
            end if
            counth=counth+1
          else if (sdesttraits(i).eq."b") then
            print *," "
	    print *,xtraits(i)," used in breeding goal and index"
707         print *,"relative economic value of ",xtraits(i)," ?"
            print *," "
            read *,tempev(i,1)
            write(unit=10, fmt=14002) tempev(i,1),xtraits(i)
            if (tempev(i,1).eq.0) then
              print *,"economic value of 0 is not allowed"
              goto 707
            end if
            countb=countb+1
          else
            print *,"wrong input!"
            goto 700
          end if
        end do
        totalh=counth+countb

14000   format(2x,a8," ! name of trait",i3)
14001   format(a10," ! use of ",a8)
14002   format(f10.3," ! economic value ",a8)

        end subroutine traitinfo

!=====================================================
        subroutine traitinfoovlp

        use selparameters

        implicit none

	! get trait info and destination
        counth=0
        countb=0
        print *,"trait information"

	do i=1,ntraits
	  print *,"name of trait ",i," ? (max 8 characters)"
          print *," "
	  read *,xtraits(i)
          write(unit=10, fmt=14000) xtraits(i),i
700       if (ntraits.eq.1) then
            desttraits(1)="b"
            goto 702
          else
	    print *,"use ",xtraits(i),": in the index (i),"
	    print *,"              in the breeding goal (h),"
	    print *,"              in the index AND breeding goal (b),"
	    print *,"              or not at this moment (n) ?"
          end if
          print *," "
          read *,desttraits(i)
          write(unit=10, fmt=14001) desttraits(i),xtraits(i)
702       if (desttraits(i).eq."n") then
            print *," "
            print *,xtraits(i)," not used"
          else if (desttraits(i).eq."i") then
            print *," "
	    print *,xtraits(i)," used in index"
          else if (desttraits(i).eq."h") then
            print *," "
	    print *,xtraits(i)," used in breeding goal"
703         print *,"relative economic value of ",xtraits(i)," ?"
            print *," "
            read *,tempev(i,1)
            write(unit=10, fmt=14002) tempev(i,1),xtraits(i)
            if (tempev(i,1).eq.0) then
              print *,"economic value of 0 is not allowed"
              goto 703
            end if
            counth=counth+1
          else if (desttraits(i).eq."b") then
            print *," "
	    print *,xtraits(i)," used in breeding goal and index"
707         print *,"relative economic value of ",xtraits(i)," ?"
            print *," "
            read *,tempev(i,1)
            write(unit=10, fmt=14002) tempev(i,1),xtraits(i)
            if (tempev(i,1).eq.0) then
              print *,"economic value of 0 is not allowed"
              goto 707
            end if
            countb=countb+1
          else
            print *,"wrong input!"
            goto 700
          end if
        end do
        totalh=counth+countb

14000   format(2x,a8," ! name of trait",i3)
14001   format(a10," ! use of ",a8)
14002   format(f10.3," ! economic value ",a8)

        end subroutine traitinfoovlp

!=====================================================

        subroutine traitinfo2
        use selparameters

        implicit none

	! get trait info and destination
        if (nstag.eq.1) then
          print *,"trait information for the dams for stage 1"
        else
          print *,"trait information for the dams"
        end if
        print *," "
	do i=1,ntraits
          if (ntraits.eq.1) then
            ddesttraits(1)="i"
            goto 712
          end if
710       print *,"use ",xtraits(i),": in the index (i),"
	  print *,"              or not at this moment (n) ?"
          print *," "
          read *,ddesttraits(i)
712       write(unit=10, fmt=15000) ddesttraits(i),xtraits(i)
          if (ddesttraits(i).eq."n" .and. sdesttraits(i).eq."n" .or. &
            & ddesttraits(i).eq."n" .and. sdesttraits(i).eq."i") then
            print *," "
            print *,xtraits(i)," not used"
          else if (ddesttraits(i).eq."n" .and. sdesttraits(i).eq."h" .or. &
            & ddesttraits(i).eq."n" .and. sdesttraits(i).eq."b") then
            ddesttraits(i)="h"
            print *," "
	    print *,xtraits(i)," used in breeding goal"
          else if (ddesttraits(i).eq."i" .and. sdesttraits(i).eq."n" .or. &
            & ddesttraits(i).eq."i" .and. sdesttraits(i).eq."i") then
            print *," "
	    print *,xtraits(i)," used in index"
          else if (ddesttraits(i).eq."i" .and. sdesttraits(i).eq."h" .or. &
            & ddesttraits(i).eq."i" .and. sdesttraits(i).eq."b") then
            ddesttraits(i)="b"
            print *," "
	    print *,xtraits(i)," used in breeding goal and index"
          else
            print *,"wrong input!"
            goto 710
          end if
        end do

15000   format(a10," ! use of ",a8,"for dams")

        end subroutine traitinfo2


!=====================================================

        subroutine traitinfo3

        use selparameters

        implicit none

	! get trait info and destination
	do i=1,ntraits
          if (sdesttraits(i).eq."n" .or. sdesttraits(i).eq."h") then
            if (indexdiff.eq."y") then
              print *,"trait information for the sires for stage 2"
              print *,"  "
              goto 15
            else
              print *,"trait information for stage 2"
              print *," "
              goto 15
            end if
          end if
        end do

15	do i=1,ntraits
          if (sdesttraits(i).eq."n" .or. sdesttraits(i).eq."h") then
            print *," use ",xtraits(i),": in the index (i),"
            print *,"               or not at this moment (n) ?"
            print *," "
            read *,sdesttraits2(i)
            if (sdesttraits(i).eq."n" .and. sdesttraits2(i).eq."n") then
              write(unit=10, fmt=16002) sdesttraits2(i),xtraits(i)
              print *,xtraits(i)," not used in stage 2"
            else if (sdesttraits(i).eq."n" .and. sdesttraits2(i).eq."i") then
              write(unit=10, fmt=16002) sdesttraits2(i),xtraits(i)
              print *,xtraits(i)," used in the index in stage 2"
            else if (sdesttraits(i).eq."h" .and. sdesttraits2(i).eq."i") then
              write(unit=10, fmt=16002) sdesttraits2(i),xtraits(i)
              sdesttraits2(i)="b"
              print *,xtraits(i)," used in breeding goal and index in stage 2"
            else if (sdesttraits(i).eq."h" .and. sdesttraits2(i).eq."n") then
              write(unit=10, fmt=16002) sdesttraits2(i),xtraits(i)
              sdesttraits2(i)="h"
              print *,xtraits(i)," used in breeding goal in stage 2"
            else
              continue
            end if
          end if
        end do

16002   format(a10," ! use of ",a8,"in stage 2 for sires")

        end subroutine traitinfo3

!=====================================================

        subroutine traitinfo4
        use selparameters

        implicit none

	! get trait info and destination
	do i=1,ntraits
          if (ddesttraits(i).eq."n" .or. ddesttraits(i).eq."h") then
            print *,"trait information for the dams for stage 2"
            print *,"  "
            goto 15
          end if
        end do
15	do i=1,ntraits
          if (ddesttraits(i).eq."n" .or. ddesttraits(i).eq."h") then
            print *," use ",xtraits(i),": in the index (i),"
            print *,"               or not at this moment (n) ?"
            print *," "
            read *,ddesttraits2(i)
            if (ddesttraits(i).eq."n" .and. ddesttraits2(i).eq."n") then
              write(unit=10, fmt=17002) ddesttraits2(i),xtraits(i)
              print *,xtraits(i)," not used in stage 2"
            else if (ddesttraits(i).eq."n" .and. ddesttraits2(i).eq."i") then
              write(unit=10, fmt=17002) ddesttraits2(i),xtraits(i)
              print *,xtraits(i)," used in the index in stage 2"
            else if (ddesttraits(i).eq."h" .and. ddesttraits2(i).eq."i") then
              write(unit=10, fmt=17002) ddesttraits2(i),xtraits(i)
              ddesttraits2(i)="b"
              print *,xtraits(i)," used in breeding goal and index in stage 2"
            else if (ddesttraits(i).eq."h" .and. ddesttraits2(i).eq."n") then
              write(unit=10, fmt=17002) ddesttraits2(i),xtraits(i)
              ddesttraits2(i)="h"
              print *,xtraits(i)," used in breeding goal in stage 2"
            else
              continue
            end if
          end if

        end do

17002   format(a10," ! use of ",a8,"in stage 2 for dams")

        end subroutine traitinfo4

!==================================================
        subroutine traitinfo5

        use selparameters

        implicit none

	! get trait info and destination
	do i=1,ntraits
          if (sdesttraits2(i).eq."n" .or. sdesttraits2(i).eq."h") then
            if (indexdiff.eq."y") then
              print *,"trait information for the sires for stage 3"
              print *,"  "
              goto 15
            else
              print *,"trait information for stage 3"
              print *," "
              goto 15
            end if
          end if
        end do

15	do i=1,ntraits
          if (sdesttraits2(i).eq."n" .or. sdesttraits2(i).eq."h") then
            print *," use ",xtraits(i),": in the index (i),"
            print *,"               or not at this moment (n) ?"
            print *," "
            read *,sdesttraits3(i)
            if (sdesttraits2(i).eq."n" .and. sdesttraits3(i).eq."n") then
              write(unit=10, fmt=16002) sdesttraits3(i),xtraits(i)
              print *,xtraits(i)," not used in stage 3"
            else if (sdesttraits2(i).eq."n" .and. sdesttraits3(i).eq."i") then
              write(unit=10, fmt=16002) sdesttraits3(i),xtraits(i)
              print *,xtraits(i)," used in the index in stage 3"
            else if (sdesttraits2(i).eq."h" .and. sdesttraits3(i).eq."i") then
              write(unit=10, fmt=16002) sdesttraits3(i),xtraits(i)
              sdesttraits3(i)="b"
              print *,xtraits(i)," used in breeding goal and index in stage 3"
            else if (sdesttraits2(i).eq."h" .and. sdesttraits3(i).eq."n") then
              write(unit=10, fmt=16002) sdesttraits3(i),xtraits(i)
              sdesttraits3(i)="h"
              print *,xtraits(i)," used in breeding goal in stage 3"
            else
              continue
            end if
          end if
        end do

16002   format(a10," ! use of ",a8,"in stage 3 for sires")

        end subroutine traitinfo5

!=====================================================

        subroutine traitinfo6
        use selparameters

        implicit none

	! get trait info and destination
	do i=1,ntraits
          if (ddesttraits2(i).eq."n" .or. ddesttraits2(i).eq."h") then
            print *,"trait information for the dams for stage 3"
            print *,"  "
            goto 15
          end if
        end do
15	do i=1,ntraits
          if (ddesttraits2(i).eq."n" .or. ddesttraits2(i).eq."h") then
            print *," use ",xtraits(i),": in the index (i),"
            print *,"               or not at this moment (n) ?"
            print *," "
            read *,ddesttraits3(i)
            if (ddesttraits2(i).eq."n" .and. ddesttraits3(i).eq."n") then
              write(unit=10, fmt=17002) ddesttraits3(i),xtraits(i)
              print *,xtraits(i)," not used in stage 3"
            else if (ddesttraits2(i).eq."n" .and. ddesttraits3(i).eq."i") then
              write(unit=10, fmt=17002) ddesttraits3(i),xtraits(i)
              print *,xtraits(i)," used in the index in stage 3"
            else if (ddesttraits2(i).eq."h" .and. ddesttraits3(i).eq."i") then
              write(unit=10, fmt=17002) ddesttraits3(i),xtraits(i)
              ddesttraits3(i)="b"
              print *,xtraits(i)," used in breeding goal and index in stage 3"
            else if (ddesttraits2(i).eq."h" .and. ddesttraits3(i).eq."n") then
              write(unit=10, fmt=17002) ddesttraits3(i),xtraits(i)
              ddesttraits3(i)="h"
              print *,xtraits(i)," used in breeding goal in stage 3"
            else
              continue
            end if
          end if

        end do

17002   format(a10," ! use of ",a8,"in stage 3 for dams")

        end subroutine traitinfo6

!==================================================

        subroutine selection_index(locntraits,sigmai,sigmah,covp,covas,covad,covaw,covc, &
          & cove,covapaq,covapi,sumits,locdesttraits,locits,loctempsource,locresponse, &
          & loctotalresponse,locrih,realg,locb,locinvp,loctotalh,locinitindsel, &
          & locev,loctempev,fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd, &
          & hsgroupsdams,proggroupsdams,covcprog,pval,nsires,neffdams,noff,corrfs,corrhs)


        use seltools


        implicit none

        integer :: sumits,locntraits,i,j,k,l,m,n,p,q,loctotalh
        integer, dimension(locntraits) :: locits
        integer, dimension(locntraits,84) :: loctempsource
        real, dimension(20) :: fsgroupsoff,hsgroupsoff,proggroupsoffs,hsgroupsdams, &
          & proggroupsdams,proggroupsoffd

        real :: sigmai,sigmah,loctotalresponse,locrih,noff,neffdams,progoff,progeffdams
        real :: ii,corrfs,corrhs,corravg,nsires,pval
	real, dimension(locntraits) :: covapi,locresponse
        real, dimension(locntraits,locntraits) :: covapaq,covp,covas,covad, &
           & covaw,covc,cove,covcprog,fs,hs,s,d
        real*8, dimension(sumits,sumits) :: locduminvp
        real, dimension(sumits,sumits) :: realp,realrfs,realrhs,locinvp
        real, dimension(sumits,1) :: locb,tempcorr1
        real, dimension(1,sumits) :: loctb,temp1sigmai
        real, dimension(1,1) :: temp2sigmai,temp2sigmah,tempcorr2,tempcov3
        real, dimension(1,loctotalh) :: temp1sigmah
        real, dimension(loctotalh,1) :: locev
        real, dimension(locntraits,1) :: loctempev
        real, dimension(sumits,locntraits) :: realg,loctempb
        real, dimension(loctotalh,loctotalh) :: realc
        real, dimension(locntraits,locntraits,83,83) :: matp,matrfs,matrhs
        real, dimension(locntraits,locntraits,83,1) :: matg
        real, dimension(locntraits,locntraits,1,1) :: matc
        real, dimension(sumits,1) :: partrealg
        real :: dum1,dum2

	character(len=1) :: locinitindsel
        character(len=1), dimension(locntraits) :: locdesttraits




        ! setup of maximum p-matrix
        do p=1,locntraits
          do q=1,locntraits
	    ! own performance + blup
            matp(p,q,1,1)=covp(p,q)
            matp(p,q,1,2)=d(p,q)/2
            matp(p,q,1,3)=s(p,q)/2
            matp(p,q,2,2)=d(p,q)
  	    matp(p,q,2,3)=0.0
  	    matp(p,q,3,3)=s(p,q)
            ! own performance - all groups
            do i=1,20
              matp(p,q,1,i+3)=fs(p,q)
              matp(p,q,1,i+23)=hs(p,q)
              matp(p,q,1,i+43)=0.0
              matp(p,q,1,i+63)=0.5*covapaq(p,q)
            end do
            ! ebv dam -  all groups
            do i=1,20
              matp(p,q,2,i+3)=d(p,q)/2
              matp(p,q,2,i+23)=0.0
              matp(p,q,2,i+43)=0.0
              matp(p,q,2,i+63)=d(p,q)/4
            end do
            ! ebv sire - all groups
            do i=1,20
              matp(p,q,3,i+3)=s(p,q)/2
              matp(p,q,3,i+23)=s(p,q)/2
              matp(p,q,3,i+43)=0.0
              matp(p,q,3,i+63)=s(p,q)/4
            end do
            ! full-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matp(p,q,i+3,j+3)=covas(p,q)+covad(p,q)+covc(p,q)+ &
                    & (covaw(p,q)/fsgroupsoff(i))+(cove(p,q)/fsgroupsoff(i))
                else
                  matp(p,q,i+3,j+3)=fs(p,q)
                end if
              end do
            end do
            ! full-sib groups - half-sib groups
            do i=1,20
              do j=1,20
                matp(p,q,i+3,j+23)=hs(p,q)
              end do
            end do
            ! full-sib groups - mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                matp(p,q,i+3,j+43)=0.0
              end do
            end do
            ! full-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matp(p,q,i+3,j+63)=(0.5*covas(p,q))+(0.5*covad(p,q))
              end do
            end do
            ! half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matp(p,q,i+23,j+23)=covas(p,q)+(covad(p,q)/hsgroupsdams(i))+ &
                    & (covc(p,q)/hsgroupsdams(i))+(covaw(p,q)/hsgroupsoff(i))+ &
                    & (cove(p,q)/hsgroupsoff(i))
                else
                  matp(p,q,i+23,j+23)=hs(p,q)
                end if
              end do
            end do
            ! half-sib groups - mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matp(p,q,i+23,j+43)=(0.5*d(p,q))/hsgroupsdams(i)
                else
                  matp(p,q,i+23,j+43)=0.0
                end if
              end do
            end do
            ! half-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matp(p,q,i+23,j+63)=0.5*hs(p,q)
              end do
            end do
            ! mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matp(p,q,i+43,j+43)=d(p,q)/hsgroupsdams(i)
                else
                  matp(p,q,i+43,j+43)=0.0
                end if
              end do
            end do
            ! mean ebv of the dams of half-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matp(p,q,i+43,j+63)=0.0
              end do
            end do
            ! progeny groups
            do i=1,20
              do j=1,20
                if (locinitindsel.eq."s") then  ! individual=male
                  if (i.eq.j) then
                    matp(p,q,i+63,j+63)=(0.25*covapaq(p,q))+ &
                      & ((0.25*covapaq(p,q))/proggroupsdams(i))+ &
                      & (covcprog(p,q)/proggroupsdams(i))+(covaw(p,q)/proggroupsoffs(i))+ &
                      & (cove(p,q)/proggroupsoffs(i))
                  else
                    matp(p,q,i+63,j+63)=0.25*covapaq(p,q)
                  end if
                else  ! individual=female
                  if (i.eq.j) then
                    matp(p,q,i+63,j+63)=(0.5*covapaq(p,q))+ &
                      & covcprog(p,q)+(covaw(p,q)/proggroupsoffd(i))+ &
                      & (cove(p,q)/proggroupsoffd(i))
                  else
                    matp(p,q,i+63,j+63)=0.5*covapaq(p,q)
                  end if
                end if
              end do
            end do
            ! symetric elements
            do i=1,83
              do j=1,83
         !     print *,"matrix p",p,q,i,j,matp(p,q,i,j)
                if (j.gt.i) then
                  matp(p,q,j,i)=matp(p,q,i,j)
                end if
              end do
            end do
          end do
        end do
!        print *,"p-max",matp

       !	print *,"max p is goed"

	! setup of maximum g-matrix
        do p=1,locntraits
	  do q=1,locntraits
            matg(p,q,1,1)=covapaq(p,q)
            matg(p,q,2,1)=d(q,p)/2
            matg(p,q,3,1)=s(q,p)/2
     !       print *,"d/2",d(q,p)/2
      !      print *,"s/2",s(q,p)/2
            ! full-sib groups
            do i=1,20
              matg(p,q,i+3,1)=covas(p,q)+covad(p,q)
            end do
            ! half-sib groups
            do i=1,20
              matg(p,q,i+23,1)=covas(p,q)
            end do
            ! mean ebv dams of half-sib groups
            do i=1,20
              matg(p,q,i+43,1)=0.0
            end do
            ! progeny groups
            do i=1,20
              matg(p,q,i+63,1)=0.5*covapaq(p,q)
            end do
          end do
	end do
      !  print *,"max g is goed"

        ! setup of maximum c-matrix
        do p=1,locntraits
          do q=1,locntraits
            matc(p,q,1,1)=covapaq(p,q)
          end do
        end do
      !  print *,"max c is goed"
       !	print *,"covapaq",covapaq

	! setup of real p-matrix
        m=0
        n=0
        do i=1,locntraits
          if (locdesttraits(i).eq."i" .or. locdesttraits(i).eq."b") then
            do j=1,locntraits
              if (locdesttraits(j).eq."i" .or. locdesttraits(j).eq."b") then
                do k=1,locits(i)-1
                  do l=1,locits(j)-1
                    realp(k+m,l+n)=matp(i,j,loctempsource(i,k),loctempsource(j,l))
      !	            print *,"realp (",k+m,",",l+n,")=",realp(k+m,l+n)!,";","org", &
                     ! & i,j,loctempsource(i,k),loctempsource(j,l)

                  end do
                end do
                n=n+locits(j)-1
              end if
            end do
            m=m+locits(i)-1
            n=0
          end if
        end do
       ! print *," "
    !  	print *,"p matrix",realp

        ! setup of real g-matrix
        ! all traits are in g (even non breeding goal traits)
        m=0
        n=0
	l=1
        do i=1,locntraits
          if (locdesttraits(i).eq."i" .or. locdesttraits(i).eq."b") then
            do j=1,locntraits
                do k=1,locits(i)-1
                  realg(k+m,l+n)=matg(i,j,loctempsource(i,k),1)
              !    print *,"realg (",k+m,",",l+n,")=",realg(k+m,l+n)
	        end do
                n=n+1
            end do
            m=m+locits(i)-1
            n=0
          end if
        end do
     ! 	print *,"g matrix",realg
    !    print *," "

      !  print *,"real g is goed"

        ! setup of real c-matrix
        m=1
        n=0
        l=1
	k=0
        do i=1,locntraits
          if (locdesttraits(i).eq."h" .or. locdesttraits(i).eq."b") then
            do j=1,locntraits
              if (locdesttraits(j).eq."h" .or. locdesttraits(j).eq."b") then
                realc(k+m,l+n)=matc(i,j,1,1)
  !                print *,"realc (",k+m,",",l+n,")=",realc(k+m,l+n)
                n=n+1
	      end if
            end do  
            m=m+1
            n=0
	  end if
        end do
      !  print *,"real c is goed"
     !   print *," "

        ! storing real p-matrix
          do j=1,sumits
            do k=1,sumits
              locinvp(j,k)=realp(j,k)
            end do
          end do
      !  print *,"voor matrix calc is goed"
        do j=1,sumits
          do k=1,sumits
            locduminvp(j,k)=locinvp(j,k)
          end do
        end do

        ! matrix calculations
        call invrt(locduminvp,sumits,sumits)
        ! covert invp back to normal real
        do j=1,sumits
          do k=1,sumits
            locinvp(j,k)=locduminvp(j,k)
          end do
        end do

!        print *," inverse p",locinvp

       ! print *,"1e matmul"
        loctempb=matmul(locinvp,realg) ! 5x5 5x2 = 5x2
      !  print *,"2e matmul"
	locb=matmul(loctempb,loctempev) ! 5x2 2x1 = 5x1
     !   PRINT *,"b ",locb
        loctb=transpose(locb) ! 5x1 naar 1x5
       ! print *,"3e matmul"
        temp1sigmai=matmul(loctb,realp) ! 1x5 5x5 = 1x5
     !   print *,"4e matmul"
        temp2sigmai=matmul(temp1sigmai,locb) ! 1x5 5x1 = 1x1
        sigmai=temp2sigmai(1,1)
    !    print *,"locev",locev
      !  print *,"loctempev",loctempev
       ! print *,"locev",locev
     !   print *,"realc",realc
	temp1sigmah=matmul(transpose(locev),realc)
              !  print *,"6e matmul"
	temp2sigmah=matmul(temp1sigmah,locev)
	sigmah=temp2sigmah(1,1)
     !   print *,temp2sigmah
 !       print *,"sigmai ",sigmai
  !      print *,"sigmah ",sigmah

	locrih=(sqrt(sigmai/sigmah))
   !     print *,"rih",locrih

        ! calculate intra-class correlations
        ! setup of maximum rfs-matrix
        do p=1,locntraits
          do q=1,locntraits
	    ! own performance + blup
            matrfs(p,q,1,1)=fs(p,q)
            matrfs(p,q,1,2)=d(p,q)/2
            matrfs(p,q,1,3)=s(p,q)/2
            matrfs(p,q,2,2)=d(p,q)
  	    matrfs(p,q,2,3)=0.0
  	    matrfs(p,q,3,3)=s(p,q)
            ! own performance - all groups
            do i=1,20
              matrfs(p,q,1,i+3)=fs(p,q)+((covaw(p,q)+cove(p,q))/sum(fsgroupsoff))
              matrfs(p,q,1,i+23)=hs(p,q)
              matrfs(p,q,1,i+43)=0.0
              matrfs(p,q,1,i+63)=(0.5*covas(p,q))+(0.5*covad(p,q))
            end do
            ! ebv dam -  all groups
            do i=1,20
              matrfs(p,q,2,i+3)=d(p,q)/2
              matrfs(p,q,2,i+23)=0.0
              matrfs(p,q,2,i+43)=0.0
              matrfs(p,q,2,i+63)=d(p,q)/4
            end do
            ! ebv sire - all groups
            do i=1,20
              matrfs(p,q,3,i+3)=s(p,q)/2
              matrfs(p,q,3,i+23)=s(p,q)/2
              matrfs(p,q,3,i+43)=0.0
              matrfs(p,q,3,i+63)=s(p,q)/4
            end do
            ! full-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrfs(p,q,i+3,j+3)=covas(p,q)+covad(p,q)+covc(p,q)+ &
                    & (((covaw(p,q)+cove(p,q))*(fsgroupsoff(i)-(fsgroupsoff(i)/sum(fsgroupsoff))))/(fsgroupsoff(i)**2))
                else
                  matrfs(p,q,i+3,j+3)=fs(p,q)
                end if
              end do
            end do
            ! full-sib groups - half-sib groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+3,j+23)=covas(p,q)
              end do
            end do
            ! full-sib groups - mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+3,j+43)=0.0
              end do
            end do
            ! full-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+3,j+63)=(0.5*covas(p,q))+(0.5*covad(p,q))+ &
                  & (0.5*covaw(p,q)/sum(fsgroupsoff))
              end do
            end do
            ! half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrfs(p,q,i+23,j+23)=covas(p,q)+(covad(p,q)/hsgroupsdams(i))+ &
                    & (covc(p,q)/hsgroupsdams(i))+(covaw(p,q)/hsgroupsoff(i))+ &
                    & (cove(p,q)/hsgroupsoff(i))
                else
                  matrfs(p,q,i+23,j+23)=covas(p,q)
                end if
              end do
            end do
            ! half-sib groups - mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrfs(p,q,i+23,j+43)=(0.5*d(p,q))/hsgroupsdams(i)
                else
                  matrfs(p,q,i+23,j+43)=0.0
                end if
              end do
            end do
            ! half-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+23,j+63)=0.5*covas(p,q)
              end do
            end do
            ! mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrfs(p,q,i+43,j+43)=d(p,q)/hsgroupsdams(i)
                else
                  matrfs(p,q,i+43,j+43)=0.0
                end if
              end do
            end do
            ! mean ebv of the dams of half-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+43,j+63)=0.0
              end do
            end do
            ! progeny groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+63,j+63)=0.5*((0.5*covas(p,q))+(0.5*covad(p,q)))
              end do
            end do
            ! symetric elements
            do i=1,83
              do j=1,83
                if (j.gt.i) then
                  matrfs(p,q,j,i)=matrfs(p,q,i,j)
                end if
              end do
            end do
          end do
        end do

	! setup of real rfs-matrix
        m=0
        n=0
        do i=1,locntraits
          if (locdesttraits(i).eq."i" .or. locdesttraits(i).eq."b") then
            do j=1,locntraits
              if (locdesttraits(j).eq."i" .or. locdesttraits(j).eq."b") then
                do k=1,locits(i)-1
                  do l=1,locits(j)-1
                    realrfs(k+m,l+n)=matrfs(i,j,loctempsource(i,k),loctempsource(j,l))
      !              print *,"realrfs (",k+m,",",l+n,")=",realrfs(k+m,l+n),";"
        	  end do
                end do
                n=n+locits(j)-1
              end if
            end do
            m=m+locits(i)-1
            n=0
          end if
        end do
     !	print *,"real rfs is goed"

       ! calculate correlation
       tempcorr1=matmul(realrfs,locb)
       tempcorr2=matmul(loctb,tempcorr1)
       corrfs=tempcorr2(1,1)/sigmai

        ! setup of maximum rhs-matrix
        do p=1,locntraits
          do q=1,locntraits
	    ! own performance + blup
            matrhs(p,q,1,1)=hs(p,q)
            matrhs(p,q,1,2)=0.0
            matrhs(p,q,1,3)=s(p,q)/2
            matrhs(p,q,2,2)=0.0
  	    matrhs(p,q,2,3)=0.0
  	    matrhs(p,q,3,3)=s(p,q)
            ! own performance - all groups
            do i=1,20
              matrhs(p,q,1,i+3)=hs(p,q)
              matrhs(p,q,1,i+23)=covas(p,q)+(covad(p,q)/sum(hsgroupsdams))+ &
                & ((covaw(p,q)+cove(p,q))/sum(hsgroupsoff))
              matrhs(p,q,1,i+43)=(0.5*d(p,q))/sum(hsgroupsdams)
              matrhs(p,q,1,i+63)=0.5*hs(p,q)
            end do
            ! ebv dam -  all groups
            do i=1,20
              matrhs(p,q,2,i+3)=0.0
              matrhs(p,q,2,i+23)=(0.5*d(p,q))/sum(hsgroupsdams)
              matrhs(p,q,2,i+43)=d(p,q)/sum(hsgroupsdams)
              matrhs(p,q,2,i+63)=0.0
            end do
            ! ebv sire - all groups
            do i=1,20
              matrhs(p,q,3,i+3)=s(p,q)/2
              matrhs(p,q,3,i+23)=s(p,q)/2
              matrhs(p,q,3,i+43)=0.0
              matrhs(p,q,3,i+63)=s(p,q)/4
            end do
            ! full-sib groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+3,j+3)=hs(p,q)
              end do
            end do
            ! full-sib groups - half-sib groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+3,j+23)=covas(p,q)+(covad(p,q)/sum(hsgroupsdams))+ &
                  & ((covaw(p,q)+cove(p,q))/sum(hsgroupsoff))
              end do
            end do
            ! full-sib groups - mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+3,j+43)=(0.5*d(p,q))/sum(hsgroupsdams)
              end do
            end do
            ! full-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+3,j+63)=0.5*hs(p,q)
              end do
            end do
            ! half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrhs(p,q,i+23,j+23)=covas(p,q)+ &
                    & (covad(p,q)*((sum(hsgroupsdams)-(hsgroupsoff(i)/sum(hsgroupsoff)))/(sum(hsgroupsdams))**2))+ &
                    & ((covaw(p,q)+cove(p,q))*(sum(hsgroupsdams)-(hsgroupsoff(i)/sum(hsgroupsoff)))/(sum(hsgroupsdams)*sum(hsgroupsoff)))
	        else
                  matrhs(p,q,i+23,j+23)=hs(p,q)
                end if
              end do
            end do
            ! half-sib groups - mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrhs(p,q,i+23,j+43)=0.5*d(p,q)*((hsgroupsdams(i)-1)/(hsgroupsdams(i)**2))
                else
                  matrhs(p,q,i+23,j+43)=0.0
                end if
              end do
            end do
            ! half-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+23,j+63)=(0.5*covas(p,q))+(0.5*covad(p,q)/sum(hsgroupsdams))+ &
                  & (0.5*covaw(p,q)/sum(hsgroupsoff))
              end do
            end do
            ! mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrhs(p,q,i+43,j+43)=d(p,q)*((hsgroupsdams(i)-1)/(hsgroupsdams(i)**2))
                else
                  matrhs(p,q,i+43,j+43)=0.0
                end if
              end do
            end do
            ! mean ebv of the dams of half-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+43,j+63)=(0.25*d(p,q))/(sum(hsgroupsdams))
              end do
            end do
            ! progeny groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+63,j+63)=0.25*hs(p,q)
              end do
            end do
            ! symetric elements
            do i=1,83
              do j=1,83
                if (j.gt.i) then
                  matrhs(p,q,j,i)=matrhs(p,q,i,j)
                end if
              end do
            end do
          end do
        end do

	! setup of real rhs-matrix
        m=0
        n=0
        do i=1,locntraits
          if (locdesttraits(i).eq."i" .or. locdesttraits(i).eq."b") then
            do j=1,locntraits
              if (locdesttraits(j).eq."i" .or. locdesttraits(j).eq."b") then
                do k=1,locits(i)-1
                  do l=1,locits(j)-1
                    realrhs(k+m,l+n)=matrhs(i,j,loctempsource(i,k),loctempsource(j,l))
      !	if (locinitindsel.eq."d") then
      !	print *,"realrhs (",k+m,",",l+n,")=",realrhs(k+m,l+n),";"
       !	end if
        	  end do
                end do
                n=n+locits(j)-1
              end if
            end do
            m=m+locits(i)-1
            n=0
          end if
        end do
       !	print *,"real rhs is goed"

       ! calculate correlation
       tempcorr1=matmul(realrhs,locb)
       tempcorr2=matmul(loctb,tempcorr1)
       corrhs=tempcorr2(1,1)/sigmai

 !      print *,"corrfs",corrfs
  !     print *,"corrhs",corrhs
    !   if (nsires.eq.ndams) then ! mating ratio = 1
    !     corrfs=1
    !     corrhs=1
    !   end if

    !   corravg=(((noff-1)*corrfs)+(noff*(neffdams-1)*corrhs))/(nsires*neffdams*noff)-1


     !   call trunc(pval,dum1,dum2,ii,ks)
        if (corrfs.lt.-1.0) then
	  corrfs=-1.0
        end if
        if (corrfs.gt.1.0) then
	  corrfs=1.0
        end if

        if (corrhs.lt.-1.0) then
	  corrhs=-1.0
        end if
        if (corrhs.gt.1.0) then
	  corrhs=1.0
        end if

        ii=rawl3(pval,noff,neffdams,nsires,corrfs,corrhs)

        ! (co-)variance update for single subscript cov's
        do q=1,locntraits
          do j=1,sumits
            partrealg(j,1)=realg(j,q)
          end do
          tempcov3=matmul(transpose(locb),partrealg) ! 1x5 5x1 = 1x1
          covapi(q)=tempcov3(1,1)
        end do

        ! calculate response per trait per generation
        do j=1,locntraits
          locresponse(j)=(ii*covapi(j))/(sqrt(sigmai))
        end do

        ! calculate total response per generation
     !   print *,"derde sqrt"
        loctotalresponse=ii*(sqrt(sigmai))
 !       print *,"local totalresponse",loctotalresponse

      !	do p=1,sumits
       !	  do q=1,sumits
	!    print *,"locinvp (",p,",",q,")=",locinvp(p,q),";"
	!  end do
      !	end do

        end subroutine selection_index

!==============================================

        subroutine covariance_update(locntraits,ssigmai,dsigmai,covp,covas,covad, &
          & covaw,covc,cove,covapaq,ssumits,sits,sresponse,stotalresponse,srealg,sb, &
          & sinvp,dsumits,dits,dresponse,dtotalresponse,drealg,db,dinvp,ks,kd,response, &
          & totalresponse,tempev,scovapi,dcovapi,fs,hs,s,d)


        implicit none

        integer :: locntraits,j,n,ni,p,q,ssumits,dsumits
        integer, dimension(84) :: sits,dits

        real :: ssigmai,stotalresponse,totalresponse
        real :: ks,kd,neffdams,noff
	real, dimension(locntraits) :: scovapi,scovipi,sresponse,response
        real, dimension(locntraits,locntraits) :: scovapiq,covapaq,covp,covas,covad, &
           & covaw,covc,cove,s,d,fs,hs
        real, dimension(ssumits,ssumits) :: sinvp
        real, dimension(ssumits,1) :: sb,spartrealg,stempcov1,stempcov2
        real, dimension(1,1) :: tempcov3,tempcov4
        real, dimension(locntraits,1) :: tempev
        real, dimension(ssumits,locntraits) :: srealg

        real :: dsigmai,dtotalresponse
	real, dimension(locntraits) :: dcovapi,dcovipi,dresponse
        real, dimension(locntraits,locntraits) :: dcovapiq
        real, dimension(dsumits,dsumits) :: dinvp
        real, dimension(dsumits,1) :: db,dpartrealg,dtempcov1,dtempcov2
        real, dimension(dsumits,locntraits) :: drealg

        ! calculate response per trait per generation through two paths
        do j=1,locntraits
          response(j)=(sresponse(j)+dresponse(j))/2
        end do

        ! calculate totalresponse per generation through two paths
        totalresponse=(stotalresponse+dtotalresponse)/2

        ! (co-)variance update for single subscript cov's sires
        do q=1,locntraits
          do j=1,ssumits
            spartrealg(j,1)=srealg(j,q)
          end do
          tempcov3=matmul(transpose(sb),spartrealg) ! 1x5 5x1 = 1x1
          scovapi(q)=tempcov3(1,1)
          stempcov1=matmul(sinvp,spartrealg) ! 5x5 5x1 = 5x1
          stempcov2=matmul(srealg,tempev) ! 5x2 2x1 = 5x1
          tempcov4=matmul(transpose(stempcov1),stempcov2) ! 1x5 5x1 = 1x1
          scovipi(q)=tempcov4(1,1)
        end do

        ! (co-)variance update for double subscript cov's for sires
        ni=1
        do p=1,locntraits
            do q=1,locntraits
                if (p.eq.q) then
                  do j=1,ssumits
                    spartrealg(j,1)=srealg(j,ni)
                  end do
                  stempcov1=matmul(sinvp,spartrealg) ! 5x5 5x1 = 5x1
                  tempcov3=matmul(transpose(stempcov1),spartrealg) ! 1x5 5x1 = 1x1
                  scovapiq(p,q)=tempcov3(1,1)
                  n=ni+1
                else if (p.lt.q) then
                  do j=1,ssumits
                    spartrealg(j,1)=srealg(j,n)
                  end do
                  tempcov3=matmul(transpose(stempcov1),spartrealg) ! 1x5 5x1 = 1x1
                  scovapiq(p,q)=tempcov3(1,1)
                  n=n+1
                else
                  continue
                end if
            end do
            ni=ni+1
        end do

        ! fill in symetric elements of double subscript covariances
        do p=1,locntraits
          do q=1,locntraits
	    if (p.lt.q) then
              scovapiq(q,p)=scovapiq(p,q)
	    end if
          end do
        end do

  !      print *,"scovapiq",scovapiq
  !      print *,"scovapi   ",scovapi
   !     print *,"scovipi   ",scovipi

        ! update covariances
        do p=1,locntraits
          do q=1,locntraits
            s(p,q)=scovapiq(p,q)-((scovapi(p)*scovipi(q)*ks)/ssigmai)
            covas(p,q)=0.25*(covapaq(p,q)-((scovapi(p)*scovapi(q)*ks)/ssigmai))
          end do
        end do

    !    print *,"s",s
     !   print *,"covas",covas

        ! (co-)variance update for single subscript cov's dams
        do q=1,locntraits
          do j=1,dsumits
            dpartrealg(j,1)=drealg(j,q)
          end do
          tempcov3=matmul(transpose(db),dpartrealg) ! 1x5 5x5 = 1x1
          dcovapi(q)=tempcov3(1,1)
          dtempcov1=matmul(dinvp,dpartrealg) ! 5x5 5x1 = 5x1
          dtempcov2=matmul(drealg,tempev) ! 5x1 1x1 = 5x1
          tempcov4=matmul(transpose(dtempcov1),dtempcov2) ! 1x5 5x1 = 1x1
          dcovipi(q)=tempcov4(1,1)
        end do

        ! (co-)variance update for double subscript cov's for dams
        ni=1
        do p=1,locntraits
            do q=1,locntraits
                if (p.eq.q) then
                  do j=1,dsumits
                    dpartrealg(j,1)=drealg(j,ni)
                  end do
                  dtempcov1=matmul(dinvp,dpartrealg) ! 5x5 5x1 = 5x1
                  tempcov3=matmul(transpose(dtempcov1),dpartrealg) ! 1x5 5x1 = 1x1
                  dcovapiq(p,q)=tempcov3(1,1)
                  n=ni+1
                else if (p.lt.q) then
                  do j=1,dsumits
                    dpartrealg(j,1)=drealg(j,n)
                  end do
                  tempcov3=matmul(transpose(dtempcov1),dpartrealg) ! 1x5 5x1 = 1x1
                  dcovapiq(p,q)=tempcov3(1,1)
                  n=n+1
                else
                  continue
                end if
            end do
            ni=ni+1
        end do

        ! fill in symetric elements
        do p=1,locntraits
          do q=1,locntraits
	    if (p.lt.q) then
              dcovapiq(q,p)=dcovapiq(p,q)
	    end if
          end do
        end do

 !       print *,"dcovapiq",dcovapiq
  !      print *,"dcovapi   ",dcovapi
   !     print *,"dcovipi   ",dcovipi

        ! update some more (co-)variances
        do p=1,locntraits
          do q=1,locntraits
            d(p,q)=dcovapiq(p,q)-((dcovapi(p)*dcovipi(q)*kd)/dsigmai)
            covad(p,q)=0.25*(covapaq(p,q)-((dcovapi(p)*dcovapi(q)*kd)/dsigmai))
          end do
        end do

    !    print *,"d",d
     !   print *,"covad",covad

        ! some more updates
        do p=1,locntraits
          do q=1,locntraits
            fs(p,q)=covas(p,q)+covad(p,q)+covc(p,q)
            hs(p,q)=covas(p,q)
            covapaq(p,q)=covas(p,q)+covad(p,q)+covaw(p,q)
            covp(p,q)=covapaq(p,q)+covc(p,q)+cove(p,q)
          end do
        end do

!        print *,"fs",fs
 !       print *,"hs",hs
  !      print *,"dcovapaq   ",dcovapaq
   !     print *,"covp   ",covp

        end subroutine covariance_update

!==============================================

        subroutine ovlp_cov_update(locntraits,ssigmai,covp,covas, &
          & covaw,covc,cove,covapaq,sumits,sits,srealg,sb, &
          & sinvp,ks,tempev,scovapi,fs,hs,s)


        implicit none

        integer :: locntraits,j,n,ni,p,q,sumits
        integer, dimension(84) :: sits

        real :: ssigmai,ks
	real, dimension(locntraits) :: scovapi,scovipi
        real, dimension(locntraits,locntraits) :: scovapiq,covapaq,covp,covas, &
           & covaw,covc,cove,s,fs,hs
        real, dimension(sumits,sumits) :: sinvp
        real, dimension(sumits,1) :: sb,spartrealg,stempcov1,stempcov2
        real, dimension(1,1) :: tempcov3,tempcov4
        real, dimension(locntraits,1) :: tempev
        real, dimension(sumits,locntraits) :: srealg

        ! (co-)variance update for single subscript cov's
        do q=1,locntraits
          do j=1,sumits
            spartrealg(j,1)=srealg(j,q)
          end do
          tempcov3=matmul(transpose(sb),spartrealg) ! 1x5 5x1 = 1x1
          scovapi(q)=tempcov3(1,1)
          stempcov1=matmul(sinvp,spartrealg) ! 5x5 5x1 = 5x1
          stempcov2=matmul(srealg,tempev) ! 5x2 2x1 = 5x1
          tempcov4=matmul(transpose(stempcov1),stempcov2) ! 1x5 5x1 = 1x1
          scovipi(q)=tempcov4(1,1)
        end do

        ! (co-)variance update for double subscript cov's
        ni=1
        do p=1,locntraits
            do q=1,locntraits
                if (p.eq.q) then
                  do j=1,sumits
                    spartrealg(j,1)=srealg(j,ni)
                  end do
                  stempcov1=matmul(sinvp,spartrealg) ! 5x5 5x1 = 5x1
                  tempcov3=matmul(transpose(stempcov1),spartrealg) ! 1x5 5x1 = 1x1
                  scovapiq(p,q)=tempcov3(1,1)
                  n=ni+1
                else if (p.lt.q) then
                  do j=1,sumits
                    spartrealg(j,1)=srealg(j,n)
                  end do
                  tempcov3=matmul(transpose(stempcov1),spartrealg) ! 1x5 5x1 = 1x1
                  scovapiq(p,q)=tempcov3(1,1)
                  n=n+1
                else
                  continue
                end if
            end do
            ni=ni+1
        end do

        ! fill in symetric elements of double subscript covariances
        do p=1,locntraits
          do q=1,locntraits
	    if (p.lt.q) then
              scovapiq(q,p)=scovapiq(p,q)
	    end if
          end do
        end do

        ! update covariances
        do p=1,locntraits
          do q=1,locntraits
            s(p,q)=scovapiq(p,q)-((scovapi(p)*scovipi(q)*ks)/ssigmai)
      !      print *,"scovapiq(p,q)",scovapiq(p,q)
       !     print *,"scovapi(p)*scovipi(q)",scovapi(p)*scovipi(q)
        !    print *,"ks",ks
         !   print *,"sigmai",ssigmai
            covas(p,q)=0.25*(covapaq(p,q)-((scovapi(p)*scovapi(q)*ks)/ssigmai))
          end do
        end do

        end subroutine ovlp_cov_update

!==============================================

        subroutine covai_update(locntraits,sigmai,sumits,response,totalresponse, &
          & realg,b,pval,noff,neffdams,nsires,corrfs,corrhs,realp)


        implicit none

        integer :: locntraits,j,q,sumits

        real :: sigmai,totalresponse,neffdams,ii,pval,noff,nsires,corrfs,corrhs
	real, dimension(locntraits) :: covapi,response
        real, dimension(sumits,sumits) :: realp
        real, dimension(sumits,1) :: b,partrealg
        real, dimension(1,1) :: tempcov3
        real, dimension(sumits,locntraits) :: realg


        ii=rawl3(pval,noff,neffdams,nsires,corrfs,corrhs)
     !   print *,"ii",ii
        ! calculate response per trait per generation
        do q=1,locntraits
          do j=1,sumits
            partrealg(j,1)=realg(j,q)
          end do
      !    print *,"hierna gaat het fout 1"
          tempcov3=matmul(transpose(b),partrealg) ! 1x5 5x1 = 1x1
          covapi(q)=tempcov3(1,1)
          response(q)=(ii*covapi(q))/(sqrt(sigmai))
        end do
        totalresponse=ii*(sqrt(sigmai))
        end subroutine covai_update

	!==================================================
	real function trunc_delta(x)

        use selparameters
        use seltools

        implicit none

        real :: x,tnumb,tr
        real, dimension(2*nclass) :: tmean

        ! calculate new proportions for truncation selection
        tmean(1)=0.0
        tmean(nclass+1)=0.0
        tnumb=0.0
        if (initindsel.eq."s") then ! sires
          do p=2,nclass
            tmean(p)=tmean(1)-((p-1)*stotalresponse)
          end do
          do p=1,nclass
            if (osigmai(p).gt.0.0) then
     !         print *,"x",x
      !        print *,"tmean(p)",tmean(p)
       !       print *,"sqrt(osigmai(p)",sqrt(osigmai(p))
              dumt=(x-tmean(p))/sqrt(osigmai(p))
              if (dumt.gt.3.0) then
                dumt=3.0
              else if (dumt.lt.-3.0) then
                dumt=-3.0
              end if
        !      print *,"dumt",dumt
              call sdutt1(10,dumt,dumr)
         !     print *,"dumr",dumr
              pvalcl(p)=dumr
          !    print *,"p value class ",p," = ",pvalcl(p)
            else
              pvalcl(p)=0.0
            end if
          end do
          do p=1,nclass
            nselec(p)=pvalcl(p)*nanim(p)
            tnumb=tnumb+nselec(p)
          end do
          sselec=tnumb
          trunc_delta=tnumb-nsires
    !      print *,"trunc_delta",trunc_delta
          ! calculate generation interval
          genints=0
          do p=1,nclass
            tempresponse=((nselec(p)*p)/sselec)
            genints=genints+tempresponse
          end do
        else ! dams
          do p=nclass+2,2*nclass
            tmean(p)=tmean(nclass+1)-((p-nclass-1)*dtotalresponse)
          end do
          do p=nclass+1,2*nclass
            if (osigmai(p).gt.0.0) then
 !           print *,"x",x
  !          print *,"tmean(p)",tmean(p)
   !         print *,"sqrt(osigmai(p)",sqrt(osigmai(p))
            dumt=(x-tmean(p))/sqrt(osigmai(p))
            if (dumt.gt.3.0) then
              dumt=3.0
            else if (dumt.lt.-3.0) then
              dumt=-3.0
            end if
    !        print *,"dumt",dumt
            call sdutt1(10,dumt,dumr)
     !       print *,"dumr",dumr
            pvalcl(p)=dumr
      !      print *,"p value class ",p," = ",pvalcl(p)
            else
              pvalcl(p)=0.0
            end if
          end do
          do p=nclass+1,2*nclass
            nselec(p)=pvalcl(p)*nanim(p)
            tnumb=tnumb+nselec(p)
          end do
          dselec=tnumb
          trunc_delta=tnumb-ndams
  !        print *,"trunc_delta",trunc_delta
          ! calculate generation interval
          genintd=0
          do p=nclass+1,2*nclass
            tempresponse=((nselec(p)*(p-nclass))/dselec)
            genintd=genintd+tempresponse
          end do
        end if

        end function trunc_delta

	!==================================================

	SUBROUTINE riddr_root(trunc_delta,zriddr,xl,xh,tol)
	!
	!  taken from Numerical Recipes 2nd Edition p 352
	!==================================================

      implicit none
      REAL, INTENT(IN) :: tol,xl,xh
      REAL, INTENT(OUT) :: zriddr
      REAL, EXTERNAL :: trunc_delta
      REAL :: a,b,c,d,fa,fb,fc,fd,eps,s
      INTEGER, parameter :: imax=100
      INTEGER :: j
!
      eps=EPSILON(1.0)
   !   print *,"eps",eps
!
      a=xl
      b=xh
      fa=trunc_delta(a)
  !    print *,"fa",fa,"   a",a
      fb=trunc_delta(b)
   !   print *,"fb",fb,"   b",b
      zriddr=b+1.0
      IF(fa*fb<0.0) then
        iterations: do j=1,imax
          c=(a+b)/2.0
          fc=trunc_delta(c)
    !      print *,"fc",fc,"   c",c
          s=SQRT(fc*fc-fa*fb)
          IF(ABS(s)<eps) exit
!
          d=c+(c-a)*SIGN(1.0,fa-fb)*fc/s
          IF(ABS(d-zriddr)<tol) exit
!
          zriddr=d
          fd=trunc_delta(zriddr)
     !     print *,"fd",fd,"   d",d
          IF(ABS(fd)<eps) exit
!
          IF(fc*fd<0.0) then
            a=c
            fa=fc
            b=zriddr
            fb=fd
          else if(fa*fd<0.0) then
            b=zriddr
            fb=fd
          else if(fb*fd<0.0) then
            a=zriddr
            fa=fd
          else
  !          PRINT *, 'never get here in zriddr'
          END if
          IF(ABS(b-a)<tol) exit
 !
        END do iterations
      else IF(ABS(fa)<eps) then
        zriddr=a
      else IF(ABS(fb)<eps) then
        zriddr=b
      else
 !       PRINT *, 'f error'
      END if
  !    PRINT *,'no. of iterations in riddr', j
      END subroutine riddr_root

        !==============================================

        subroutine jacobi(a,n,d)
        !subroutine jacobi(a,n,np,d,v,nrot) in numerical recipes

        ! Computes all eigenvalues and eigenvectors of a real symmetric matrix A, which
        ! is of size N by N, stored in a physical NP by NP array. On output, elements
        ! of A above the diagonal are destroyed. D returns the eigenvalues of A in its
        ! first N elements. V is a matrix with the same logical and physical dimensions
        ! as A, whose columns contain, on input, the normalized eigenvectors of A.
        ! NROT returns the number of Jacobi rotations that were required.
        !
        ! from NUMERICAL RECIPES, programmed by Marc Rutten june 2000.
         
        implicit none

        integer :: n,nrot,nmax
        real :: a(n,n),d(n),v(n,n)
        parameter(nmax=500)
        integer :: i,ip,iq,j
        real :: c,g,h,s,sm,t,tau,theta,tresh,b(nmax),z(nmax)

        do ip=1,n
          do iq=1,n
            v(ip,iq)=0
          end do
          v(ip,ip)=1
        end do
        do ip=1,n
          b(ip)=a(ip,ip)
          d(ip)=b(ip)
          z(ip)=0
        end do
        nrot=0
        do i=1,50
          sm=0
          do ip=1,n-1
            do iq=ip+1,n
              sm=sm+abs(a(ip,iq))
            end do
          end do
          if(sm.eq.0)return
          if(i.lt.4)then
            tresh=0.2*sm/n**2
          else
            tresh=0
          end if
          do ip=1,n-1
            do iq=ip+1,n
              g=100.*abs(a(ip,iq))
              if((i.gt.4).and.(abs(d(ip))+g.eq.abs(d(ip))).and.(abs(d(iq))+g.eq. &
                & abs(d(iq))))then
                a(ip,iq)=0
                else if(abs(a(ip,iq)).gt.tresh)then
                  h=d(iq)-d(ip)
                  if(abs(h)+g.eq.abs(h))then
                  t=a(ip,iq)/h
                else
                  theta=0.5*h/a(ip,iq)
                  t=1./(abs(theta)+sqrt(1.+theta**2))
                  if(theta.lt.0.)t=-t
                end if
                c=1./sqrt(1+t**2)
                s=t*c
                tau=s/(1.+c)
                h=t*a(ip,iq)
                z(ip)=z(ip)-h
                z(iq)=z(iq)+h
                d(ip)=d(ip)-h
                d(iq)=d(iq)+h
                a(ip,iq)=0
                do j=1,ip-1
                  g=a(j,ip)
                  h=a(j,iq)
                  a(j,ip)=g-s*(h+g*tau)
                  a(j,iq)=h+s*(g-h*tau)
                end do
                do j=ip+1,iq-1
                  g=a(ip,j)
                  h=a(j,iq)
                  a(ip,j)=g-s*(h+g*tau)
                  a(j,iq)=h+s*(g-h*tau)
                end do
                do j=iq+1,n
                  g=a(ip,j)
                  h=a(iq,j)
                  a(ip,j)=g-s*(h+g*tau)
                  a(iq,j)=h+s*(g-h*tau)
                end do
                do j=1,n
                  g=v(j,ip)
                  h=v(j,iq)
                  v(j,ip)=g-s*(h+g*tau)
                  v(j,iq)=h+s*(g-h*tau)
                end do
                nrot=nrot+1
              end if
            end do
          end do
          do ip=1,n
            b(ip)=b(ip)+z(ip)
            d(ip)=b(ip)
            z(ip)=0
          end do
        end do

        return

        end subroutine jacobi

        !==============================================

        subroutine intra_sd(locntraits,ssigmai,dsigmai,covp,covas,covad,covaw,covc,cove,covapaq, &
          & ssumits,dsumits,sdesttraits,ddesttraits,sits,dits,stempsource,dtempsource,sb, &
          & db,fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd, &
          & hsgroupsdams,proggroupsdams,covcprog,sdcorrfs,sdcorrhs)


        implicit none

        integer :: ssumits,dsumits,locntraits,i,j,k,l,m,n,p,q
        integer, dimension(locntraits) :: sits,dits
        integer, dimension(locntraits,84) :: stempsource,dtempsource
        real, dimension(20) :: fsgroupsoff,hsgroupsoff,proggroupsoffs,hsgroupsdams, &
          & proggroupsdams,proggroupsoffd

        real :: ssigmai,dsigmai,sigmah,noff,neffdams,progoff,progeffdams
        real :: sdcorrfs,sdcorrhs
        real, dimension(locntraits,locntraits) :: covapaq,covp,covas,covad, &
           & covaw,covc,cove,covcprog,fs,hs,s,d
        real, dimension(ssumits,dsumits) :: realrfs,realrhs
        real, dimension(ssumits,1) :: tempcorr1,sb
        real, dimension(dsumits,1) :: db
        real, dimension(1,1) :: tempcorr2
        real, dimension(locntraits,locntraits,83,83) :: matrfs,matrhs

        character(len=1), dimension(locntraits) :: sdesttraits,ddesttraits

        ! calculate intra-class correlations
        ! setup of maximum rfs-matrix
        do p=1,locntraits
          do q=1,locntraits
	    ! own performance + blup
            matrfs(p,q,1,1)=fs(p,q)
            matrfs(p,q,1,2)=d(p,q)/2
            matrfs(p,q,1,3)=s(p,q)/2
            matrfs(p,q,2,2)=d(p,q)
  	    matrfs(p,q,2,3)=0.0
  	    matrfs(p,q,3,3)=s(p,q)
            ! own performance - all groups
            do i=1,20
              matrfs(p,q,1,i+3)=fs(p,q)+((covaw(p,q)+cove(p,q))/sum(fsgroupsoff))
              matrfs(p,q,1,i+23)=hs(p,q)
              matrfs(p,q,1,i+43)=0.0
              matrfs(p,q,1,i+63)=(0.5*covas(p,q))+(0.5*covad(p,q))
            end do
            ! ebv dam -  all groups
            do i=1,20
              matrfs(p,q,2,i+3)=d(p,q)/2
              matrfs(p,q,2,i+23)=0.0
              matrfs(p,q,2,i+43)=0.0
              matrfs(p,q,2,i+63)=d(p,q)/4
            end do
            ! ebv sire - all groups
            do i=1,20
              matrfs(p,q,3,i+3)=s(p,q)/2
              matrfs(p,q,3,i+23)=s(p,q)/2
              matrfs(p,q,3,i+43)=0.0
              matrfs(p,q,3,i+63)=s(p,q)/4
            end do
            ! full-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrfs(p,q,i+3,j+3)=covas(p,q)+covad(p,q)+covc(p,q)+ &
                    & (((covaw(p,q)+cove(p,q))*(fsgroupsoff(i)-(fsgroupsoff(i)/sum(fsgroupsoff))))/(fsgroupsoff(i)**2))
                else
                  matrfs(p,q,i+3,j+3)=fs(p,q)
                end if
              end do
            end do
            ! full-sib groups - half-sib groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+3,j+23)=covas(p,q)
              end do
            end do
            ! full-sib groups - mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+3,j+43)=0.0
              end do
            end do
            ! full-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+3,j+63)=(0.5*covas(p,q))+(0.5*covad(p,q))+ &
                  & (0.5*covaw(p,q)/sum(fsgroupsoff))
              end do
            end do
            ! half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrfs(p,q,i+23,j+23)=covas(p,q)+(covad(p,q)/hsgroupsdams(i))+ &
                    & (covc(p,q)/hsgroupsdams(i))+(covaw(p,q)/hsgroupsoff(i))+ &
                    & (cove(p,q)/hsgroupsoff(i))
                else
                  matrfs(p,q,i+23,j+23)=covas(p,q)
                end if
              end do
            end do
            ! half-sib groups - mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrfs(p,q,i+23,j+43)=(0.5*d(p,q))/hsgroupsdams(i)
                else
                  matrfs(p,q,i+23,j+43)=0.0
                end if
              end do
            end do
            ! half-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+23,j+63)=0.5*covas(p,q)
              end do
            end do
            ! mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrfs(p,q,i+43,j+43)=d(p,q)/hsgroupsdams(i)
                else
                  matrfs(p,q,i+43,j+43)=0.0
                end if
              end do
            end do
            ! mean ebv of the dams of half-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+43,j+63)=0.0
              end do
            end do
            ! progeny groups
            do i=1,20
              do j=1,20
                matrfs(p,q,i+63,j+63)=0.5*((0.5*covas(p,q))+(0.5*covad(p,q)))
              end do
            end do
            ! symetric elements
            do i=1,83
              do j=1,83
                if (j.gt.i) then
                  matrfs(p,q,j,i)=matrfs(p,q,i,j)
                end if
              end do
            end do
          end do
        end do

	! setup of real rfs-matrix
        m=0
        n=0
        do i=1,locntraits
          if (sdesttraits(i).eq."i" .or. sdesttraits(i).eq."b") then
            do j=1,locntraits
              if (ddesttraits(j).eq."i" .or. ddesttraits(j).eq."b") then
                do k=1,sits(i)-1
                  do l=1,dits(j)-1
                    realrfs(k+m,l+n)=matrfs(i,j,stempsource(i,k),dtempsource(j,l))
         !           print *,"realrfs (",k+m,",",l+n,")=",realrfs(k+m,l+n),";"
        	  end do
                end do
                n=n+dits(j)-1
              end if
            end do
            m=m+sits(i)-1
            n=0
          end if
        end do
     !	print *,"real rfs is goed"

       ! calculate correlation
       tempcorr1=matmul(realrfs,db)
       tempcorr2=matmul(transpose(sb),tempcorr1)
       sdcorrfs=tempcorr2(1,1)/(sqrt(ssigmai)*sqrt(dsigmai))

        ! setup of maximum rhs-matrix
        do p=1,locntraits
          do q=1,locntraits
	    ! own performance + blup
            matrhs(p,q,1,1)=hs(p,q)
            matrhs(p,q,1,2)=0.0
            matrhs(p,q,1,3)=s(p,q)/2
            matrhs(p,q,2,2)=0.0
  	    matrhs(p,q,2,3)=0.0
  	    matrhs(p,q,3,3)=s(p,q)
            ! own performance - all groups
            do i=1,20
              matrhs(p,q,1,i+3)=hs(p,q)
              matrhs(p,q,1,i+23)=covas(p,q)+(covad(p,q)/sum(hsgroupsdams))+ &
                & ((covaw(p,q)+cove(p,q))/sum(hsgroupsoff))
              matrhs(p,q,1,i+43)=(0.5*d(p,q))/sum(hsgroupsdams)
              matrhs(p,q,1,i+63)=0.5*hs(p,q)
            end do
            ! ebv dam -  all groups
            do i=1,20
              matrhs(p,q,2,i+3)=0.0
              matrhs(p,q,2,i+23)=(0.5*d(p,q))/sum(hsgroupsdams)
              matrhs(p,q,2,i+43)=d(p,q)/sum(hsgroupsdams)
              matrhs(p,q,2,i+63)=0.0
            end do
            ! ebv sire - all groups
            do i=1,20
              matrhs(p,q,3,i+3)=s(p,q)/2
              matrhs(p,q,3,i+23)=s(p,q)/2
              matrhs(p,q,3,i+43)=0.0
              matrhs(p,q,3,i+63)=s(p,q)/4
            end do
            ! full-sib groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+3,j+3)=hs(p,q)
              end do
            end do
            ! full-sib groups - half-sib groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+3,j+23)=covas(p,q)+(covad(p,q)/sum(hsgroupsdams))+ &
                  & ((covaw(p,q)+cove(p,q))/sum(hsgroupsoff))
              end do
            end do
            ! full-sib groups - mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+3,j+43)=(0.5*d(p,q))/sum(hsgroupsdams)
              end do
            end do
            ! full-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+3,j+63)=0.5*hs(p,q)
              end do
            end do
            ! half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrhs(p,q,i+23,j+23)=covas(p,q)+ &
                    & (covad(p,q)*((sum(hsgroupsdams)-(hsgroupsoff(i)/sum(hsgroupsoff)))/(sum(hsgroupsdams))**2))+ &
                    & ((covaw(p,q)+cove(p,q))*(sum(hsgroupsdams)-(hsgroupsoff(i)/sum(hsgroupsoff)))/(sum(hsgroupsdams)*sum(hsgroupsoff)))
	        else
                  matrhs(p,q,i+23,j+23)=hs(p,q)
                end if
              end do
            end do
            ! half-sib groups - mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrhs(p,q,i+23,j+43)=0.5*d(p,q)*((hsgroupsdams(i)-1)/(hsgroupsdams(i)**2))
                else
                  matrhs(p,q,i+23,j+43)=0.0
                end if
              end do
            end do
            ! half-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+23,j+63)=(0.5*covas(p,q))+(0.5*covad(p,q)/sum(hsgroupsdams))+ &
                  & (0.5*covaw(p,q)/sum(hsgroupsoff))
              end do
            end do
            ! mean ebv dams of half-sib groups
            do i=1,20
              do j=1,20
                if (i.eq.j) then
                  matrhs(p,q,i+43,j+43)=d(p,q)*((hsgroupsdams(i)-1)/(hsgroupsdams(i)**2))
                else
                  matrhs(p,q,i+43,j+43)=0.0
                end if
              end do
            end do
            ! mean ebv of the dams of half-sib groups - progeny groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+43,j+63)=(0.25*d(p,q))/(sum(hsgroupsdams))
              end do
            end do
            ! progeny groups
            do i=1,20
              do j=1,20
                matrhs(p,q,i+63,j+63)=0.25*hs(p,q)
              end do
            end do
            ! symetric elements
            do i=1,83
              do j=1,83
                if (j.gt.i) then
                  matrhs(p,q,j,i)=matrhs(p,q,i,j)
                end if
              end do
            end do
          end do
        end do

	! setup of real rhs-matrix
        m=0
        n=0
        do i=1,locntraits
          if (sdesttraits(i).eq."i" .or. sdesttraits(i).eq."b") then
            do j=1,locntraits
              if (ddesttraits(j).eq."i" .or. ddesttraits(j).eq."b") then
                do k=1,sits(i)-1
                  do l=1,dits(j)-1
                    realrhs(k+m,l+n)=matrhs(i,j,stempsource(i,k),dtempsource(j,l))
          !          print *,"realrhs (",k+m,",",l+n,")=",realrhs(k+m,l+n),";"
        	  end do
                end do
                n=n+dits(j)-1
              end if
            end do
            m=m+sits(i)-1
            n=0
          end if
        end do
     !	print *,"real rhs is goed"

       ! calculate correlation
       tempcorr1=matmul(realrhs,db)
       tempcorr2=matmul(transpose(sb),tempcorr1)
       sdcorrhs=tempcorr2(1,1)/(sqrt(ssigmai)*sqrt(dsigmai))


        if (sdcorrfs.lt.-1.0) then
	  sdcorrfs=-1.0
        end if
        if (sdcorrfs.gt.1.0) then
	  sdcorrfs=1.0
        end if
        if (sdcorrhs.lt.-1.0) then
	  sdcorrhs=-1.0
        end if
        if (sdcorrhs.gt.1.0) then
	  sdcorrhs=1.0
        end if



        end subroutine intra_sd


!==================================================================================
REAL FUNCTION dFmtblup(nt,nim,nif,infom,infof,v,cas,cad,cis,cid,pm,pf,d,&
              & bm,bf,vim,vif,rfsmm,rfsmf,rfsff,rhsmm,rhsmf,rhsff,nm,nf,m,f)
!Calculates the rate of inbreeding for multi-trait selection on BLUP-EBV
!in discrete generations. The selective advantage is the breeding goal plus
!the term for the mate. That is, the sum of breeding values weighted
!by the economic weights.
!Input are the Bulmer equilibrium parameters. This subroutine does not
!contain routines to calculate those Bulmer equilibrium parameters
!The correction of the selected proportion according to Wray et al. (1990) (see
!Bijma and Woolliams, 2000) is included for schemes with less than 20 parents
!When going from 20 to 19 parents, therefore, there may be some discontinuity
!in the prediction.
!List of symbols used:
!nt=number of traits,nim=number of infosources males, nif=idem females
!infom=vector identifying the type of info source for males, infof=idem females,
!v = vector of economic weights, cas=additive genetic (co)variance matrix of the
!selected sires, cad=idem dams, cim=covar matrix of EBV for sires, cid=idem dams,
!pm=selected prop. males, pf=idem females, d=mating ratio, bm=vector of index
!weights for males, bf=idem females, vim=variance of index males, vif=idem fem.
!rfsmm=intraclass correlation between index of male full sibs, rfsmf=idem between
!a male and its female fullsib, rfsff=idem between female full sibs, rhsmm .. rhsff
!=idem halfsibs, nm=number of male selection candidates per dam, nf=number female
!selection candidates per dam, m=number of sires, f = number of dams.
!==================================================================================
!USE normal_table
USE seltools
IMPLICIT NONE
INTEGER, INTENT(IN) :: nt,nim,nif
INTEGER, DIMENSION(nt,84), INTENT(IN) :: infom,infof
REAL, DIMENSION(nt), INTENT(IN) :: v
REAL, DIMENSION(nt,nt), INTENT(IN) :: cas,cad,cis,cid
REAL, DIMENSION(nim), INTENT(IN) :: bm
REAL, DIMENSION(nif), INTENT(IN) :: bf
REAL, INTENT(IN) :: vim,vif,pm,pf,d,rfsmm,rfsmf,rfsff,rhsmm,rhsmf,rhsff
INTEGER :: i,j
REAL, DIMENSION(nim,nt) :: Cmm,Cmf
REAL, DIMENSION(nif,nt) :: Cfm,Cff
REAL :: delf,vsa(2),half(2,1),big(2,2),Imat(2,2),glambda(2,2),gpi(2,2),bb(2),dum(2,1)
REAL :: imal,ifem,km,kf,xm,xf,ssqm,ssqf,nm,nf,m,f
REAL :: cSS_fsm,cSS_fsmf,cSS_fsf,cSS_hsm,cSS_hsmf,cSS_hsf

!selection parameters
call trunc(pval=pm,xval=xm,ival=imal,kval=km)
call trunc(pval=pf,xval=xf,ival=ifem,kval=kf)

!variance of the selective advantage
!no reduction for finite population size here because in calculation of
!pi and lambda other (co)variances do not have finite reduction either
!reduction for finite before calculating u-squared
vsa(1) = SUM(v*MATMUL(cas,v)) + SUM(v*MATMUL(cad,v))/d
vsa(2) = SUM(v*MATMUL(cas,v)) + SUM(v*MATMUL(cad,v))

CALL create_C()

glambda(1,1)=SUM(bm*MATMUL(Cmm,v))*imal/(SQRT(vim)*vsa(1))
glambda(1,2)=SUM(bm*MATMUL(Cmf,v))*imal/(SQRT(vim)*vsa(2))
glambda(2,1)=SUM(bf*MATMUL(Cfm,v))*ifem/(SQRT(vif)*vsa(1))
glambda(2,2)=SUM(bf*MATMUL(Cff,v))*ifem/(SQRT(vif)*vsa(2))
glambda=0.5*glambda

gpi(1,1)=0.5-SUM(bm*MATMUL(Cmm,v))*km/vsa(1)
gpi(1,2)=0.5-SUM(bm*MATMUL(Cmf,v))*km/vsa(2)
gpi(2,1)=0.5-SUM(bf*MATMUL(Cfm,v))*kf/vsa(1)
gpi(2,2)=0.5-SUM(bf*MATMUL(Cff,v))*kf/vsa(2)
gpi=0.5*gpi

!solve beta
Imat=RESHAPE( (/1.0, 0.0, 0.0, 1.0/), (/2,2/) )
half=0.5
big=Imat-TRANSPOSE(gpi)
big=1.0/(big(1,1)*big(2,2)-big(1,2)*big(2,1))&
    & *RESHAPE( (/big(2,2),-1.0*big(2,1),-1.0*big(1,2),big(1,1)/), (/2,2/) )     !invert
dum=MATMUL(MATMUL(big,TRANSPOSE(glambda)),half)
bb(:)=dum(:,1)                          		!get rid of one dimension
bb(1)=bb(1)/REAL(m)
bb(2)=bb(2)/REAL(f)
!PRINT *,'beta',bb

!rate of inbreeding without Poisson correction
!account for finite population size in vsa
vsa(1) = (SUM(v*MATMUL(cas,v)) + SUM(v*MATMUL(cad,v))/d)*(1.0-1.0/m)
vsa(2) = SUM(v*MATMUL(cas,v))*(1.0-1.0/m) + SUM(v*MATMUL(cad,v))*(1.0-1.0/f)
ssqm = 1.0/(4*m) + bb(1)*bb(1)*vsa(1) * REAL(m)
ssqf = 1.0/(4*f) + bb(2)*bb(2)*vsa(2) * REAL(f)
delf=0.5*(ssqm + ssqf)
!PRINT *,'Predicted rate of inbreeding before correction :',delf

CALL Poissoncorr()
dFmtblup=delf                                   !rate of inbreeding

Contains

!=========================================================================
SUBROUTINE create_C()
!calculates the covariance matrices between the selective advantage of the
!parent and the info-sources of the offspring.
!=========================================================================
INTEGER :: counter,k

!male offspring
counter = 0
info_traitsm: DO i=1,nt
  info_sourcesm: DO j=1,84
    select case (infom(i,j))
      case (-1:0)
        EXIT info_sourcesm
      case (1)                                                          !own perf
        counter=counter+1
        Cmm(counter,:)=(/ (0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt) /)       !sires
        Cmf(counter,:)=(/ (0.5*cas(i,k)+0.5*cad(i,k),k=1,nt) /)         !dams
      case (2)                                                          !ebvdam
        counter=counter+1
        Cmm(counter,:)=(/ (cid(i,k)/d,k=1,nt) /)
        Cmf(counter,:)=(/ (cid(i,k),k=1,nt) /)
      case (3)                                                          !ebv sire
        counter=counter+1
        Cmm(counter,:)=(/ (cis(i,k),k=1,nt) /)
        Cmf(counter,:)=(/ (cis(i,k),k=1,nt) /)
      case (4:23)                                                       !full sibs
        counter=counter+1
        Cmm(counter,:)=(/ (0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt) /)
        Cmf(counter,:)=(/ (0.5*cas(i,k)+0.5*cad(i,k),k=1,nt) /)
      case (24:43)                                                      !half sibs
        counter=counter+1
        Cmm(counter,:)=(/ (0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt) /)
        Cmf(counter,:)=(/ (0.5*cas(i,k),k=1,nt) /)
      case (44:63)                                                      !damhs ebv
        counter=counter+1
        Cmm(counter,:)=(/ (cid(i,k)/d,k=1,nt) /)
        Cmf(counter,:)= 0.0
      case (64:83)                                                      !progeny
        counter=counter+1
        Cmm(counter,:)=(/ (0.25*cas(i,k)+0.25*cad(i,k)/d,k=1,nt) /)
        Cmf(counter,:)=(/ (0.25*cas(i,k)+0.25*cad(i,k),k=1,nt) /)
      case default
        PRINT *,'ERROR, inconsistency in info sources males in function dFmtblup'
        stop
    end select
  ENDDO info_sourcesm
ENDDO info_traitsm
if (counter/=nim) then
  PRINT *,'ERROR IN INFOSOURCES FOR MALES IN FUNCTION dFmtblup'
  stop
end if

!female offspring
counter = 0
info_traitsf: DO i=1,nt
  info_sourcesf: DO j=1,84
    select case (infof(i,j))
      case (-1:0)
        EXIT info_sourcesf
      case (1)                                                          !own perf
        counter=counter+1
        Cfm(counter,:)=(/ (0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt) /)       !sires
        Cff(counter,:)=(/ (0.5*cas(i,k)+0.5*cad(i,k),k=1,nt) /)         !dams
      case (2)                                                          !ebvdam
        counter=counter+1
        Cfm(counter,:)=(/ (cid(i,k)/d,k=1,nt) /)
        Cff(counter,:)=(/ (cid(i,k),k=1,nt) /)
      case (3)                                                          !ebv sire
        counter=counter+1
        Cfm(counter,:)=(/ (cis(i,k),k=1,nt) /)
        Cff(counter,:)=(/ (cis(i,k),k=1,nt) /)
      case (4:23)                                                       !full sibs
        counter=counter+1
        Cfm(counter,:)=(/ (0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt) /)
        Cff(counter,:)=(/ (0.5*cas(i,k)+0.5*cad(i,k),k=1,nt) /)
      case (24:43)                                                      !half sibs
        counter=counter+1
        Cfm(counter,:)=(/ (0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt) /)
        Cff(counter,:)=(/ (0.5*cas(i,k),k=1,nt) /)
      case (44:63)                                                      !damhs ebv
        counter=counter+1
        Cfm(counter,:)=(/ (cid(i,k)/d,k=1,nt) /)
        Cff(counter,:)= 0.0
      case (64:83)                                                      !progeny
        counter=counter+1
        Cfm(counter,:)=(/ (0.25*cas(i,k)+0.25*cad(i,k)/d,k=1,nt) /)
        Cff(counter,:)=(/ (0.25*cas(i,k)+0.25*cad(i,k),k=1,nt) /)
      case default
        PRINT *,'ERROR, inconsistency in info sources females in function dFmtblup'
        stop
    end select
  ENDDO info_sourcesf
ENDDO info_traitsf
if (counter/=nif) then
  PRINT *,'ERROR IN INFOSOURCES FOR FEMALES IN FUNCTION dFmtblup'
  stop
end if

END SUBROUTINE create_C

!=========================================================================
SUBROUTINE Poissoncorr()
!calculates the Poisson correction, see Bijma and Woolliams, Genetics 2000
!=========================================================================
REAL :: kmfs,kmhs,kffs,kfhs,imfs,iffs,imhs,ifhs,pmfs,pffs,pmhs,pfhs,xmfs,xffs
REAL :: xmhs,xfhs,rhofsmm,rhofsmf,rhofsff,rhohsmm,rhohsmf,rhohsff,dum

!sample value of the intra-class correlation between sibs
!since the indices of males and females can differ, there are three types of
!intraclass correlations: between male sibs, between a male and its female sib
!and between female sibs.
rhofsmm=rfsmm-rfsmm*(1-rfsmm*rfsmm)*(0.8634/REAL(m)+0.954/REAL(f))
rhofsmf=rfsmf-rfsmf*(1-rfsmf*rfsmf)*(0.8634/REAL(m)+0.954/REAL(f))
rhofsff=rfsff-rfsff*(1-rfsff*rfsff)*(0.8634/REAL(m)+0.954/REAL(f))
rhohsmm=rhsmm-rhsmm*(1-rhsmm*rhsmm)*(1.4075/REAL(m)+1.4581/REAL(f))
rhohsmf=rhsmf-rhsmf*(1-rhsmf*rhsmf)*(1.4075/REAL(m)+1.4581/REAL(f))
rhohsff=rhsff-rhsff*(1-rhsff*rhsff)*(1.4075/REAL(m)+1.4581/REAL(f))

!correction of the selected proportion according to Wray et al., 1990
!and recalculate the intensity etc.
 IF(m<20) THEN
      pmfs=(1.0-rhofsmm)*pm + rhofsmm*MAX(pm,1.0/REAL(m))
      pffs=(1.0-rhofsff)*pf + rhofsff*MAX(pf,1.0/REAL(m))
      pmhs=(1.0-rhohsmm)*pm + rhohsmm*MAX(pm,1.0/REAL(m))
      pfhs=(1.0-rhohsff)*pf + rhohsff*MAX(pf,1.0/REAL(m))
      call trunc(pval=pmfs,xval=xmfs,ival=imfs,kval=kmfs)
      call trunc(pval=pffs,xval=xffs,ival=iffs,kval=kffs)
      call trunc(pval=pmhs,xval=xmhs,ival=imhs,kval=kmhs)
      call trunc(pval=pfhs,xval=xfhs,ival=ifhs,kval=kfhs)
  ELSE
      pmfs=pm
      pmhs=pm
      pffs=pf
      pfhs=pf
      imfs=imal
      imhs=imal
      iffs=ifem
      ifhs=ifem
      xmfs=xm
      xmhs=xm
      xffs=xf
      xfhs=xf
      kmfs=km
      kmhs=km
      kffs=kf
      kfhs=kf
  ENDIF

!Probability ratio's cond/uncond = 1/R_Burrows
!full sibs
dum=(imfs*rhofsmm-xmfs)/SQRT(1.0-kmfs*rhofsmm**2)
cSS_fsm =sabf(dum)/pmfs					!=p(m|m_fs selected)/p(m)
dum=(imfs*rhofsmf-xffs)/SQRT(1.0-kmfs*rhofsmf**2)
cSS_fsmf=sabf(dum)/pffs					!this is the most accurate one
dum=(iffs*rhofsff-xffs)/SQRT(1.0-kffs*rhofsff**2)
cSS_fsf =sabf(dum)/pffs

!half sibs
dum=(imhs*rhohsmm-xmhs)/SQRT(1.0-kmhs*rhohsmm**2)
cSS_hsm =sabf(dum)/pmhs
dum=(imhs*rhohsmf-xfhs)/SQRT(1.0-kmhs*rhohsmf**2)
cSS_hsmf=sabf(dum)/pfhs
dum=(ifhs*rhohsff-xfhs)/SQRT(1.0-kfhs*rhohsff**2)
cSS_hsf =sabf(dum)/pfhs

CALL hyper_correct

END SUBROUTINE Poissoncorr

!============================================
SUBROUTINE hyper_correct
!correction according to Burrows 1984
!full hypergeometric variance is calculated
!and mean conditional on model is substracted
!See woolliams and bijma (1999)
!============================================
REAL :: znm,znf,zm,zf,ztm,ztf,d1,d2
REAL :: mu_sqm,mu_sqf,mu_sqmf,pi(2,2),Vs(2,2),Vd(2,2),delta(2,1,1),alpha(2,1),corr
!
  ztm=REAL(nm*f)
  ztf=REAL(nf*f)
  znm=REAL(nm)
  znf=REAL(nf)
  zm=REAL(m)
  zf=REAL(f)
!
!Full sibs
  Vd(1,1)= znm*(znm-1.0)*zm*(zm-1.0)*cSS_fsm/ztm/(ztm-1.0)
  Vd(1,2)= znm*znf*zm*zf*cSS_fsmf/ztm/ztf
  Vd(2,1)= Vd(1,2)
  Vd(2,2)= znf*(znf-1.0)*zf*(zf-1.0)*cSS_fsf/ztf/(ztf-1.0)

!Half sibs
  Vs(1,1)= znm*znm*zm*(zm-1.0)*cSS_hsm/ztm/(ztm-1.0)
  Vs(1,2)= znm*znf*zm*zf*cSS_hsmf/ztm/ztf
  Vs(2,1)= Vs(1,2)
  Vs(2,2)= znf*znf*zf*(zf-1.0)*cSS_hsf/ztf/(ztf-1.0)

!sires
  Vs=d*Vd+d*(d-1.0)*Vs				!full sire fam size variance

!mean squared conditional on selective advantage
!finite vsa used here
  mu_sqm=1.0+2*glambda(1,1)*vsa(1)*2*glambda(1,1)
  mu_sqmf=d*(1.0+2*glambda(1,1)*vsa(1)*2*glambda(2,1))
  mu_sqf=d*d*(1.0+2*glambda(2,1)*vsa(1)*2*glambda(2,1))
!WRITE(27,*) 'mu_sqs',mu_sqm,mu_sqmf,mu_sqf

  Vs(1,1)=Vs(1,1) - mu_sqm			!subtract the mean squared
  Vs(1,2)=Vs(1,2) - mu_sqmf
  Vs(2,1)=Vs(1,2)
  Vs(2,2)=Vs(2,2) - mu_sqf
!
  mu_sqm=(1.0+2*glambda(1,2)*vsa(2)*2*glambda(1,2))/d/d
  mu_sqmf=(1.0+2*glambda(1,2)*vsa(2)*2*glambda(2,2))/d
  mu_sqf=1.0+2*glambda(2,2)*vsa(2)*2*glambda(2,2)
!WRITE(27,*) 'mu_sqd',mu_sqm,mu_sqmf,mu_sqf

  Vd(1,1)= Vd(1,1) - mu_sqm
  Vd(1,2)= Vd(1,2) - mu_sqmf
  Vd(2,1)= Vd(1,2) 	
  Vd(2,2)= Vd(2,2) - mu_sqf

! check for negative variances
  IF((Vs(1,1)+1.0)<0.0) PRINT *, 'negative variance Vs 1,1'
  IF((Vs(2,2)+d)<0.0) PRINT *, 'negative variance Vs 2,2'
  IF((Vd(1,1)+1.0/d)<0.0) PRINT *, 'negative variance Vd 1,1'
  IF((Vd(2,2)+1.0)<0.0) PRINT *, 'negative variance Vd 2,2'
!
!  WRITE(27,*) 'Vn_dev for sires',Vs
!  WRITE(27,*) 'Vn_dev for dams',Vd
  alpha(1,1)=1.0/(2*m)
  alpha(2,1)=1.0/(2*f)
  delta(1,:,:)= MATMUL(MATMUL(TRANSPOSE(alpha),Vs),alpha)
  delta(2,:,:)= MATMUL(MATMUL(TRANSPOSE(alpha),Vd),alpha)
 ! WRITE(27,*) 'delta ',delta

IF(m>19) THEN           !!effect of beta added to the correction
pi=2.0*gpi

!sires
d1= bb(1)**2 * pi(1,1)**2 * Vs(1,1) * vsa(1)
d1= d1+2.0*bb(1)*pi(1,1)*bb(2)*pi(2,1)*Vs(1,2)*vsa(1)
d1= d1+(bb(2)*pi(2,1))**2*Vs(2,2)*vsa(1)
delta(1,:,:)=delta(1,:,:)+d1

!dams
d2= bb(1)**2 * pi(1,2)**2 * Vd(1,1)*vsa(2)
d2= d2+2.0*bb(1)*pi(1,2)*bb(2)*pi(2,2)*Vd(1,2)*vsa(2)
d2= d2+(bb(2)*pi(2,2))**2*Vd(2,2)*vsa(2)
delta(2,:,:)=delta(2,:,:)+d2
ENDIF

 ! WRITE(27,*) 'delta ',delta
  corr= 0.125*(m*delta(1,1,1)+f*delta(2,1,1))
  delf=delf+corr
 ! WRITE(27,*)'value of the correction ',corr
end subroutine hyper_correct

END Function dFmtblup

        end module selroutines









