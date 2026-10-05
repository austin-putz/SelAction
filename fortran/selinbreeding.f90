!     Last change:  MR   14 Sep 2000    2:09 pm
MODULE Inbreeding
IMPLICIT NONE
SAVE

CONTAINS

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

USE selroutines, ONLY: trunc
USE seltools
!USE normal_table
!USE index_pack

IMPLICIT NONE
INTEGER, INTENT(IN) :: nt,nim,nif
INTEGER, DIMENSION(nt,84), INTENT(IN) :: infom,infof
REAL, DIMENSION(nt), INTENT(IN) :: v
REAL, DIMENSION(nt,nt), INTENT(IN) :: cas,cad,cis,cid
REAL, DIMENSION(nim), INTENT(IN) :: bm
REAL, DIMENSION(nif), INTENT(IN) :: bf
REAL, INTENT(IN) :: vim,vif,pm,pf,d,rfsmm,rfsmf,rfsff,rhsmm,rhsmf,rhsff,nm,nf,m,f
INTEGER :: ii,jj,i,j
REAL, DIMENSION(nim,nt) :: Cmm,Cmf
REAL, DIMENSION(nif,nt) :: Cfm,Cff
REAL :: delf,vsa(2),half(2,1),big(2,2),Imat(2,2),glambda(2,2),gpi(2,2),bb(2),dum(2,1)
REAL :: imal,ifem,km,kf,xm,xf,ssqm,ssqf
REAL :: cSS_fsm,cSS_fsmf,cSS_fsf,cSS_hsm,cSS_hsmf,cSS_hsf

!selection parameters
call trunc(pm,xm,imal,km)
call trunc(pf,xf,ifem,kf)

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
      case (-1)
        EXIT info_sourcesm
      case (1)                                                          !own perf
        counter=counter+1
        Cmm(counter,:)=[(0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt)]       !sires
        Cmf(counter,:)=[(0.5*cas(i,k)+0.5*cad(i,k),k=1,nt)]         !dams
      case (2)                                                          !ebv dam
        counter=counter+1
        Cmm(counter,:)=[(cid(i,k)/d,k=1,nt)]
        Cmf(counter,:)=[(cid(i,k),k=1,nt)]
      case (3)                                                          !ebv sire
        counter=counter+1
        Cmm(counter,:)=[(cis(i,k),k=1,nt)]
        Cmf(counter,:)=[(cis(i,k),k=1,nt)]
      case (4:23)                                                       !full sibs
        counter=counter+1
        Cmm(counter,:)=[(0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt)]
        Cmf(counter,:)=[(0.5*cas(i,k)+0.5*cad(i,k),k=1,nt)]
      case (24:43)                                                      !half sibs
        counter=counter+1
        Cmm(counter,:)=[(0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt)]
        Cmf(counter,:)=(/ (0.5*cas(i,k),k=1,nt) /)
      case (44:63)                                                      !damhs ebv
        counter=counter+1
        Cmm(counter,:)=[(cid(i,k)/d,k=1,nt)]
        Cmf(counter,:)= 0.0
      case (64:83)                                                      !progeny
        counter=counter+1
        Cmm(counter,:)=[(0.25*cas(i,k)+0.25*cad(i,k)/d,k=1,nt)]
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
      case (-1)
        EXIT info_sourcesf
      case (1)                                                          !own perf
        counter=counter+1
        Cfm(counter,:)=[(0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt)]       !sires
        Cff(counter,:)=[(0.5*cas(i,k)+0.5*cad(i,k),k=1,nt)]         !dams
      case (2)                                                          !ebv dam
        counter=counter+1
        Cfm(counter,:)=[(cid(i,k)/d,k=1,nt)]
        Cff(counter,:)=[(cid(i,k),k=1,nt)]
      case (3)                                                          !ebv sire
        counter=counter+1
        Cfm(counter,:)=[(cis(i,k),k=1,nt)]
        Cff(counter,:)=[(cis(i,k),k=1,nt)]
      case (4:23)                                                       !full sibs
        counter=counter+1
        Cfm(counter,:)=[(0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt)]
        Cff(counter,:)=[(0.5*cas(i,k)+0.5*cad(i,k),k=1,nt)]
      case (24:43)                                                      !half sibs
        counter=counter+1
        Cfm(counter,:)=[(0.5*cas(i,k)+0.5*cad(i,k)/d,k=1,nt)]
        Cff(counter,:)=(/ (0.5*cas(i,k),k=1,nt) /)
      case (44:63)                                                      !damhs ebv
        counter=counter+1
        Cfm(counter,:)=[(cid(i,k)/d,k=1,nt)]
        Cff(counter,:)= 0.0
      case (64:83)                                                      !progeny
        counter=counter+1
        Cfm(counter,:)=[(0.25*cas(i,k)+0.25*cad(i,k)/d,k=1,nt)]
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

END MODULE inbreeding

