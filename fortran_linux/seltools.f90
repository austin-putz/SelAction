!     Last change:  MR   15 Jan 2001   12:16 pm
	module seltools
      implicit none
      integer, parameter :: rr=selected_real_kind(p=14)
      save
!
contains
!
!=======================
real function gcef(q,ix)
!
!     calculates normal deviate x from lower tail proportion p
!     algorithm from cw/j/mg.... corrected jaw 8/8/96, f90 jaw 13/11/96
!=======================
      implicit none
      integer, optional :: ix
      real :: q
      real(kind=rr) :: &
     & p,pp,zero=0.0_rr,one=1.0_rr,half=0.5_rr,u,t,x, &
     & a1=2.515517_rr,a2=0.802853_rr,a3=0.010328_rr,  &
     & b1=1.432788_rr,b2=0.189269_rr,b3=0.001308_rr
     !
      p=real(q,kind=rr)
      select case ((p>=zero).and.(p<=one))
      case (.true.)
        if(present(ix)) ix=0
        if(p>=one) then
          gcef=7.0_rr                 !jaw
        elseif(p<1.0e-10_rr) then
          gcef=-7.0_rr                !jaw
!       elseif(p==half) then
!          gcef=zero
        else
! calculates for probabilities gt half by using remainder
          if(p>half) then
            pp=one-p
          else
            pp=p
          endif
          u=log(one/(pp*pp))
          t=sqrt(u)
          x=(a1 + (a2*t) + (a3*u))
          x=x/(one + (b1*t) + (b2*u) + b3*exp(3.0_rr*log(t)))
          if(p>half) then
            gcef=t-x
          else
            gcef=x-t
          endif
        endif
      case default
        if(present(ix)) ix=1
        print *," -error-30- : probability out of bounds"
        gcef=zero
      end select
end function gcef
!
!========================
real function sabf(xx,ix)
!
!     calculates p proportion from x normal deviate
!     jaw f90 13/11/96 based on bv f77
!========================
      implicit none
      integer, optional :: ix
      real :: xx
      real(kind=rr) :: x,y,z,p,zero=0.0_rr,half=0.5_rr,one=1.0_rr
!
      x=real(xx,kind=rr)
      if(abs(x)>=7.0_rr) then
        if(present(ix)) ix=1
        print *," -error-40- : probability out of bounds"!greater than 7
      end if
      if(x<=-7.0_rr)then
        sabf=zero
      else if(x>=7.0_rr) then
        sabf=one
      else if(abs(x)<=tiny(x)) then
        sabf=half
      else
        z=abs(x)
        y=half*z*z
        if(z<=1.28_rr) then
          p=y+5.92885724438_rr
          p=y+2.62433121679_rr + 48.6959930692_rr/p
          p=y+5.75885480458_rr - 29.8213557808_rr/p
          p=half - z*(0.398942280444_rr - 0.399903438504_rr*y/p)
          if(x>zero) p=one-p
          sabf=p
        else
          p=z+ 3.99019417011_rr
          p=z+0.742380924027_rr +  30.789933034_rr/p
          p=z+  4.8385912808_rr - 15.1508972451_rr/p
          p=z-0.151679116635_rr + 5.29330324926_rr/p
          p=z+3.98064794e-04_rr + 1.98615381364_rr/p
          p=z-    3.8052e-08_rr + 1.00000615302_rr/p
          p=0.398942280385_rr*exp(-y)/p
          if(x>zero) p=one-p
          sabf=p
        endif
      if(present(ix)) ix=0
      endif
end function sabf

!======================================

	real function factor(x)
        implicit none
        real*8:: x

	factor=.63*exp(3.36*(x-1.))+.37*exp(86.*(x-1.))
	return
	end function factor

!=====================================

	real function sintvi(pp,n)
! voor dokumentatie zie brascamp (1978) pg 93

        implicit none
        integer :: n,i,j
        real :: pp,a,p,r,t,c,b

	dimension a(0:10)
	p=pp
	if(n.ne.0)then
	    if(p.lt.1./n)p=1./n
	end if
	if(p.ge.1.)then
		sintvi=0.0
		goto 3
	end if
	r=1./p-1.
   !     print *,"      r ",r
        t=log(r)
    !    print *," log(r) ",t
        if(p.le..5)go to 1
	t=-t
	c=r
	goto 2
1	c=1.
2	sintvi=(((((-.0000991394*t+.00218171)*t-.0175066)*t+.0455729)*t+.399041)*t+.79788456)*c

	if(p.ge.0.001)goto 10   ! benadering wordt slechter
	a(0)=3.960
	a(1)=3.960   ! uit falconer, 1980, pg 316.
	a(2)=3.790
	a(3)=3.687
	a(4)=3.613
	a(5)=3.554
	a(6)=3.507
	a(7)=3.464
	a(8)=3.429
	a(9)=3.397
	a(10)=3.367
	b=p*10000.    ! 0<b<10
	i=int(b)
	j=int(b+1.)
	sintvi=a(i)*(j*1.-b)+a(j)*(b-i*1.)

10	if(n.ne.0)sintvi=sintvi-r/(float(n+n+2)*sintvi)
	
3	return
	end function sintvi

        !=================================================

real function rawl3(p,nw,nfs,nhs,tfs,ths)
        implicit none
! aangepast voor gebruik van non-integers!!!!

! rawl3 calculates selection differential for a hierarchical full - paternal
! half sib population, by a three dimensional application of rawlings formula
! (see meuwissen, 1991, biometrics 47:195)
! ns = number of animals selected
! nw = number of animals within full sib family
! nfs= number of full sib families per half sib family
! nhs= number of half sib families in population
! tfs= intra class correlation between estimated breeding values of full sibs
! ths= intra class correlation between estimated breeding values of half sibs
!
! when the population consists of full or half sib families only:
! nfs=1
! nw = number of animals within family
! nhs= number of families
! tfs= intra class correlation between breeding values of relatives.
!
! some intrinsi! vax-fortran functions are used:
! alog = natural logarithm
! jnint = nearest integer
! jmod = modulus, i.e. the rest after dividing the 1st by the 2nd argument
! jint = truncate (e.g. 2.8 ->2)
! floatj = convert integer to real
!
! theo meuwissen, res. inst. anim. prod. 'schoonoord', po box 501, 3700 am
! the netherlands. e-mail: tme@ivo.agro.nl

! we berekenen eerst si voor tfs=ths=1 (sic)
        integer :: n,na

	real :: nw,nfs,nhs,nr,ns,ths,tfs
        real :: sic,si1,si2,sib,sia,w1,y,wt,rhoa,rhoac,rhobc,rhobc2,rhoc
        real :: rhoc2,rhob,ac,bc,ba,b,siac,bbc,sibc,pp,p
        real*8 :: dumfs,dumhs  ! marc

!        real, external :: factor,sintvi

!	p=ns*1./(nw*nfs*nhs)
	ns=p*nw*nfs*nhs
	nr=mod(ns,nw*nfs)  ! nf= rest uit deling ns/nf (# uit laagst gesel fam
	na=nint((ns-nr)*1./(nfs*nw))+1 ! # fam waaruit dieren gehaald worden
        if(nr.eq.ns)then     ! alle dieren uit beste familie
	    sic=sintvi((1./nhs),nint(nhs))
	else                 ! moet gewogen gemiddelde bepaald worden
	    si1=sintvi((((na-1)*1.)/nhs),nint(nhs))  ! si bij na-1 gesel. fam
	    si2=sintvi(((na*1.)/nhs),nint(nhs))      ! si bij na gesel fam
	    sic=(si1*(nw*nfs-nr)*(na-1)+si2*na*nr)/ns  ! ***))
	end if
! ***))
! afleiding:
!  sic={nf*x(1)+    +nf*x(na-1)+nr*x(na)}/ns  met x(i) is verw.waarde fam rank
!  si1={nf*x(1)+    +nf*x(na-1)}/(ns-nr)
!  si2={nf*x(1)+    +nf*x(na)}/(ns-nr+nf)
!  na enig omwerken van si1 en si2 naar sic volgt bovenstaande formule


! we berekenen nu si voor tfs=1;ths=0 (sib)
	ns=p*nw*nfs*nhs ! ns= # geselecteerd
	nr=mod(ns,nw)  ! nf= rest uit deling ns/nf (# uit laagst gesel fam
	na=nint((ns-nr)*1./(nw))+1 ! # fam waaruit dieren gehaald worden
        if(nr.eq.ns)then     ! alle dieren uit beste familie
	    sib=sintvi(1./(nhs*nfs),nint(nhs*nfs))
	else                 ! moet gewogen gemiddelde bepaald worden
	    si1=sintvi((na-1)*1./(nfs*nhs),nint(nfs*nhs))  ! si bij na-1 gesel.
	    si2=sintvi(na*1./(nfs*nhs),nint(nfs*nhs))      ! si bij na gesel
	    sib=(si1*(nw-nr)*(na-1)+si2*na*nr)/ns  ! ***))
	end if
       !	if(sic.le.0.0)then
!	  print *,' sic = ',sic
    !	  print *,' p =',p
     !	  print *,' nw=',nw
      !	  print *,' nfs=',nfs
       !	  print *,' nhs=',nhs
    	!  print *,' tfs=',tfs
    !	  print *,' ths=',ths
     !	  print *,' '
     !	  print *,' ns=',ns
       !	end if
       !	if(sib.le.0.0)
       ! print *,' sib = ',sib
! de si als tfs=ths=0
	n=nint(nw*nfs*nhs)
	sia=sintvi(p,n)

! als nfs=nw=1 => alle individuen ongerelateerd in nhs half sib families(1
	if(abs(nfs-1.).lt..0001.and.abs(nw-1.).lt..0001)then
	     rawl3=sia
	     goto 9
	end if

! als nfs=1 => enkelvoudige fam.structuur: populatie v. nhs full sib  families
! als tfs=1 is de sel.int. sic
	if(abs(nfs-1.).lt..0001)then
	    w1=(log(sic)-log(sia))/log(1.-1.*(nw-1)/(n-1))
            dumfs=tfs       ! marc
	    y=factor(dumfs)
	    wt=.5*(1.-y)+w1*y
	    rawl3=sia*((1.-tfs*(nw-1)/(n-1))**wt)
	    goto 9
	end if

! als nw=1 => enkelvoudige fam.structuur: populatie v. nhs half sib families
! als ths=1 is de sel.int. sic
	if(abs(nw-1.).lt..0001)then
	    w1=(log(sic)-log(sia))/log(1.-1.*(nfs-1)/(n-1))
            dumhs=ths ! marc
	    y=factor(dumhs)
	    wt=.5*(1.-y)+w1*y
	    rawl3=sia*((1.-ths*(nfs-1)/(n-1))**wt)
	    goto 9
	end if

! als nhs=1 => enkelvoudige fam struct: full sib families binnen half sib fam.
! de intra class correlatie binnen half sib familie is tfs-ths
! als tfs-ths=1 is de sel.int. sib
	if(abs(nhs-1.).lt..0001)then
	    w1=(log(sib)-log(sia))/log(1.-1.*(nw-1)/(n-1))
            dumfs=tfs       ! marc
            dumhs=ths       ! marc

	    y=factor(dumfs-dumhs)
	    wt=.5*(1.-y)+w1*y
	    rawl3=sia*((1.-(tfs-ths)*(nw-1)/(n-1))**wt)
	    rawl3=rawl3*sqrt(1.-ths)  ! owen en steck (1962)
	    goto 9
	end if

! als benadering wordt gebruikt: si=((1-rhoa)**b)*sia
	rhoa=((nw-1)*tfs+(nfs-1)*nw*ths)/(n-1)
	rhoac=((nw-1)*ths+(nfs-1)*nw*ths)/(n-1)    ! op lijn ths=tfs
	rhobc=((nw-1)*1.+(nfs-1)*nw*ths)/(n-1)
 !      print *,"tfs",tfs
     !  print *,"ths",ths
       ! print *,"nfs",nfs
        !print *,"nhs",nhs
	rhobc2=ths*(nfs-1)/(nfs*nhs-1)
    !    print *,"rhobc2",rhobc2
     !   print *,"1-rhobc2",1.-rhobc2
	rhoc=((nw-1)*1.+(nfs-1)*nw*1.)/(n-1)
	rhoc2=1.*(nfs-1)/(1.*nfs*nhs-1.)
	rhob=((nw-1)*1.)/(n-1)
	ac=(log(sic)-log(sia))/log(1.-rhoc)
	bc=(log(sic)-log(sib))/log(1.-rhoc2)
	ba=0.5
        dumhs=ths ! marc

	y=factor(dumhs)
	b=ba*(1.-y)+ac*y

	siac=((1.-rhoac)**b)*sia
	bbc=ba*(1.-y)+bc*y
  !      print *,"b",b
   !     print *,"bbc",bbc
	sibc=((1.-rhobc2)**bbc)*sib
	bbc=(log(sibc)-log(sia))/log(1.-rhobc)
	ba=(b-bbc*y)/(1.-y)
        dumfs=tfs ! marc

	y=factor(dumfs)
 ! 	  print *,' ba =',ba
  ! 	  print *,' y=',y
   ! 	  print *,' bbc=',bbc

	b=ba*(1.-y)+bbc*y
     !   print *,"b in rawl3",b
      !	  print *,' '
	rawl3=sia*((1.-rhoa)**b)

9	return
	end function rawl3

!==========================================

       subroutine racine
!***********************************************************************
! valeurs des zeros (positifs) et des rapports poids/zero              *
! du polynome d'hermite de dimension 2x2 … 2x30 (herz, herp)           *
! this subroutine reads values from the file racines2.in, which are    *
! needed to calculate multivariate normal integrals. the data are      *
! stored in the common declarations herz/h and herp/w                  *
!***********************************************************************
      character*60 dummy
      integer m,nrac,i,n
      real*8 pi,rac2pi
      real*8 w(40,40),h(40,40)

      common/pival/pi,rac2pi
      common/herz/h
      common/herp/w

      pi=3.1415926535d0
      rac2pi=2.5066282745918d0

       w( 1 , 2 )= 1.534199440341625
       w( 1 , 4 )= 1.734442752620318
       w( 1 , 6 )= 1.814328391081699
       w( 1 , 8 )= 1.857274886830833
       w( 1 , 10 )= 1.884088754784574
       w( 1 , 12 )= 1.902421962733881
       w( 1 , 14 )= 1.915748219022493
       w( 1 , 16 )= 1.925872122895547
       w( 1 , 18 )= 1.933824111413124
       w( 1 , 20 )= 1.940235371616161
       w( 2 , 2 )= 4.926020145916023E-02
       w( 2 , 4 )= 0.1795743647582679
       w( 2 , 6 )= 0.2748422671893160
       w( 2 , 8 )= 0.3410255353705600
       w( 2 , 10 )= 0.3887263969772554
       w( 2 , 12 )= 0.4244909524588198
       w( 2 , 14 )= 0.4522163669944690
       w( 2 , 16 )= 0.4743046392389396
       w( 2 , 18 )= 0.4923003105638835
       w( 2 , 20 )= 0.5072362625283182
       w( 3 , 4 )= 8.618032840303116E-03
       w( 3 , 6 )= 3.230177538416717E-02
       w( 3 , 8 )= 6.072053823164934E-02
       w( 3 , 10 )= 8.833911930236868E-02
       w( 3 , 12 )= 0.1133688887543762
       w( 3 , 14 )= 0.1354957645832860
       w( 3 , 16 )= 0.1549100483993271
       w( 3 , 18 )= 0.1719420008963130
       w( 3 , 20 )= 0.1869307742108031
       w( 4 , 4 )= 6.810943954774492E-05
       w( 4 , 6 )= 1.713261001922684E-03
       w( 4 , 8 )= 6.599237004969679E-03
       w( 4 , 10 )= 1.427091325919987E-02
       w( 4 , 12 )= 2.363608663035455E-02
       w( 4 , 14 )= 3.378616874816664E-02
       w( 4 , 16 )= 4.411790109103964E-02
       w( 4 , 18 )= 5.426858289634313E-02
       w( 4 , 20 )= 6.403580546605188E-02
       w( 5 , 6 )= 2.838370506712846E-05
       w( 5 , 8 )= 3.661468928344343E-04
       w( 5 , 10 )= 1.438497002285810E-03
       w( 5 , 12 )= 3.439894347024873E-03
       w( 5 , 14 )= 6.324600008484199E-03
       w( 5 , 16 )= 9.930352741297277E-03
       w( 5 , 18 )= 1.406826260925322E-02
       w( 5 , 20 )= 1.856553578624166E-02
       w( 6 , 6 )= 6.834806455881460E-08
       w( 6 , 8 )= 8.535916927493784E-06
       w( 6 , 10 )= 8.187684307637125E-05
       w( 6 , 12 )= 3.263594746093806E-04
       w( 6 , 14 )= 8.415914981524216E-04
       w( 6 , 16 )= 1.684670063152223E-03
       w( 6 , 18 )= 2.868228042867348E-03
       w( 6 , 20 )= 4.373023206618543E-03
       w( 7 , 8 )= 5.998222232039885E-08
       w( 7 , 10 )= 2.330613926467644E-06
       w( 7 , 12 )= 1.888333448397047E-05
       w( 7 , 14 )= 7.609598007393258E-05
       w( 7 , 16 )= 2.080777812457498E-04
       w( 7 , 18 )= 4.468177025335974E-04
       w( 7 , 20 )= 8.158519745260625E-04
       w( 8 , 8 )= 5.662092746849101E-11
       w( 8 , 10 )= 2.753192230827109E-08
       w( 8 , 12 )= 6.131367976079818E-07
       w( 8 , 14 )= 4.453587422213675E-06
       w( 8 , 16 )= 1.810058703125876E-05
       w( 8 , 18 )= 5.186721479246692E-05
       w( 8 , 20 )= 1.181234727960681E-04
       w( 9 , 10 )= 9.556134769248841E-11
       w( 9 , 12 )= 9.914415146242131E-09
       w( 9 , 14 )= 1.587830461662799E-07
       w( 9 , 16 )= 1.068307344382267E-06
       w( 9 , 18 )= 4.371566251504517E-06
       w( 9 , 20 )= 1.301517459270097E-05
       w( 10 , 10 )= 4.138100331209648E-14
       w( 10 , 12 )= 6.585552017939934E-11
       w( 10 , 14 )= 3.174043095895187E-09
       w( 10 , 16 )= 4.084763027857373E-08
       w( 10 , 18 )= 2.596826280759461E-07
       w( 10 , 20 )= 1.068563745743092E-06
       w( 11 , 12 )= 1.251975818007035E-13
       w( 11 , 14 )= 3.146300944729368E-11
       w( 11 , 16 )= 9.519885062667864E-10
       w( 11 , 18 )= 1.048346045879546E-08
       w( 11 , 20 )= 6.380027135267784E-08
       w( 12 , 12 )= 2.766604206609574E-17
       w( 12 , 14 )= 1.266274147282280E-13
       w( 12 , 16 )= 1.242011125856262E-11
       w( 12 , 18 )= 2.745105167506847E-10
       w( 12 , 20 )= 2.689939860354446E-09
       w( 13 , 14 )= 1.419825365033418E-16
       w( 13 , 16 )= 7.989706140837473E-14
       w( 13 , 18 )= 4.380177791042888E-12
       w( 13 , 20 )= 7.718925432626603E-11
       w( 14 , 14 )= 1.729683849969671E-20
       w( 14 , 16 )= 2.060043823988855E-16
       w( 14 , 18 )= 3.901545370251933E-14
       w( 14 , 20 )= 1.437267113237413E-12
       w( 15 , 16 )= 1.440321273447601E-19
       w( 15 , 18 )= 1.701861894879841E-16
       w( 15 , 20 )= 1.628679630942230E-14
       w( 16 , 16 )= 1.025942652992727E-23
       w( 16 , 18 )= 2.935235831634675E-19
       w( 16 , 20 )= 1.026351422719074E-16
       w( 17 , 18 )= 1.336549098002518E-22
       w( 17 , 20 )= 3.143332406353462E-19
       w( 18 , 18 )= 5.831318463207393E-27
       w( 18 , 20 )= 3.753661241315649E-22
       w( 19 , 20 )= 1.152797925069064E-25
       w( 20 , 20 )= 3.199308720551721E-30
       h( 1 , 2 )= 0.7419637843027252
       h( 1 , 4 )= 0.5390798113513747
       h( 1 , 6 )= 0.4444030019441393
       h( 1 , 8 )= 0.3867606045005565
       h( 1 , 10 )= 0.3469641570813558
       h( 1 , 12 )= 0.3173700966294526
       h( 1 , 14 )= 0.2942517144887137
       h( 1 , 16 )= 0.2755464192302764
       h( 1 , 18 )= 0.2600079252489996
       h( 1 , 20 )= 0.2468328960227239
       h( 2 , 2 )= 2.334414218338976
       h( 2 , 4 )= 1.636519042435107
       h( 2 , 6 )= 1.340375197151617
       h( 2 , 8 )= 1.163829100554963
       h( 2 , 10 )= 1.042945348802752
       h( 2 , 12 )= 0.9534219229321089
       h( 2 , 14 )= 0.8836525629929820
       h( 2 , 16 )= 0.8272849037797646
       h( 2 , 18 )= 0.7805064920524658
       h( 2 , 20 )= 0.7408707252859315
       h( 3 , 4 )= 2.802485861287544
       h( 3 , 6 )= 2.259464451000801
       h( 3 , 8 )= 1.951980345716332
       h( 3 , 10 )= 1.745247320814128
       h( 3 , 12 )= 1.593480429816420
       h( 3 , 14 )= 1.475781736957921
       h( 3 , 16 )= 1.380980199272142
       h( 3 , 18 )= 1.302464954480166
       h( 3 , 20 )= 1.236032004799157
       h( 4 , 4 )= 4.144547186125892
       h( 4 , 6 )= 3.223709828770095
       h( 4 , 8 )= 2.760245047630701
       h( 4 , 10 )= 2.458663611172368
       h( 4 , 12 )= 2.240467851691752
       h( 4 , 14 )= 2.072582674144618
       h( 4 , 16 )= 1.938004905925717
       h( 4 , 18 )= 1.826896577986742
       h( 4 , 20 )= 1.733090590631722
       h( 5 , 6 )= 4.271825847932279
       h( 5 , 8 )= 3.600873624171546
       h( 5 , 10 )= 3.189014816553390
       h( 5 , 12 )= 2.897728643223315
       h( 5 , 14 )= 2.676201879526944
       h( 5 , 16 )= 2.499840415187398
       h( 5 , 18 )= 2.354877715992543
       h( 5 , 20 )= 2.232859218634871
       h( 6 , 6 )= 5.500901704467746
       h( 6 , 8 )= 4.492955302520016
       h( 6 , 10 )= 3.943967350657317
       h( 6 , 12 )= 3.569306764073553
       h( 6 , 14 )= 3.289106970171830
       h( 6 , 16 )= 3.068135169013123
       h( 6 , 18 )= 2.887579695004715
       h( 6 , 20 )= 2.736208340465430
       h( 7 , 8 )= 5.472225705949342
       h( 7 , 10 )= 4.734581334046066
       h( 7 , 12 )= 4.260383605019905
       h( 7 , 14 )= 3.914253725963627
       h( 7 , 16 )= 3.644781249880832
       h( 7 , 18 )= 3.426308595129134
       h( 7 , 20 )= 3.244088732999868
       h( 8 , 8 )= 6.630878198393125
       h( 8 , 10 )= 5.578738805893206
       h( 8 , 12 )= 4.978041374639126
       h( 8 , 14 )= 4.555340384596970
       h( 8 , 16 )= 4.232021109995414
       h( 8 , 18 )= 3.972557341929992
       h( 8 , 20 )= 3.757559776168987
       h( 9 , 10 )= 6.510590157013652
       h( 9 , 12 )= 5.732747175251200
       h( 9 , 14 )= 5.217223673447458
       h( 9 , 16 )= 4.832604613244486
       h( 9 , 18 )= 4.528076990600174
       h( 9 , 20 )= 4.277826156362753
       h( 10 , 10 )= 7.619048541679760
       h( 10 , 12 )= 6.541675005098631
       h( 10 , 14 )= 5.906656325824984
       h( 10 , 16 )= 5.450033273623424
       h( 10 , 18 )= 5.094978513857600
       h( 10 , 20 )= 4.806287192093868
       h( 11 , 12 )= 7.437890666021637
       h( 11 , 14 )= 6.633731493950425
       h( 11 , 16 )= 6.088964309076990
       h( 11 , 18 )= 5.675884710106658
       h( 11 , 20 )= 5.344605445720095
       h( 12 , 12 )= 8.507803519195260
       h( 12 , 14 )= 7.415125286176056
       h( 12 , 16 )= 6.755930830540724
       h( 12 , 18 )= 6.274168326809516
       h( 12 , 20 )= 5.894805675372003
       h( 13 , 14 )= 8.283069540861407
       h( 13 , 16 )= 7.460755754121510
       h( 13 , 18 )= 6.894347646173902
       h( 13 , 20 )= 6.459423377583771
       h( 14 , 14 )= 9.321937814408775
       h( 14 , 16 )= 8.219728765382250
       h( 14 , 18 )= 7.542793039211400
       h( 14 , 20 )= 7.041738406453846
       h( 15 , 16 )= 9.064399210702431
       h( 15 , 18 )= 8.229115367471575
       h( 15 , 20 )= 7.646163764541460
       h( 16 , 16 )= 10.07742267422947
       h( 16 , 18 )= 8.969286534562606
       h( 16 , 20 )= 8.278940623659501
       h( 17 , 18 )= 9.794276019583014
       h( 17 , 20 )= 8.949504543855527
       h( 18 , 18 )= 10.78525331238752
       h( 18 , 20 )= 9.673556366934033
       h( 19 , 20 )= 10.48156053467428
       h( 20 , 20 )= 11.45337784154873



  !    open(5,file='racines2.in',form='formatted')
   !   open(15,file='racines2.out',form='formatted')

    !  do 1 m=2,20,2
     !   read(5,*) nrac,dummy
  !      read(5,*) (w(i,m),i=1,m)
   !     read(5,*) (h(i,m),i=1,m)
  ! 1  continue

   !   do m=1,40
    !    do n=1,40
     !     if (w(m,n).ne.0.0) then
      !      write(15,fmt=*) "w(",m,",",n,")=",w(m,n)
    !      end if
     !   end do
   !   end do
    !  do m=1,40
     !   do n=1,40
      !    if (h(m,n).ne.0.0) then
       !     write(15,fmt=*) "h(",m,",",n,")=",h(m,n)
        !  end if
    !    end do
    !  end do

 ! 10  format(2z20)
  !    close(5)
   !   close(15)
      return
      end subroutine racine
      
!***********************************************************************
                                                         

      subroutine sd1dutt(nrac,i,s,d1dutt)
!***********************************************************************
!                fonction d de dutt, dimension 1                       *
!***********************************************************************
      implicit none
      integer i,nrac
      real*8 s,h(40,40),d1dutt
      common/herz/h

      d1dutt=-sin(h(i,nrac)*s)

      return
!c***********************************************************************
      end subroutine sd1dutt

      subroutine sd2dutt(nrac,i,j,s1,s2,r,d2dutt)
!c***********************************************************************
!c                fonction d de dutt, dimension 2                       *
!c***********************************************************************
      implicit none
      integer i,j,nrac
      real*8 pi,rac2pi,s1,s2,r,hi,hj,h(40,40),d2dutt
      common/herz/h

      hi=h(i,nrac)
      hj=h(j,nrac)
      d2dutt=-exp(-r*hi*hj)*cos((hi*s1)+(hj*s2))
      d2dutt=d2dutt+exp(r*hi*hj)*cos((-hi*s1)+(hj*s2))
      return
!***********************************************************************
      end subroutine sd2dutt

      subroutine sd3dutt(nrac,i,j,k,s1,s2,s3,r12,r13,r23,d3dutt)
!c***********************************************************************
!c                fonction d de dutt, dimension 3                       *
!c***********************************************************************
      implicit none
      integer i,j,k,nrac
      real*8 r12,r13,r23,hi,hj,hk,d,s1,s2,s3
      real*8 h(40,40),d3dutt
      common/herz/h

      hi=h(i,nrac)
      hj=h(j,nrac)
      hk=h(k,nrac)
      d=exp((-r12*hi*hj)+(-r13*hi*hk)+(-r23*hj*hk))*sin((hi*s1)+(hj*s2)+(hk*s3))
      d=d-exp((r12*hi*hj)+(r13*hi*hk)+(-r23*hj*hk))*sin((-hi*s1)+(hj*s2)+(hk*s3))
      d=d-exp((r12*hi*hj)+(-r13*hi*hk)+(r23*hj*hk))*sin((hi*s1)+(-hj*s2)+(hk*s3))
      d=d-exp((-r12*hi*hj)+(r13*hi*hk)+(r23*hj*hk))*sin((hi*s1)+(hj*s2)+(-hk*s3))
      d3dutt=d

      return
!***********************************************************************
      end subroutine sd3dutt

!***********************************************************************

      subroutine sdutt1(nrac,s,dutt1)
!***********************************************************************
!                integrales de la loi normale de dimension 1           *
!***********************************************************************
      implicit none
      integer i,nrac
      real*8 pi,rac2pi,s,ssum,w(40,40)
      real*8 :: d1dutt,dutt1
      common/pival/pi,rac2pi
      common/herp/w

      ssum=0.e0
      do 10 i=1,nrac
        call sd1dutt(nrac,i,s,d1dutt)
        ssum=ssum+w(i,nrac)*d1dutt
  10   continue
      dutt1=0.5e0+ssum/pi

      return
!***********************************************************************
      end subroutine sdutt1

      subroutine sdutt2(nrac,s1,s2,r,dutt2)
!c***********************************************************************
!c                integrales de la loi normale de dimension 2           *
!c***********************************************************************
      implicit none
      integer i,j,nrac
      real*8 pi,rac2pi,s1,s2,r,sum1,sum2,li,w(40,40)
      real*8 :: d1dutt,d2dutt,dutt2,tempdutt1,tempdutt2
      common/pival/pi,rac2pi
      common/herp/w

      sum1=0.e0
      sum2=0.e0

      do 30  i=1,nrac
        li=w(i,nrac)
        call sd1dutt(nrac,i,s1,d1dutt)
        tempdutt1=d1dutt
        call sd1dutt(nrac,i,s2,d1dutt)
        tempdutt2=d1dutt
        sum1=sum1+li*(tempdutt1+tempdutt2)
        do 20  j=1,nrac
          call sd2dutt(nrac,i,j,s1,s2,r,d2dutt)
          sum2=sum2+li*w(j,nrac)*d2dutt
  20    continue
  30  continue

      dutt2=0.25e0+(0.5e0*sum1/pi)+(0.5e0*sum2/(pi*pi))
      return
!c***********************************************************************
      end subroutine sdutt2

      subroutine sdutt3(nrac,s1,s2,s3,r12,r13,r23,dutt3)
!c***********************************************************************
!c                integrales de la loi normale de dimension 3           *
!c***********************************************************************
      implicit none
      integer i,j,k,nrac
      real*8 sum1,sum2,sum3,pi2,r12,r13,r23,s1,s2
      real*8 pi,rac2pi,s3,li,lj,w(40,40)
      real*8 :: d1dutt,d2dutt,d3dutt,dutt3,tempdutt1,tempdutt2,tempdutt3
      common/pival/pi,rac2pi
      common/herp/w

      sum1=0.e0
      sum2=0.e0
      sum3=0.e0

      do 70 i=1,nrac
        li=w(i,nrac)
        call sd1dutt(nrac,i,s1,d1dutt)
        tempdutt1=d1dutt
        call sd1dutt(nrac,i,s2,d1dutt)
        tempdutt2=d1dutt
        call sd1dutt(nrac,i,s3,d1dutt)
        tempdutt3=d1dutt
        sum1=sum1+li*(tempdutt1+tempdutt2+tempdutt3)
        do 60 j=1,nrac
          lj=w(j,nrac)
          call sd2dutt(nrac,i,j,s1,s2,r12,d2dutt)
          tempdutt1=d2dutt
          call sd2dutt(nrac,i,j,s1,s3,r13,d2dutt)
          tempdutt2=d2dutt
          call sd2dutt(nrac,i,j,s2,s3,r23,d2dutt)
          tempdutt3=d2dutt

          sum2=sum2+li*lj*(tempdutt1+tempdutt2+tempdutt3)
          do 50 k=1,nrac
            call sd3dutt(nrac,i,j,k,s1,s2,s3,r12,r13,r23,d3dutt)
            sum3=sum3 +li*lj*w(k,nrac)*d3dutt
  50      continue
  60    continue
  70  continue

      pi2=pi*pi
      dutt3=0.125e0+(1.e0/(4.e0*pi))*(sum1+(sum2/pi)+(sum3/(pi2)))
      return
      end subroutine sdutt3

!***********************************************************************

      subroutine sdutt(idim,v,dutt)
!***********************************************************************
!c                integrales de la loi normale de dimension quelconque  *
!c***********************************************************************
      implicit none
      integer i,j,ii,jj,n,idim,nrac,nrac0,nracmax,icor
      integer un,deux,trois,quatre
      parameter(un=1,deux=2,trois=3,quatre=4)

      real*8 prev,prev2,dif,res,tol
      parameter(nrac0=10,nracmax=30,tol=1.d-5)
      real*8 v(10),v2(10)
      real*8 s4(4),r6(6)
      real*8 :: dutt1,dutt2,dutt3,rec_dutt,dutt
      logical zero,extreme
      zero=.false.
      extreme=.false.

      icor=idim*(idim-1)/2
      do 100 i=1,idim
        if (v(i).gt.5.e0) then
          dutt=0.e0
          return
        endif
        if (abs(v(i)).gt.2.e0) extreme=.true.
        if (v(i).gt.4.e0) zero=.true.
 100  continue

      icor=idim*(idim-1)/2
      do 101 i=idim+1,idim+icor
        if (abs(v(i)).gt.0.5e0) extreme=.true.
 101  continue

!c dimension 1

      if (idim.eq.1) then
        if (v(1).lt.-5.e0) then
          dutt = 1.e0
        else
          call sdutt1(nrac0,v(1),dutt1)
          dutt=dutt1
        endif

! dimension 2

      else if (idim.eq.2) then
        if (v(1).lt.-5e0) then
          call sdutt1(nrac0,v(2),dutt1)
          dutt=dutt1
        else if (v(2).lt.-5e0) then
          call sdutt1(nrac0,v(1),dutt1)
           dutt=dutt1
        else if (zero) then
           dutt=0.e0
        else if (extreme) then
           n=0
           prev=0.e0
           do 201 nrac=nrac0,nracmax,2
             if (n.gt.1) goto 201
             call sdutt2(nrac,v(1),v(2),v(3),dutt2)
             dutt=dutt2
             dif= (dutt - prev) / dutt
             prev2 = prev
             prev = dutt
             if (abs(dif).lt.tol) n = nrac
  201      continue
           if (n.eq.0) then
             res=dutt
             if (abs(dif).gt.1.e-3) res=0.e0
             print *," -error-80- : integrals bivariate normal distribution"

!             write(6,202) v(1),v(2),v(3),prev2,dutt,res
 ! 202        format(1x," l integrale de dimension 2 avec seuils ", &
  !   &       2(d10.4)," et correlation ",d10.4," n a pu etre calculee", &
   !  &       " suffisamment precisement",/1x," avant derniere valeur", &
    ! &       " calculee:",d12.6," derniere valeur calculee:", &
     !&       d12.6," valeur retenue = ",d12.6)
             dutt=res
           endif
        else
          call sdutt2(nrac0,v(1),v(2),v(3),dutt2)
          dutt=dutt2
        endif

! dimension 3

      else if (idim.eq.3) then
        if (v(1).lt.-5e0) then
            v2(1)=v(2)
            v2(2)=v(3)
            v2(3)=v(6)
            call srec_dutt(deux,v2,rec_dutt)
            dutt=rec_dutt
        else if (v(2).lt.-5e0) then
            v2(1)=v(1)
            v2(2)=v(3)
            v2(3)=v(5)
            call srec_dutt(deux,v2,rec_dutt)
            dutt=rec_dutt
        else if (v(3).lt.-5e0) then
            v2(1)=v(1)
            v2(2)=v(2)
            v2(3)=v(4)
            call srec_dutt(deux,v2,rec_dutt)
            dutt=rec_dutt
        else if (zero) then
           dutt=0.e0
        else if (extreme) then
           n=0
           prev=0.e0
           do 301 nrac=nrac0,nracmax,2
             if (n.gt.1) goto 301
             call sdutt3(nrac,v(1),v(2),v(3),v(4),v(5),v(6),dutt3)
             dutt=dutt3
             dif= (dutt - prev) / dutt
             prev2 = prev
             prev = dutt
             if (abs(dif).lt.tol) n = nrac
  301      continue
           if (n.eq.0) then
             res=dutt
             if (abs(dif).gt.1.e-3) res=0.e0
             print *," -error-90- : integrals trivariate normal distribution"

!             write(6,302) v(1),v(2),v(3),v(4),v(5),v(6),prev2,dutt,res
 ! 302        format(1x," l integrale de dimension 3 avec seuils ", &
  !   &       3d10.4," et correlations ",3d10.4," n a pu etre calculee", &
   !  &       " suffisamment precisement",/1x," avant derniere valeur", &
    ! &       " calculee:",d12.6," derniere valeur calculee:", &
     !&       d12.6," valeur retenue = ",d12.6)
             if (dabs(dif).gt.1.e-3) dutt=0.e0
             dutt=res
           endif
        else
          call sdutt3(nrac0,v(1),v(2),v(3),v(4),v(5),v(6),dutt3)
          dutt=dutt3
        endif

      else
        write(6,10) idim
10      format(1x," dimension de l integrale ",i4," incorrecte")
        stop
      endif
      return
!***********************************************************************
      end subroutine sdutt

      subroutine srec_dutt(idim,v,rec_dutt)
!c***********************************************************************
!   rec_dutt : appel recursif de la fonction dutt sans l"instruction  *
!              "recursive function"                                   *
!***********************************************************************
      integer idim
      real*8 v(10)
      real*8 :: dutt,rec_dutt

      call sdutt(idim,v,dutt)
      rec_dutt=dutt

      return
      end subroutine srec_dutt



      subroutine sseuil1(a,seuil1)
!***********************************************************************
!     calcule le seuil de troncature d'une integrale de dimension 1    *
!      tel que   integrale de seuil1 a +inf soit egale a 'a'           *
!***********************************************************************
      implicit none
      integer i,iter
      integer un
      parameter(un=1)
      real*8 pi,rac2pi,s,a,f,fprim,v(10)
      real*8 :: dutt,seuil1
      common/pival/pi,rac2pi

      s=0.e0
      v(1)=s
      call sdutt(un,v,dutt)
      f= dutt-a

      iter = 0
      do 10  i=1,20
        if (abs(f).gt.1.e-5) then
           fprim = - exp(-0.5e0 * s * s) / rac2pi
           s = s - f / fprim
           v(1)=s
           call sdutt(un,v,dutt)
           f= dutt-a
           iter = i
        endif
  10  continue
      if (iter.eq.50) then
        print *," -error-50- : proportion of univariate normal distribution"
        stop
      else
        seuil1 = s
      endif

      return
!***********************************************************************
      end subroutine sseuil1

      subroutine sseuil2(a,s1,r,seuil2)
!***********************************************************************
!     sachant le premier seuil s1 et la correlation entre les deux     *
!     lois normales r et tel que l'integrale soit egale a 'a'          *
!***********************************************************************
      implicit none
      integer i,iter
      integer un,deux
      parameter(un=1,deux=2)
      real*8 pi,rac2pi,s1,s2,a,f,fprim,t,x,r
      real*8 v(10),v2(10)
      real*8 :: dutt,seuil1,seuil2
      common/pival/pi,rac2pi

      v(1)=s1
      call sdutt(un,v,dutt)
      x=dutt

      call sseuil1(a/x,seuil1)
      s2=seuil1

      v(2)=s2
      v(3)=r
      call sdutt(deux,v,dutt)
      f= dutt- a

      iter = 0
      do 10  i=1,20
        if (abs(f).gt.1.e-5) then
           t = (s1 - r * s2)/ sqrt(1.e0 - r * r)
           v2(1)=t
           fprim = - exp(-0.5e0 * s2 * s2) / rac2pi
           call sdutt(un,v2,dutt)
           fprim = fprim * dutt
           x =  f / min(fprim,-1.e-5)
  5        if (abs(x).gt.1.e0) then
             x = 0.5e0 * x
             goto 5
           endif
           s2 = s2 - x
           v(2)=s2
           call sdutt(deux,v,dutt)
           f= dutt-a
           iter = i
        endif
  10  continue
      if (iter.eq.50) then
        print *," -error-60- : proportion of bivariate normal distribution"
        stop
      else
        seuil2 = s2
      endif

      return
!***********************************************************************
      end subroutine sseuil2

      
      subroutine sseuil3(a,s1,s2,r12,r13,r23,seuil3)
!c***********************************************************************
!c     calcule le 3e seuil de troncature d'une integrale de dimension 3 *
!c     sachant les deux premiers seuils s1 et s2 et les correlations    *
!c     r12, r13 et r23 et tel que l'integrale soit egale a 'a'          *
!c***********************************************************************
      implicit none
      integer i,iter
      integer un,deux,trois
      parameter(un=1,deux=2,trois=3)
      real*8 v(10),v2(10),x
      real*8 pi,rac2pi,s1,s2,s3,a,f,fprim,t1,t2,r12,r13,r23,r
      real*8 :: dutt,seuil1,seuil3
      common/pival/pi,rac2pi

      v(1)=s1
      v(2)=s2
      v(3)=r12
      call sdutt(deux,v,dutt)
      x=dutt
      call sseuil1(a/x,seuil1)
      s3=seuil1
      v(3)=s3
      v(4)=r12
      v(5)=r13
      v(6)=r23
      call sdutt(trois,v,dutt)
      f= dutt-a

      iter = 0
      do 10  i=1,20
        if (abs(f).gt.1.e-5) then
           t1= (s1 - r13 * s3)/ sqrt(1.e0 - r13 * r13)
           t2= (s2 - r23 * s3)/ sqrt(1.e0 - r23 * r23)
           r = sqrt((1.e0 -r13 * r13)*(1.e0 - r23 * r23))
           r = (r12 - r13 * r23) / r
           fprim = - exp(-0.5e0 * s3 * s3) / rac2pi
           v2(1)=t1
           v2(2)=t2
           v2(3)=r
           call sdutt(deux,v2,dutt)
           fprim = fprim * dutt
           x =  f / min(fprim,-1.e-5)
           if (x.gt.1.e0) x = 1.e0
           if (x.lt.-1.e0) x = -1.e0
           s3 = s3 - x
           v(3)=s3
           call sdutt(trois,v,dutt)
           f= dutt-a
           iter = i
        endif
  10  continue
      if (iter.eq.50) then
        print *," -error-70- : proportion of trivariate normal distribution"
        stop
      else
        seuil3 = s3
      endif

      return

        end subroutine sseuil3

!c***********************************************************************


end module seltools
