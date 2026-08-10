!     Last change:  MR   22 Jan 2001   10:25 am
	module discrete
        implicit none

        contains

        subroutine sel1s

        use selparameters
        use seltools
        use selroutines

	implicit none
        print *," filename? (max = 8 characters)"
        print *," "
        read *,fnam

        fnamein=trim(fnam)//".in "
        fnameout=trim(fnam)//".out"
        print *," input is written to ",fnamein
        print *," output is written to ",fnameout

        open(unit=10, file=fnamein, status="unknown", form="formatted")
        open(unit=20, file=fnameout, status="unknown", form="formatted")

        write(unit=10, fmt=*) "        1 ! stage selection"
        write(unit=10, fmt=*) " ",fnam," ! filenames"

        ! read general info
        print *," number of traits? "
        print *," "
        read *,ntraits
        write(unit=10, fmt=11001) ntraits

        allocate(sigmaa(ntraits), sigmap(ntraits))
        allocate(sigmaas(ntraits), sigmac(ntraits),sigmaad(ntraits))
        allocate(sigmaaw(ntraits), sigmae(ntraits))
        allocate(covipi(ntraits), hs(ntraits,ntraits))
        allocate(covapiq(ntraits,ntraits), covapaq(ntraits,ntraits))
        allocate(phcorr(ntraits,ntraits), gcorr(ntraits,ntraits))
        allocate(ccorr(ntraits,ntraits), ecorr(ntraits,ntraits))
        allocate(hh(ntraits), cc(ntraits), ccprog(ntraits))
        allocate(response(ntraits), tempev(ntraits,1))
        allocate(xtraits(ntraits), progsigmac(ntraits))
        allocate(fs(ntraits,ntraits))
        allocate(covp(ntraits,ntraits), covas(ntraits,ntraits),covad(ntraits,ntraits))
        allocate(covaw(ntraits,ntraits), covc(ntraits,ntraits),cove(ntraits,ntraits))

        allocate(scovapi(ntraits), scovipi(ntraits))
        allocate(scovapiq(ntraits,ntraits), scovapaq(ntraits,ntraits))
	allocate(spheninfo(ntraits), s(ntraits,ntraits))
        allocate(sresponse(ntraits), d(ntraits,ntraits))
        allocate(sdesttraits(ntraits))
	allocate(posgcorr(ntraits), covcprog(ntraits,ntraits))
	allocate(scovp(ntraits,ntraits), scovas(ntraits,ntraits), scovad(ntraits,ntraits))
        allocate(scovaw(ntraits,ntraits), scovc(ntraits,ntraits), scove(ntraits,ntraits))

        allocate(dcovapi(ntraits), dcovipi(ntraits))
        allocate(dcovapiq(ntraits,ntraits), dcovapaq(ntraits,ntraits))
        allocate(dpheninfo(ntraits), sproginfo(ntraits), dproginfo(ntraits))
        allocate(dresponse(ntraits))
        allocate(ddesttraits(ntraits))
        allocate(dcovp(ntraits,ntraits), dcovas(ntraits,ntraits),dcovad(ntraits,ntraits))
        allocate(dcovaw(ntraits,ntraits), dcovc(ntraits,ntraits),dcove(ntraits,ntraits))
        allocate(sits(ntraits), dits(ntraits), sits2(ntraits), dits2(ntraits))
        allocate(sits3(ntraits), dits3(ntraits), sitst(ntraits), ditst(ntraits))

	! group arrays (dimension 20) are only populated for p=1..hsgroups/
	! fsgroups/proggroups by the read loops below; selection_index in
	! selroutines.f90 unconditionally sums/indexes the full 20 elements,
	! so unused slots must be zeroed here rather than left uninitialized.
	fsgroupsoff=0.0
	hsgroupsoff=0.0
	hsgroupsdams=0.0
	proggroupsdams=0.0
	proggroupsoffs=0.0
	proggroupsoffd=0.0

	! economic values in temparray set to zero
	do i=1,ntraits
	  tempev(i,1)=0
	  spheninfo(i)="n"
	  dpheninfo(i)="n"
          posgcorr(i)="n"
	end do

        ! get trait information
630     print *, " use different indices or information sources for sires and dams? y/n"
        print *," "
        read *,indexdiff
        write(unit=10, fmt=11002) indexdiff
        nstag=0
        call traitinfo 	! for sires
        if (indexdiff.eq."y") then
          call traitinfo2     ! for dams
        else
          do i=1,ntraits
            ddesttraits(i)=sdesttraits(i)
          end do
        end if

 	! check number of breeding goal traits
	if (totalh.lt.1) then
	  print *," the breeding goal must contain 1 trait minimum!"
	  print *," start over please"
	  goto 630
	end if

        ! create vector with economic values
        allocate(ev(totalh,1))
        j=0
        do i=1,ntraits
          if (tempev(i,1).ne.0) then
            j=j+1
            ev(j,1)=tempev(i,1)
          end if
        end do

800	print *," use of common environmental effects? (y/n):"
        print *," "
	read *,initc
        write(unit=10, fmt=11003) initc
	if (initc.eq."y") then
	  print *," use of com.env.effects enabled"
	else if (initc.eq."n") then
	  print *," use of com.env.effects disabled"
	  do p=1,ntraits
	    cc(p)=0
	  end do
	else
          print *," wrong input!"
	  goto 800
	end if

	! read trait parameters
	do p=1,ntraits
	  print *," phenotypic variance for ",xtraits(p)," ?"
          print *," "
	  read *,sigmap(p)
          write(unit=10, fmt=11004) sigmap(p),xtraits(p)

900	  print *," heritability = h-square for ",xtraits(p)," ?"
          print *," "
	  read *,hh(p)
          write(unit=10, fmt=11005) hh(p),xtraits(p)

	  if (hh(p).le.0) then
	    print *," wrong input, heritability must be higher than 0!"
	    goto 900
	  else if (hh(p).ge.1) then
	    print *," wrong input, heritability must be lower than 1!"
	    goto 900
	  else
	    print *," "
	  end if

          cc(p)=0
          if (initc.eq."y") then
950         print *," common environmental effect = c-square for ",xtraits(p)," ?"
            print *," "
            read *,cc(p)
            write(unit=10, fmt=11006) cc(p),xtraits(p)

            if (cc(p).lt.0) then
              print *," wrong input, com.env.effect must be higher than 0!"
              goto 950
            else if (cc(p).ge.1) then
              print *," wrong input, com.env.effect must be lower than 1!"
              goto 950
            else
              print *," "
            end if

	    if (cc(p)+hh(p).ge.1) then
	      print *," heritability + com.env.effect must be lower than 1!"
	      goto 900
	    end if
	  end if
        end do

        ! read number of fs-, hs- and progeny groups
        print *," use full-sib groups ? y/n"
        print *," "
        read *,initfs
        write(unit=10, fmt=*) "        ",initfs," ! full-sib groups ?"
        if (initfs.eq."y") then
          print *," number of full-sib groups ? max=20"
          print *," "
          read *,fsgroups
          write(unit=10, fmt='(i10,a21)') fsgroups," ! number of fsgroups"
          do p=1,fsgroups
            print *," number of animals in full-sib group ",p
            print *," "
            read *,fsgroupsoff(p)
            write(unit=10, fmt='(f10.3,a31,i3)') fsgroupsoff(p)," ! number of animals in fsgroup",p
          end do
        end if
        print *," use half-sib groups ? y/n"
        print *," "
        read *,iniths
        write(unit=10, fmt=*) "        ",iniths," ! half-sib groups ?"
        if (iniths.eq."y") then
          print *," number of half-sib groups ? max=20"
          print *," "
          read *,hsgroups
          write(unit=10, fmt='(i10,a21)') hsgroups," ! number of hsgroups"
          do p=1,hsgroups
            print *," number of dams producing animals in half-sib group ",p
            print *," "
            read *,hsgroupsdams(p)
            write(unit=10, fmt='(f10.3,a29,i3)') hsgroupsdams(p)," ! number of dams in hsgroup ",p
            print *," number of animals in half-sib group ",p
            print *," "
            read *,hsgroupsoff(p)
            write(unit=10, fmt='(f10.3,a31,i3)') hsgroupsoff(p)," ! number of animals in hsgroup",p
          end do
        end if
        print *," use progeny groups ? y/n"
        print *," "
        read *,initprog
        write(unit=10, fmt=*) "        ",initprog," ! progeny groups ?"
        if (initprog.eq."y") then
          print *," number of progeny groups ? max=20"
          print *," "
          read *,proggroups
          write(unit=10, fmt='(i10,a23)') proggroups," ! number of proggroups"
          print *," "
          do p=1,proggroups
            print *," number of dams producing animals in progeny group ",p
            print *," "
            read *,proggroupsdams(p)
            write(unit=10, fmt='(f10.3,a30,i3)') proggroupsdams(p)," ! number of dams in proggroup",p
!            print *," if candidate is male :"
            print *," "
            print *," number of animals in progeny group ",p
            print *," "
            read *,proggroupsoffs(p)
            write(unit=10, fmt='(f10.3,a33,i3)') proggroupsoffs(p)," ! number of animals in proggroup",p
 !           print *," if candidate is female :"
  !          print *," "
   !         print *,"number of animals in progeny group ",p
            print *," "
            proggroupsoffd(p)=proggroupsoffs(p)/proggroupsdams(p)
     !       read *,proggroupsoffd(p)
      !      write(unit=10, fmt='(f10.3,a33,i3)') proggroupsoffd(p)," ! number of animals in proggroup",p
          end do
        end if

        ! initialise source array
        allocate(stempsource(ntraits,84), dum4(ntraits,84))
        allocate(stempsource4(ntraits,84))
        allocate(dtempsource4(ntraits,84))
        allocate(dtempsource(ntraits,84))
        stempsource=0
        stempsource4=0
        dtempsource=0
        dtempsource4=0

	! initialize information source counter
	do p=1,ntraits
	  sits(p)=0
	  dits(p)=0
	end do

        ! input of information sources
        initindsel="s"
        do p=1,ntraits ! first sires
          if (sdesttraits(p).eq."i" .or. sdesttraits(p).eq."b") then
            nstag=0
	    call info_sources(p,xtraits(p),stempsource,sits(p),dum4,dum5, &
             & spheninfo(p),sproginfo(p),initindsel,indexdiff,ntraits, &
             & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams,hsgroupsoff, &
             & proggroupsdams,proggroupsoffs,nstag)
 	  end if
        end do

        if (indexdiff.eq."y") then
          initindsel="d"
          do p=1,ntraits ! then dams
            if (ddesttraits(p).eq."i" .or. ddesttraits(p).eq."b") then
	      call info_sources(p,xtraits(p),dtempsource,dits(p),dum4,dum5, &
               & dpheninfo(p),dproginfo(p),initindsel,indexdiff,ntraits, &
               & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams,hsgroupsoff, &
               & proggroupsdams,proggroupsoffd,nstag)
	    end if
          end do
        else
          do p=1,ntraits
            dits(p)=sits(p)
	    dpheninfo(p)=spheninfo(p)
	    dproginfo(p)=sproginfo(p)
	    do q=1,84
	      dtempsource(p,q)=stempsource(p,q)
	    end do
          end do
        end if

  !      PRINT *,"tempsource s",stempsource
   !     PRINT *,"tempsource d",dtempsource
    !    PRINT *,"pheninfo s",spheninfo
     !   PRINT *,"pheninfo d",dpheninfo

	! read correlations
975	do i=1,ntraits
	  do j=1,ntraits
	    if (j.gt.i) then
1000	      print *," correlations between ",xtraits(i)," and ",xtraits(j)," ?"
	      print *," phenotypic ?"
              print *," "
  	      read *,phcorr(i,j)
              write(unit=10, fmt=11007) phcorr(i,j),xtraits(i),xtraits(j)

              if (phcorr(i,j).le.-1 .or. phcorr(i,j).ge.1) then
                print *," wrong input!"
                goto 1000
              end if
	      print *," genetic ?"
              print *," "
	      read *,gcorr(i,j)
              write(unit=10, fmt=11008) gcorr(i,j),xtraits(i),xtraits(j)

              if (gcorr(i,j).le.-1 .or. gcorr(i,j).ge.1) then
                print *,"wrong input!"
                goto 1000
              end if
              if (initc.eq."y") then
	        print *," common environmental ?"
                print *," "
    	        read *,ccorr(i,j)
                write(unit=10, fmt=11009) ccorr(i,j),xtraits(i),xtraits(j)

                if (ccorr(i,j).le.-1 .or. ccorr(i,j).ge.1) then
                  print *," wrong input!"
                  goto 1000
                end if
              end if
	    end if
	  end do
	end do

	! setup correlations between traits
	do i=1,ntraits
	  do j=1,ntraits
	    if (i.eq.j) then
	      phcorr(i,j)=1
	      gcorr(i,j)=1
              ccorr(i,j)=1
	    else if (j.gt.i) then
              phcorr(j,i)=phcorr(i,j)
              gcorr(j,i)=gcorr(i,j)
              ccorr(j,i)=ccorr(i,j)
	    else
	      continue
	    end if
	  end do
	end do

        ! get selection information
1200	print *," number of selected sires? "
        print *," "
	read *,nsires
        write(unit=10, fmt=11011) nsires
        print *," number of selected dams? "
        print *," "
	read *,ndams
        write(unit=10, fmt=11012) ndams
        print *," number of male selection candidates per dam? "
        print *," "
	read *,noffs
        write(unit=10, fmt=11021) noffs
        print *," number of female selection candidates per dam? "
        print *," "
	read *,noffd
        write(unit=10, fmt=11028) noffd
        print *," proportion selected sires? "
        print *," "
        read *,pvals                                   !formats checken=========
        write(unit=10, fmt=11013) pvals
        print *," proportion selected dams? "
        print *," "
        read *,pvald
        write(unit=10, fmt=11019) pvald
        neffdams=ndams/nsires

        ! check info sources if mating ratio = 1
        initnotematrat="n"
        if (nsires.eq.ndams) then
          do p=1,ntraits
            spheninfo(p)="n"
            dpheninfo(p)="n"
          end do
          do p=1,ntraits
            i=0
            do q=1,sits(p)
              if (stempsource(p,q).ge.24 .and. stempsource(p,q).le.63) then
                initnotematrat="y"
              else
                i=i+1
                stempsource4(p,i)=stempsource(p,q)
                if (stempsource(p,q).eq.1) then
                  spheninfo(p)="y"
                else if (stempsource(p,q).ge.4 .and. stempsource(p,q).le.23) then
                  spheninfo(p)="y"
                else if (stempsource(p,q).ge.64 .and. stempsource(p,q).le.83) then
                  spheninfo(p)="y"
                else
                  continue
                end if
              end if
            end do
            do q=1,84
              if (q.le.i) then
                stempsource(p,q)=stempsource4(p,q)
              else
                stempsource(p,q)=0
              end if
            end do
            sits(p)=i
          end do
          if (indexdiff.eq."y") then
            do p=1,ntraits
              i=0
              do q=1,dits(p)
                if (dtempsource(p,q).ge.24 .and. dtempsource(p,q).le.63) then
                  initnotematrat="y"
                else
                  i=i+1
                  dtempsource4(p,i)=dtempsource(p,q)
                  if (dtempsource(p,q).eq.1) then
                    dpheninfo(p)="y"
                  else if (dtempsource(p,q).ge.4 .and. dtempsource(p,q).le.23) then
                    dpheninfo(p)="y"
                  else if (dtempsource(p,q).ge.64 .and. dtempsource(p,q).le.83) then
                    dpheninfo(p)="y"
                  else
                    continue
                  end if
                end if
              end do
              do q=1,84
                if (q.le.i) then
                  dtempsource(p,q)=dtempsource4(p,q)
                else
                  dtempsource(p,q)=0
                end if
              end do
              dits(p)=i
            end do
          else
            do p=1,ntraits
              do q=1,84
                dtempsource(p,q)=stempsource(p,q)
              end do
              dpheninfo(p)=spheninfo(p)
              dits(p)=sits(p)
            end do
          end if
        end if
        if (initnotematrat.eq."y") then
          call note_matrat
        end if

        ! check if traits without phenotypic infosources are correlated with
	! traits which do have phenotypic infosources
	if (indexdiff.eq."y") then   ! check sires and dams
1100   	  do i=1,ntraits
	    if (spheninfo(i).eq."n" .and. dpheninfo(i).eq."n") then
	      do j=1,ntraits
	        if (spheninfo(j).eq."y" .or. dpheninfo(j).eq."y") then
	          if (gcorr(i,j).ne.0.0) then
	            posgcorr(i)="y"
	          end if
	        end if
	      end do
	      if (posgcorr(i).eq."n") then
	        call note_pheninfo(xtraits(i),pheninfoinit)
	        if (pheninfoinit.eq."i") then
                  print *," change sire or dam information sources s/d ?"
                  print *," "
                  read *,sourcesd
                  write(unit=10, fmt=11010) sourcesd
                  if (sourcesd.eq."s") then
                    initindsel="s"
	            call info_sources(i,xtraits(i),stempsource,sits(i),dum4,dum5, &
                      & spheninfo(i), &
                      & sproginfo(i),initindsel,indexdiff,ntraits,fsgroups,hsgroups, &
                      & proggroups,fsgroupsoff,hsgroupsdams,hsgroupsoff,proggroupsdams, &
                      & proggroupsoffs,nstag)
	            goto 1100
	          else
                    initindsel="d"
	            call info_sources(i,xtraits(i),dtempsource,dits(i),dum4,dum5,&
                      & dpheninfo(i), &
                      & dproginfo(i),initindsel,indexdiff,ntraits,fsgroups,hsgroups, &
                      & proggroups,fsgroupsoff,hsgroupsdams,hsgroupsoff,proggroupsdams, &
                      & proggroupsoffd,nstag)
                    goto 1100
	          end if
	        else if (pheninfoinit.eq."c") then
	          do p=1,ntraits
	            if (spheninfo(p).eq."y" .or. dpheninfo(p).eq."y") then
	              if (p.gt.i) then
	                print *," genetic correlation between:",xtraits(i),"and ",xtraits(p)
	                print *," was: ",gcorr(i,p)
	                print *," new value:"
                        print *," "
                        read *,gcorr(i,p)
                        write(unit=10, fmt=11008) gcorr(i,p),xtraits(i),xtraits(p)
                        gcorr(p,i)=gcorr(i,p)
	                goto 1175
	              else if (i.gt.p) then
	                print *," genetic correlation between:",xtraits(i),"and ",xtraits(p)
                        print *," was: ",gcorr(i,p)
                        print *," new value:"
                        print *," "
                        read *,gcorr(p,i)
                        write(unit=10, fmt=11008) gcorr(p,i),xtraits(p),xtraits(i)
                        gcorr(i,p)=gcorr(p,i)
                        goto 1175
	              else
	                continue
	              end if
	            end if
	          end do
	        else
	          continue
	        end if
1175	      end if
	    end if
          end do
        else    ! check sires
1180	  do i=1,ntraits
	    if (spheninfo(i).eq."n") then
	      do j=1,ntraits
	        if (spheninfo(j).eq."y") then
	          if (gcorr(i,j).ne.0.0) then
	            posgcorr(i)="y"
	          end if
	        end if
	      end do
       	      if (posgcorr(i).eq."n") then
	        call note_pheninfo(xtraits(i),pheninfoinit)
	        if (pheninfoinit.eq."i") then
                  initindsel="n"
	          call info_sources(i,xtraits(i),stempsource,sits(i),dum4,dum5, &
                    & spheninfo(i), &
                    & sproginfo(i),initindsel,indexdiff,ntraits,fsgroups,hsgroups, &
                    & proggroups,fsgroupsoff,hsgroupsdams,hsgroupsoff,proggroupsdams, &
                    & proggroupsoffs,nstag)
	          dits(i)=sits(i)
	          dpheninfo(i)=spheninfo(i)
	          dproginfo(i)=sproginfo(i)
	          do q=1,84
	            dtempsource(i,q)=stempsource(i,q)
	          end do
	          goto 1180
	        else if (pheninfoinit.eq."c") then
	          do p=1,ntraits
	            if (spheninfo(p).eq."y") then
	              if (p.gt.i) then
	                print *," genetic correlation between:",xtraits(i),"and ",xtraits(p)
	                print *," was: ",gcorr(i,p)
	                print *," new value:"
                        print *," "
                        read *,gcorr(i,p)
                        write(unit=10, fmt=11008) gcorr(i,p),xtraits(i),xtraits(p)
                        gcorr(p,i)=gcorr(i,p)
	                goto 1190
	              else if (i.gt.p) then
	                print *," genetic correlation between:",xtraits(i),"and ",xtraits(p)
                        print *," was: ",gcorr(i,p)
                        print *," new value:"
                        print *," "
                        read *,gcorr(p,i)
                        write(unit=10, fmt=11008) gcorr(p,i),xtraits(p),xtraits(i)
                        gcorr(i,p)=gcorr(p,i)
	                goto 1190
	              else
	                continue
	              end if
	            end if
	          end do
	        else
	          continue
	        end if
1190	      end if
            end if
	  end do
        end if

	! get dimension for real p-matrix
	ssumits=0
	dsumits=0
	do p=1,ntraits
	  if (sdesttraits(p).eq."i" .or. sdesttraits(p).eq."b") then
	    ssumits=ssumits+(sits(p)-1)
	  end if
	  if (ddesttraits(p).eq."i" .or. ddesttraits(p).eq."b") then
	    dsumits=dsumits+(dits(p)-1)
	  end if
	end do
    !    print *,"ssumits ",ssumits
     !   print *,"dsumits ",dsumits

        ! get progeny testing information
        if (initprog.eq."y" .and. initc.eq."y") then
          do q=1,ntraits
960         print *," common environmental effect in the progeny test"
            print *," = c-square for ",xtraits(q)," ?"
            print *," "
            read *,ccprog(q)
            write(unit=10, fmt=11016) ccprog(q),xtraits(q)
            if (ccprog(q).le.0) then
              print *," wrong input, com.env.effect must be higher than 0!"
              goto 960
            else if (ccprog(q).ge.1) then
              print *," wrong input, com.env.effect must be lower than 1!"
              goto 960
            else
              continue
            end if
          end do
        end if

        ! get truncation points
        call trunc(pvals,dum1,dum2,is,ks)
        call trunc(pvald,dum1,dum2,id,kd)

  !	print *,"ks is",ks,is
   !	print *,"kd id",kd,id

        allocate(sb(ssumits,1), db(dsumits,1), sinvp(ssumits,ssumits))
        allocate(spartrealg(ssumits,1), dpartrealg(dsumits,1), dinvp(dsumits,dsumits))
        allocate(stempcov1(ssumits,1), stempcov2(ssumits,1), srealg(ssumits,ntraits))
        allocate(dtempcov1(dsumits,1), dtempcov2(dsumits,1), drealg(dsumits,ntraits))
    !	  print *,"allocaten gaat goed"

        ! variance starting values
        ssigmai=0.0
        do p=1,ntraits
	  sigmaa(p)=hh(p)*sigmap(p)
	  sigmac(p)=cc(p)*sigmap(p)
          progsigmac(p)=ccprog(p)*sigmap(p)
	  sigmaas(p)=0.25*sigmaa(p)
          sigmaad(p)=0.25*sigmaa(p)
	  sigmaaw(p)=0.5*sigmaa(p)
          sigmae(p)=sigmap(p)-sigmaa(p)-sigmac(p)
          if (sdesttraits(p).eq."h" .or. sdesttraits(p).eq."b") then
            temp3sigmai=hh(p)*sigmaa(p)*tempev(p,1)*tempev(p,1)
            ssigmai=ssigmai+temp3sigmai
          end if
      !    print *,"ssigmai",ssigmai
          if (indexdiff.eq."y") then
            if (ddesttraits(p).eq."h" .or. ddesttraits(p).eq."b") then
              temp3sigmai=hh(p)*sigmaa(p)*tempev(p,1)*tempev(p,1)
              dsigmai=dsigmai+temp3sigmai
            end if
          else
            dsigmai=ssigmai
          end if
	end do
        ssigmai=ssigmai*(1-ks)
        dsigmai=dsigmai*(1-kd)
     !	print *,"varianties zijn goed"

	! covariance starting values
	do p=1,ntraits
          do q=1,ntraits
            scovapi(q)=hh(q)*tempev(q,1)*sigmaa(q)
            dcovapi(q)=scovapi(q)
            covipi(q)=hh(q)*tempev(q,1)*sigmaa(q)
	    covp(p,q)=phcorr(p,q)*(sqrt(sigmap(p))*sqrt(sigmap(q)))
	    covas(p,q)=gcorr(p,q)*(sqrt(sigmaas(p))*sqrt(sigmaas(q)))
	    covad(p,q)=gcorr(p,q)*(sqrt(sigmaad(p))*sqrt(sigmaad(q)))
       	    covaw(p,q)=gcorr(p,q)*(sqrt(sigmaaw(p))*sqrt(sigmaaw(q)))
            covc(p,q)=ccorr(p,q)*(sqrt(sigmac(p))*sqrt(sigmac(q)))
      !      print *,"covc",p,q,covc
            covcprog(p,q)=ccorr(p,q)*(sqrt(progsigmac(p))*sqrt(progsigmac(q)))

            genpart=((sqrt(hh(p)))*(sqrt(hh(q)))*gcorr(p,q))
            comenvpart=((sqrt(cc(p)))*(sqrt(cc(q)))*ccorr(p,q))
            errpart=(sqrt(1-hh(p)-cc(p))*sqrt(1-hh(q)-cc(q)))
 	    ecorr(p,q)=(phcorr(p,q)-genpart-comenvpart)/errpart

	    cove(p,q)=ecorr(p,q)*(sqrt(sigmae(p))*sqrt(sigmae(q)))
 	    covapiq(p,q)=hh(q)*gcorr(p,q)*(sqrt(sigmaa(p))*(sqrt(sigmaa(q))))
            covapaq(p,q)=gcorr(p,q)*(sqrt(sigmaa(p))*(sqrt(sigmaa(q))))
            fs(p,q)=covas(p,q)+covad(p,q)+covc(p,q)
            hs(p,q)=covas(p,q)
            s(p,q)=covapiq(p,q)-((scovapi(p)*covipi(q)*ks)/ssigmai)
            d(p,q)=covapiq(p,q)-((dcovapi(p)*covipi(q)*kd)/dsigmai)
          end do
        end do
  !  	print *,"covarianties zijn goed"
!        print *,"covapiq",covapiq
 !       print *,"scovapi",scovapi
  !      print *,"covipi",covipi
   !     print *,"ks",ks
    !    print *,"s",s
     !   print *,"d",d

        close(unit=10)

        ! index calculations
        selrounds=25
        response=0
        do p=1,selrounds
          initindsel="s"
   	  call selection_index(ntraits,ssigmai,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,scovapi,ssumits,sdesttraits,sits,stempsource,sresponse, &
            & stotalresponse,srih,srealg,sb,sinvp,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvals,nsires,neffdams,noffs,scorrfs,scorrhs, &
            & fsgroups,hsgroups,proggroups)
          initindsel="d"
          call selection_index(ntraits,dsigmai,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,dcovapi,dsumits,ddesttraits,dits,dtempsource,dresponse, &
            & dtotalresponse,drih,drealg,db,dinvp,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvald,nsires,neffdams,noffd,dcorrfs,dcorrhs, &
            & fsgroups,hsgroups,proggroups)
          call covariance_update(ntraits,ssigmai,dsigmai,covp,covas,covad, &
            & covaw,covc,cove,covapaq,ssumits,sits,sresponse,stotalresponse,srealg, &
            & sb,sinvp,dsumits,dits,dresponse,dtotalresponse,drealg,db,dinvp,ks,kd, &
            & response,totalresponse,tempev,scovapi,dcovapi,fs,hs,s,d)
!        print *,'totalresponse',(totalresponse)
        end do

        call intra_sd(ntraits,ssigmai,dsigmai,covp,covas,covad,covaw,covc,cove,covapaq, &
          & ssumits,dsumits,sdesttraits,ddesttraits,sits,dits,stempsource,dtempsource,sb, &
          & db,fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd, &
          & hsgroupsdams,proggroupsdams,covcprog,sdcorrfs,sdcorrhs, &
          & fsgroups,hsgroups,proggroups)


      !  dFmtblup(nt,nim,nif,infom,infof,v,cas,cad,cis,cid,pm,pf,d,&
       !       & bm,bf,vim,vif,rfsmm,rfsmf,rfsff,rhsmm,rhsmf,rhsff,nm,nf,m,f)

        dF=dFmtblup(ntraits,ssumits,dsumits,stempsource,dtempsource,tempev,covas*4, &
           &  covad*4,s,d,pvals,pvald,neffdams,sb,db,ssigmai,dsigmai, &
           &  scorrfs,sdcorrfs,dcorrfs,scorrhs,sdcorrhs,dcorrhs,noffs,noffd,nsires,ndams)




    !    print *,covp(1,1)," = covp"
     !   print *,covas(1,1)," = covas"
      !  print *,covad(1,1)," = covad"
       ! print *,covaw(1,1)," = covaw"
        !print *,cove(1,1)," = cove"
        !print *,covapaq(1,1)," = covapaq"


	! print output
        call intro(2)

        ! print trait information
        write(unit=20, fmt=*) " TRAITS"
        write(unit=20, fmt=*) " "
        do p=1,ntraits
	  write(unit=20, fmt=*) "   ",xtraits(p)
        end do
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "

        ! print trait parameters
        write(unit=20, fmt=*) "  TRAIT PARAMETERS"
        write(unit=20, fmt=*) "  "
        if (initc.eq."y") then
          write(unit=20, fmt=*) "       phenotypic variance  heritability  com.env.effect"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3,8x,f8.3)') xtraits(p),sigmap(p),hh(p),cc(p)
          end do
        else
          write(unit=20, fmt=*) "       phenotypic variance  heritability"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3)') xtraits(p),sigmap(p),hh(p)
          end do
        end if
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "

        if (ntraits.gt.1) then
          ! print phenotypic correlations
          write(unit=20, fmt=*) "  PHENOTYPIC CORRELATIONS"
          write(unit=20, fmt=*) "  "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),(phcorr(p,j), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print genetic correlations
          write(unit=20, fmt=*) "  GENETIC CORRELATIONS"
          write(unit=20, fmt=*) "  "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),(gcorr(p,j), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print common environmental correlations
          if (initc.eq."y") then
            write(unit=20, fmt=*) "  COMMON ENVIRONMENTAL CORRELATIONS"
            write(unit=20, fmt=*) "  "
            write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
            do p=1,ntraits
              write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),(ccorr(p,j), j=1,p)
            end do
          end if
          write(unit=20, fmt=*) " "
          write(unit=20, fmt=*) " "
        end if

        ! print breeding goal information
        write(unit=20, fmt=*) " BREEDING GOAL INFORMATION"
        write(unit=20, fmt=*) " "
        do p=1,ntraits
	  if (sdesttraits(p).eq."h" .or. sdesttraits(p).eq."b") then
	    write(unit=20, fmt=11018) tempev(p,1),xtraits(p)
          end if
        end do
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "

        ! print population parameters
        write(unit=20, fmt=*) "  POPULATION SIZE"
        write(unit=20, fmt=*) "  "
        write(unit=20, fmt='(a42,f8.3)') "               number of selected sires : ",nsires
        write(unit=20, fmt='(a42,f8.3)') "                number of selected dams : ",ndams
        write(unit=20, fmt='(a42,f8.3)') " number of male selection candidates per dam   : ",noffs
        write(unit=20, fmt='(a42,f8.3)') " number of female selection candidates per dam : ",noffd
        write(unit=20, fmt=*) " "
        write(unit=20, fmt='(a29,f5.3)') " selected proportion sires : ",pvals
        write(unit=20, fmt='(a29,f5.3)') "  selected proportion dams : ",pvald
        write(unit=20, fmt=*) " "
        if (fsgroups.gt.0 .or. hsgroups.gt.0 .or. proggroups.gt.0) then
          write(unit=20, fmt=*) " CHARACTERISTICS OF THE USED GROUPS"
          write(unit=20, fmt=*) " "
        end if

        do i=1,fsgroups
          write(unit=20, fmt=*) " full-sib group ",i," with ",fsgroupsoff(i)," animals"
        end do
        do i=1,hsgroups
          write(unit=20, fmt=*) " half-sib group ",i," with ",hsgroupsdams(i)," dams, producing ",hsgroupsoff(i),"animals"
        end do
        if (proggroups.gt.0) then
          write(unit=20, fmt=*) " progeny group information"
          do i=1,proggroups
            write(unit=20, fmt=*) " progeny group ",i," with ",proggroupsdams(i)," dams, producing",proggroupsoffs(i),"progeny"
          end do
!          write(unit=20, fmt=*) " progeny group information for dams"
 !         do i=1,proggroups
  !          write(unit=20, fmt=*) " progeny group ",i," with 1 dam, producing",proggroupsoffd(i),"progeny"
   !       end do
        end if

        ! print index information
 	i=0
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "
        if (indexdiff.eq."y") then
          write(unit=20, fmt=*) " INDEX INFORMATION FOR SIRES :"
        else
          write(unit=20, fmt=*) " INDEX INFORMATION"
        end if
        write(unit=20, fmt=*) " "
    	xsource(1)="own performance"
     	xsource(2)="ebv of the dam"
        xsource(3)="ebv of the sire"
        do p=4,23
          xsource(p)="information of fs-group "
        end do
        do p=24,43
          xsource(p)="information of hs-group "
        end do
        do p=44,63
          xsource(p)="mean ebv of the dams of hs-group "
        end do
        do p=64,83
          xsource(p)="information of progeny group "
        end do
      	do p=1,ntraits
       	  if (sdesttraits(p).eq."i" .or. sdesttraits(p).eq."b") then
	    do q=1,sits(p)-1
	      i=i+1
              if (stempsource(p,q).le.3) then
      	        write(unit=20, fmt=11000) xsource(stempsource(p,q)),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.4 .and. stempsource(p,q).le.23) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-3),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.24 .and. stempsource(p,q).le.43) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-23),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.44 .and. stempsource(p,q).le.63) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-43),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.64 .and. stempsource(p,q).le.83) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-63),xtraits(p), &
                  & sb(i,1)
              else
                continue
              end if
            end do
      	    write(unit=20, fmt=*) " "
       	  end if
     	end do
        if (indexdiff.eq."y") then
          i=0
	  write(unit=20, fmt=*) " INDEX INFORMATION FOR DAMS:"
	  write(unit=20, fmt=*) " "
          do p=1,ntraits
	    if (ddesttraits(p).eq."i" .or. ddesttraits(p).eq."b") then
	      do q=1,dits(p)-1
	        i=i+1
                if (dtempsource(p,q).le.3) then
       	          write(unit=20, fmt=11000) xsource(dtempsource(p,q)),xtraits(p), &
                    & db(i,1)
                else if (dtempsource(p,q).ge.4 .and. dtempsource(p,q).le.23) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-3,xtraits(p), &
                    & db(i,1)
                else if (dtempsource(p,q).ge.24 .and. dtempsource(p,q).le.43) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-23,xtraits(p), &
                    & db(i,1)
                else if (dtempsource(p,q).ge.44 .and. dtempsource(p,q).le.63) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-43,xtraits(p), &
                    & db(i,1)
                else if (dtempsource(p,q).ge.64 .and. dtempsource(p,q).le.83) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-63,xtraits(p), &
                    & db(i,1)
                else
                  continue
                end if
      	      end do
       	      write(unit=20, fmt=*) " "
	    end if
      	  end do
        end if
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) "             ******************   RESULTS   *******************"
        write(unit=20, fmt=*) " "
        print *, "             ******************   RESULTS   *******************"
        print *, " "

        ! print equilibrium parameters
        write(unit=20, fmt=*) " EQUILIBRIUM PARAMETERS"
        write(unit=20, fmt=*) " "
        if (initc.eq."y") then
          write(unit=20, fmt=*) "       phenotypic variance  heritability  com.env.effect"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3,8x,f8.3)') xtraits(p),covp(p,p),(covapaq(p,p)/covp(p,p)),(covc(p,p)/covp(p,p))
          end do
        else
          write(unit=20, fmt=*) "       phenotypic variance  heritability"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3)') xtraits(p),covp(p,p),(covapaq(p,p)/covp(p,p))
          end do
        end if
        write(unit=20, fmt=*) " "

        if (ntraits.gt.1) then
          ! print phenotypic correlations
          write(unit=20, fmt=*) "  PHENOTYPIC CORRELATIONS"
          write(unit=20, fmt=*) "  "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((covp(p,j)/(sqrt(covp(p,p))*sqrt(covp(j,j)))), j=1,p)
          end do
          write(unit=20, fmt=*) " "
          write(unit=20, fmt=*) " "

          ! print genetic correlations
          write(unit=20, fmt=*) "  GENETIC CORRELATIONS"
          write(unit=20, fmt=*) "  "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((covapaq(p,j)/(sqrt(covapaq(p,p))*sqrt(covapaq(j,j)))), j=1,p)
          end do
          write(unit=20, fmt=*) " "
          write(unit=20, fmt=*) " "

          ! print common environmental correlations
          if (initc.eq."y") then
            write(unit=20, fmt=*) "  COMMON ENVIRONMENTAL CORRELATIONS"
            write(unit=20, fmt=*) "  "
            write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
            do p=1,ntraits
              write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((covc(p,j)/(sqrt(covc(p,p))*sqrt(covc(j,j)))), j=1,p)
            end do
          end if
          write(unit=20, fmt=*) " "
        end if

        ! print response
        write(unit=20, fmt=*) " RESPONSE"
        write(unit=20, fmt=*) "                           sires           dams          total"
        print *, " RESPONSE"
        print *, "                           sires           dams          total"
        do p=1,ntraits
          if (sdesttraits(p).eq."b" .or. sdesttraits(p).eq."h") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*sresponse(p),0.5*dresponse(p),response(p)
            write(unit=20, fmt=11025) 0.5*sresponse(p)*tempev(p,1),0.5*dresponse(p)*tempev(p,1),response(p)*tempev(p,1)
            write(unit=20, fmt=11023) ((0.5*sresponse(p)*tempev(p,1))/totalresponse)*100, &
              & ((0.5*dresponse(p)*tempev(p,1))/totalresponse)*100, &
              & ((response(p)*tempev(p,1))/totalresponse)*100
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*sresponse(p),0.5*dresponse(p),response(p)
            print 11025, 0.5*sresponse(p)*tempev(p,1),0.5*dresponse(p)*tempev(p,1),response(p)*tempev(p,1)
            print 11023, ((0.5*sresponse(p)*tempev(p,1))/totalresponse)*100, &
              & ((0.5*dresponse(p)*tempev(p,1))/totalresponse)*100, &
              & ((response(p)*tempev(p,1))/totalresponse)*100
            print *, " "
         end if
        end do
        ! print correlated response
        do p=1,ntraits
          if (sdesttraits(p).eq."i" .or. ddesttraits(p).eq."i") then
            write(unit=20, fmt=*) " CORRELATED RESPONSE"
            write(unit=20, fmt=*) "                           sires           dams          total"
            print *, " CORRELATED RESPONSE"
            print *, "                           sires           dams          total"
            goto 10010
          end if
        end do
10010   do p=1,ntraits
          if (sdesttraits(p).eq."i" .or. ddesttraits(p).eq."i") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*sresponse(p),0.5*dresponse(p),response(p)
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*sresponse(p),0.5*dresponse(p),response(p)
            print *, " "
          end if
        end do
        ! print total response
        write(unit=20, fmt=*) " TOTAL RESPONSE"
        write(unit=20, fmt=*) "                           sires           dams          total"
        write(unit=20, fmt=11025) 0.5*stotalresponse,0.5*dtotalresponse,totalresponse
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "
        print *, " TOTAL RESPONSE"
        print *, "                           sires           dams          total"
        print 11025, 0.5*stotalresponse,0.5*dtotalresponse,totalresponse
        print *, " "
        print *, " "
        if (ssigmai.ne.dsigmai) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "  index variance sires : ",ssigmai,"    index variance dams : ",dsigmai
                       print '(a25,f13.3,a26,f13.3)', "  index variance sires : ",ssigmai,"    index variance dams : ",dsigmai
        else
          write(unit=20, fmt='(a25,f13.3)') "        index variance : ",ssigmai
                       print '(a25,f13.3)', "        index variance : ",ssigmai
        end if
        write(unit=20, fmt='(a26,f13.3)') " breeding goal variance : ",sigmah
                     print '(a26,f13.3)', " breeding goal variance : ",sigmah
        if (srih.ne.drih) then
          write(unit=20, fmt='(a26,f13.3,a26,f13.3)') " accuracy of sire index : ",srih,"  accuracy of dam index : ",drih
                       print '(a26,f13.3,a26,f13.3)', " accuracy of sire index : ",srih,"  accuracy of dam index : ",drih
        else
          write(unit=20, fmt='(a25,f13.3)') "     accuracy of index : ",srih
                       print '(a25,f13.3)', "     accuracy of index : ",srih
        end if
        write(unit=20, fmt=*) " "
        print *, " "
        write(unit=20, fmt='(a26,f6.3,a16)') " increase of inbreeding : ",dF*100,"% per generation"
                     print '(a26,f6.3,a16)', " increase of inbreeding : ",dF*100,"% per generation"


        ! check for incoherent parameters
        posdefph="y"
        posdefg="y"
        allocate(jacvec(ntraits))
        call jacobi(phcorr,ntraits,jacvec)
        do p=1,ntraits
       !   print *,"jacvec(p)",jacvec(p)
          if (jacvec(p).lt.0) then
            posdefph="n"
          end if
        end do
        jacvec=0
        call jacobi(gcorr,ntraits,jacvec)
        do p=1,ntraits
       !   print *,"jacvec(p)",jacvec(p)
          if (jacvec(p).lt.0) then
            posdefg="n"
          end if
        end do
        if (posdefph.eq."n" .or. posdefg.eq."n") then
          write(unit=20, fmt=*) " ** incoherent genetic parameters detected"
          print *, " "
          print *, " ** incoherent genetic parameters detected"
        end if
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) "                      ******  end of output  ******"
        print *, " "
        print *, "                      ******  end of output  ******"

        ! format statements
	11000 format(5x,a33,"    for ",a8,"  (",f8.3,")")
        11001 format(i10," ! number of traits")
        11002 format(a10," ! different indices for sires and dams")
        11003 format(a10," ! use of common environment")
        11004 format(f10.3," ! phenotypic variance ",a8)
        11005 format(f10.3," ! heritability ",a8)
        11006 format(f10.3," ! common environmental effect ",a8)
        11007 format(f10.3," ! phenotypic correlation between ",a8," and ",a8)
        11008 format(f10.3," !    genetic correlation between ",a8," and ",a8)
        11009 format(f10.3," !   com.env. correlation between ",a8," and ",a8)
        11010 format(a10," ! sire or dam information to be changed")
        11011 format(f10.3," ! number of sires")
        11012 format(f10.3," ! number of dams")
        11013 format(f10.3," ! proportion sires")
        11014 format(f10.3," ! number of dams for progeny test")
        11015 format(f10.3," ! number of offspring per dam in progeny test")
        11016 format(f10.3," ! common environmental effect in progeny test ",a8)
        11017 format(i10," ! number of generations")
	11018 format(5x,f10.3," * ",a8)
        11019 format(f10.3," ! proportion dams")

        11020 format("         trait units : ",f10.3,5x,f10.3,5x,f10.3)
        11025 format("      economic units : ",f10.3,5x,f10.3,5x,f10.3)
        11023 format(" % of total response : ",f10.3,5x,f10.3,5x,f10.3)

        11021 format(f10.3," ! male candidates per dam")
        11028 format(f10.3," ! female candidates per dam")
	11024 format(5x,a33,i3," for ",a8,"  (",f8.3,")")

        close(unit=20)

        end subroutine sel1s

 !================================================================

        subroutine sel2s

        use selparameters
        use seltools
        use selroutines

	implicit none
        print *,"filename? (max = 8 characters)"
        print *," "
        read *,fnam

        fnamein=trim(fnam)//".in "
        fnameout=trim(fnam)//".out"
        print *,"input is written to ",fnamein
        print *,"output is written to ",fnameout

        open(unit=10, file=fnamein, status="unknown", form="formatted")
        open(unit=20, file=fnameout, status="unknown", form="formatted")

        write(unit=10, fmt=*) "        2 ! stage selection"
        write(unit=10, fmt=*) " ",fnam," ! filenames"

        ! read general info
        print *,"number of traits? "
        print *," "
        read *,ntraits
        write(unit=10, fmt=11001) ntraits

        allocate(sigmaa(ntraits), sigmap(ntraits))
        allocate(sigmaas(ntraits), sigmac(ntraits),sigmaad(ntraits))
        allocate(sigmaaw(ntraits), sigmae(ntraits))
        allocate(covipi(ntraits), hs(ntraits,ntraits))
        allocate(covapiq(ntraits,ntraits), covapaq(ntraits,ntraits))
        allocate(phcorr(ntraits,ntraits), gcorr(ntraits,ntraits))
        allocate(ccorr(ntraits,ntraits), ecorr(ntraits,ntraits))
        allocate(hh(ntraits), cc(ntraits), ccprog(ntraits))
        allocate(response(ntraits), tempev(ntraits,1))
        allocate(xtraits(ntraits), progsigmac(ntraits))
        allocate(fs(ntraits,ntraits), prs(ntraits), prd(ntraits))
        allocate(covp(ntraits,ntraits), covas(ntraits,ntraits),covad(ntraits,ntraits))
        allocate(covaw(ntraits,ntraits), covc(ntraits,ntraits),cove(ntraits,ntraits))

        allocate(scovapi(ntraits), scovipi(ntraits))
        allocate(scovapiq(ntraits,ntraits), scovapaq(ntraits,ntraits))
	allocate(spheninfo(ntraits), s(ntraits,ntraits), response2(ntraits))
        allocate(sresponse(ntraits), d(ntraits,ntraits))
        allocate(sdesttraits(ntraits), sdesttraits2(ntraits))
	allocate(posgcorr(ntraits), covcprog(ntraits,ntraits))
	allocate(scovp(ntraits,ntraits), scovas(ntraits,ntraits), scovad(ntraits,ntraits))
        allocate(scovaw(ntraits,ntraits), scovc(ntraits,ntraits), scove(ntraits,ntraits))

        allocate(dcovapi(ntraits), dcovipi(ntraits))
        allocate(dcovapiq(ntraits,ntraits), dcovapaq(ntraits,ntraits))
        allocate(dpheninfo(ntraits), sproginfo(ntraits), dproginfo(ntraits))
        allocate(dresponse(ntraits), sresponse2(ntraits), dresponse2(ntraits))
        allocate(ddesttraits(ntraits), ddesttraits2(ntraits))
        allocate(dcovp(ntraits,ntraits), dcovas(ntraits,ntraits),dcovad(ntraits,ntraits))
        allocate(dcovaw(ntraits,ntraits), dcovc(ntraits,ntraits),dcove(ntraits,ntraits))

        allocate(sresponsec(ntraits), sresponse2c(ntraits), mssresponse2c(ntraits))
        allocate(dresponsec(ntraits), dresponse2c(ntraits), msdresponse2c(ntraits))
        allocate(responsec(ntraits), response2c(ntraits), msresponse2c(ntraits))
        allocate(mssresponse2(ntraits), msdresponse2(ntraits), msresponse2(ntraits))
        allocate(v(2,2), dumv(2,2), g(2,1), beta(2,1))
        allocate(sits(ntraits), dits(ntraits), sits2(ntraits), dits2(ntraits))
        allocate(sits3(ntraits), dits3(ntraits), sitst(ntraits), ditst(ntraits))

	! group arrays (dimension 20) are only populated for p=1..hsgroups/
	! fsgroups/proggroups by the read loops below; selection_index in
	! selroutines.f90 unconditionally sums/indexes the full 20 elements,
	! so unused slots must be zeroed here rather than left uninitialized.
	fsgroupsoff=0.0
	hsgroupsoff=0.0
	hsgroupsdams=0.0
	proggroupsdams=0.0
	proggroupsoffs=0.0
	proggroupsoffd=0.0

	! economic values in temparray set to zero
	tempev=0
	spheninfo="n"
	dpheninfo="n"
        posgcorr="n"
        sdesttraits="n"
        sdesttraits2="n"
        ddesttraits="n"
        ddesttraits2="n"

        ! get trait information stage 1
630     print *, "use different indices or information sources for sires and dams? y/n"
        print *," "
        read *,indexdiff
        write(unit=10, fmt=11002) indexdiff
        nstag=1
        call traitinfo 	! for sires
        if (indexdiff.eq."y") then
          call traitinfo2     ! for dams
        else
          ddesttraits=sdesttraits
        end if
        sdesttraits2=sdesttraits
        ddesttraits2=ddesttraits

  	! check the number of breeding goal traits
	if (totalh.lt.1) then
	  print *,"the breeding goal must contain 1 trait minimum!"
	  print *,"start over please"
	  goto 630
	end if

        ! get trait information stage 2
        if (ntraits.gt.1) then
          call traitinfo3 	! for sires
          if (indexdiff.eq."y") then
            call traitinfo4     ! for dams
          else
            ddesttraits2=sdesttraits2
          end if
        else
          sdesttraits2(1)="b"
          ddesttraits2(1)="b"
        end if

          ! create vector with economic values
        allocate(ev(totalh,1))
        j=0
        do i=1,ntraits
          if (tempev(i,1).ne.0) then
            j=j+1
            ev(j,1)=tempev(i,1)
          end if
        end do

800	print *,"use of common environmental effects? (y/n):"
        print *," "
	read *,initc
        write(unit=10, fmt=11003) initc
	if (initc.eq."y") then
	  print *,"use of com.env.effects enabled"
	else if (initc.eq."n") then
	  print *,"use of com.env.effects disabled"
	  do p=1,ntraits
	    cc(p)=0
	  end do
	else
          print *,"wrong input!"
	  goto 800
	end if

	! read trait parameters
	do p=1,ntraits
	  print *,"phenotypic variance for ",xtraits(p)," ?"
          print *," "
	  read *,sigmap(p)
          write(unit=10, fmt=11004) sigmap(p),xtraits(p)

900	  print *,"heritability = h-square for ",xtraits(p)," ?"
          print *," "
	  read *,hh(p)
          write(unit=10, fmt=11005) hh(p),xtraits(p)

	  if (hh(p).le.0) then
	    print *,"wrong input, heritability must be higher than 0!"
	    goto 900
	  else if (hh(p).ge.1) then
	    print *,"wrong input, heritability must be lower than 1!"
	    goto 900
	  else
	    print *," "
	  end if

          cc(p)=0
          if (initc.eq."y") then
950         print *,"common environmental effect = c-square for ",xtraits(p)," ?"
            print *," "
            read *,cc(p)
            write(unit=10, fmt=11006) cc(p),xtraits(p)

            if (cc(p).lt.0) then
              print *,"wrong input, com.env.effect must be higher than 0!"
              goto 950
            else if (cc(p).ge.1) then
              print *,"wrong input, com.env.effect must be lower than 1!"
              goto 950
            else
              print *," "
            end if

	    if (cc(p)+hh(p).ge.1) then
	      print *,"heritability + com.env.effect must be lower than 1!"
	      goto 900
	    end if
	  end if
        end do

        ! read number of fs-, hs- and progeny groups
        print *,"use full-sib groups ? y/n"
        print *," "
        read *,initfs
        write(unit=10, fmt=*) "        ",initfs," ! full-sib groups ?"
        if (initfs.eq."y") then
          print *,"number of full-sib groups ? max=20"
          print *," "
          read *,fsgroups
          write(unit=10, fmt='(i10,a21)') fsgroups," ! number of fsgroups"
          do p=1,fsgroups
            print *,"number of animals in full-sib group ",p
            print *," "
            read *,fsgroupsoff(p)
            write(unit=10, fmt='(f10.3,a31,i3)') fsgroupsoff(p)," ! number of animals in fsgroup",p
          end do
        end if
        print *,"use half-sib groups ? y/n"
        print *," "
        read *,iniths
        write(unit=10, fmt=*) "        ",iniths," ! half-sib groups ?"
        if (iniths.eq."y") then
          print *,"number of half-sib groups ? max=20"
          print *," "
          read *,hsgroups
          write(unit=10, fmt='(i10,a21)') hsgroups," ! number of hsgroups"
          do p=1,hsgroups
            print *,"number of dams producing animals in half-sib group ",p
            print *," "
            read *,hsgroupsdams(p)
            write(unit=10, fmt='(f10.3,a29,i3)') hsgroupsdams(p)," ! number of dams in hsgroup ",p
            print *,"number of animals in half-sib group ",p
            print *," "
            read *,hsgroupsoff(p)
            write(unit=10, fmt='(f10.3,a31,i3)') hsgroupsoff(p)," ! number of animals in hsgroup",p
          end do
        end if
        print *,"use progeny groups ? y/n"
        print *," "
        read *,initprog
        write(unit=10, fmt=*) "        ",initprog," ! progeny groups ?"
        if (initprog.eq."y") then
          print *,"number of progeny groups ? max=20"
          print *," "
          read *,proggroups
          write(unit=10, fmt='(i10,a23)') proggroups," ! number of proggroups"
          print *," "
          do p=1,proggroups
            print *,"number of dams producing animals in progeny group ",p
            print *," "
            read *,proggroupsdams(p)
            write(unit=10, fmt='(f10.3,a30,i3)') proggroupsdams(p)," ! number of dams in proggroup",p
   !         print *," if candidate is male :"
            print *," "
            print *,"number of animals in progeny group ",p
            print *," "
            read *,proggroupsoffs(p)
            write(unit=10, fmt='(f10.3,a33,i3)') proggroupsoffs(p)," ! number of animals in proggroup",p
    !        print *," if candidate is female :"
            print *," "
     !       print *,"number of animals in progeny group ",p
      !      print *," "
            proggroupsoffd(p)=proggroupsoffs(p)/proggroupsdams(p)
       !     read *,proggroupsoffd(p)
        !    write(unit=10, fmt='(f10.3,a33,i3)') proggroupsoffd(p)," ! number of animals in proggroup",p
          end do
        end if

        ! initialise source array
        allocate(stempsource(ntraits,84))
        allocate(stempsource2(ntraits,84))
        allocate(stempsource3(ntraits,84))
        allocate(stempsource4(ntraits,84))
        allocate(dtempsource(ntraits,84))
        allocate(dtempsource2(ntraits,84))
        allocate(dtempsource3(ntraits,84))
        allocate(dtempsource4(ntraits,84))
        stempsource=0
        stempsource2=0
        stempsource3=0
        stempsource4=0
        dtempsource=0
        dtempsource2=0
        dtempsource3=0
        dtempsource4=0

	! initialize information source counter
	sits=0
	sits2=0
        sits3=0
	dits=0
	dits2=0
        dits3=0
        ! input of information sources stage 1 and stage 2
        initindsel="s"
        do p=1,ntraits ! first sires
          if (sdesttraits(p).eq."i" .or. sdesttraits(p).eq."b") then
            nstag=1
	    call info_sources(p,xtraits(p),stempsource,sits(p),stempsource3, &
             & sits3(p),spheninfo(p),sproginfo(p),initindsel,indexdiff,ntraits, &
             & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
             & hsgroupsoff,proggroupsdams,proggroupsoffs,nstag) ! stage 1
 	  end if
          if (sdesttraits2(p).eq."i" .or. sdesttraits2(p).eq."b") then
	    call info_sources2(p,xtraits(p),stempsource3,sits3(p),stempsource2, &
             & sits2(p),spheninfo(p),sproginfo(p),initindsel,indexdiff,ntraits, &
             & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
             & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 2
 	  end if
        end do

        if (indexdiff.eq."y") then
          initindsel="d"
          do p=1,ntraits ! then dams
            if (ddesttraits(p).eq."i" .or. ddesttraits(p).eq."b") then
	      call info_sources(p,xtraits(p),dtempsource,dits(p),dtempsource3, &
               & dits3(p),dpheninfo(p),dproginfo(p),initindsel,indexdiff,ntraits, &
               & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
               & hsgroupsoff,proggroupsdams,proggroupsoffd,nstag) ! stage 1
	    end if
            if (ddesttraits2(p).eq."i" .or. ddesttraits2(p).eq."b") then
  	      call info_sources2(p,xtraits(p),dtempsource3,dits3(p),dtempsource2, &
               & dits2(p),dpheninfo(p),dproginfo(p),initindsel,indexdiff,ntraits, &
               & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
               & hsgroupsoff,proggroupsdams,proggroupsoffd) ! stage 2
	    end if
          end do
        else
          dits=sits
          dits2=sits2
          dpheninfo=spheninfo
          dproginfo=sproginfo
          dtempsource=stempsource
          dtempsource2=stempsource2
        end if


  !      PRINT *,"tempsource s",stempsource
   !     PRINT *,"tempsource d",dtempsource
   !    PRINT *,"pheninfo s ",spheninfo
    !   PRINT *,"pheninfo d ",dpheninfo

	! read correlations
975	do i=1,ntraits
	  do j=1,ntraits
	    if (j.gt.i) then
1000	      print *,"correlations between ",xtraits(i)," and ",xtraits(j)," ?"
	      print *,"phenotypic ?"
              print *," "
  	      read *,phcorr(i,j)
              write(unit=10, fmt=11007) phcorr(i,j),xtraits(i),xtraits(j)

              if (phcorr(i,j).le.-1 .or. phcorr(i,j).ge.1) then
                print *,"wrong input!"
                goto 1000
              end if
	      print *,"genetic ?"
              print *," "
	      read *,gcorr(i,j)
              write(unit=10, fmt=11008) gcorr(i,j),xtraits(i),xtraits(j)

              if (gcorr(i,j).le.-1 .or. gcorr(i,j).ge.1) then
                print *,"wrong input!"
                goto 1000
              end if
              if (initc.eq."y") then
	        print *,"common environmental ?"
                print *," "
    	        read *,ccorr(i,j)
                write(unit=10, fmt=11009) ccorr(i,j),xtraits(i),xtraits(j)

                if (ccorr(i,j).le.-1 .or. ccorr(i,j).ge.1) then
                  print *,"wrong input!"
                  goto 1000
                end if
              end if
	    end if
	  end do
	end do

	! setup correlations between traits
	do i=1,ntraits
	  do j=1,ntraits
	    if (i.eq.j) then
	      phcorr(i,j)=1
	      gcorr(i,j)=1
              ccorr(i,j)=1
	    else if (j.gt.i) then
              phcorr(j,i)=phcorr(i,j)
              gcorr(j,i)=gcorr(i,j)
              ccorr(j,i)=ccorr(i,j)
	    else
	      continue
	    end if
	  end do
	end do

        ! get selection information
1200    print *,"number of selected sires? "
        print *," "
	read *,nsires
        write(unit=10, fmt=11011) nsires

        print *,"number of selected dams? "
        print *," "
	read *,ndams
        write(unit=10, fmt=11012) ndams

        print *,"number of male selection candidates per dam? "
        print *," "
	read *,noffs
        write(unit=10, fmt=11021) noffs
        print *,"number of female selection candidates per dam? "
        print *," "
	read *,noffd
        write(unit=10, fmt=11028) noffd

        print *,"proportion selected sires in stage 1 ? "
        print *," "
        read *,pvals
        write(unit=10, fmt=11013) pvals

        print *,"proportion selected sires in stage 2 ? "
        print *," "
        read *,pvals2
        write(unit=10, fmt=11026) pvals2

        print *,"proportion selected dams in stage 1 ? "
        print *," "
        read *,pvald
        write(unit=10, fmt=11019) pvald

        print *,"proportion selected dams in stage 2 ? "
        print *," "
        read *,pvald2
        write(unit=10, fmt=11027) pvald2
        neffdams=ndams/nsires

        ! check info sources if mating ratio = 1
        initnotematrat="n"
        if (nsires.eq.ndams) then
          spheninfo="n"
          dpheninfo="n"
          do p=1,ntraits
            i=0
            do q=1,sits2(p)
              if (stempsource2(p,q).ge.24 .and. stempsource2(p,q).le.43) then
                initnotematrat="y"
              else
                i=i+1
                stempsource4(p,i)=stempsource2(p,q)
                if (stempsource2(p,q).eq.1) then
                  spheninfo(p)="y"
                else if (stempsource2(p,q).ge.4 .and. stempsource2(p,q).le.23) then
                  spheninfo(p)="y"
                else if (stempsource2(p,q).ge.64 .and. stempsource2(p,q).le.83) then
                  spheninfo(p)="y"
                else
                  continue
                end if
              end if
            end do
            do q=1,84
              if (q.le.i) then
                stempsource2(p,q)=stempsource4(p,q)
              else
                stempsource2(p,q)=0
              end if
            end do
            sits2(p)=i
          end do
          if (indexdiff.eq."y") then
            do p=1,ntraits
              i=0
              do q=1,dits2(p)
                if (dtempsource2(p,q).ge.24 .and. dtempsource2(p,q).le.43) then
                  initnotematrat="y"
                else
                  i=i+1
                  dtempsource4(p,i)=dtempsource2(p,q)
                  if (dtempsource2(p,q).eq.1) then
                    dpheninfo(p)="y"
                  else if (dtempsource2(p,q).ge.4 .and. dtempsource2(p,q).le.23) then
                    dpheninfo(p)="y"
                  else if (dtempsource2(p,q).ge.64 .and. dtempsource2(p,q).le.83) then
                    dpheninfo(p)="y"
                  else
                    continue
                  end if
                end if
              end do
              do q=1,84
                if (q.le.i) then
                  dtempsource2(p,q)=dtempsource4(p,q)
                else
                  dtempsource2(p,q)=0
                end if
              end do
              dits2(p)=i
            end do
          else
            do p=1,ntraits
              do q=1,84
                dtempsource2(p,q)=stempsource2(p,q)
              end do
              dpheninfo(p)=spheninfo(p)
              dits2(p)=sits2(p)
            end do
          end if
        end if
        if (initnotematrat.eq."y") then
          call note_matrat
        end if

        ! check if traits without phenotypic infosources are genetically correlated with
	! traits which do have phenotypic infosources
	if (indexdiff.eq."y") then   ! check sires and dams
1100   	  do i=1,ntraits
	    if (spheninfo(i).eq."n" .and. dpheninfo(i).eq."n") then
	      do j=1,ntraits
	        if (spheninfo(j).eq."y" .or. dpheninfo(j).eq."y") then
	          if (gcorr(i,j).ne.0.0) then
	            posgcorr(i)="y"
	          end if
	        end if
	      end do
	      if (posgcorr(i).eq."n") then
	        call note_pheninfo(xtraits(i),pheninfoinit)
	        if (pheninfoinit.eq."i") then
                  print *," change sire or dam information sources s/d ?"
                  print *," "
                  read *,sourcesd
                  write(unit=10, fmt=11010) sourcesd
                  if (sourcesd.eq."s") then
                    initindsel="s"
	            call info_sources(i,xtraits(i),stempsource,sits(i),stempsource3, &
                     & sits3(i),spheninfo(i),sproginfo(i),initindsel,indexdiff,ntraits, &
                     & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                     & hsgroupsoff,proggroupsdams,proggroupsoffs,nstag) ! stage 1
              	    call info_sources2(i,xtraits(i),stempsource3,sits3(i),stempsource2, &
                     & sits2(i),spheninfo(i),sproginfo(i),initindsel,indexdiff,ntraits, &
                     & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                     & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 2
	            goto 1100
	          else if (sourcesd.eq."d") then
                    initindsel="d"
	            call info_sources(i,xtraits(i),dtempsource,dits(i),dtempsource3, &
                     & dits3(i),dpheninfo(i),dproginfo(i),initindsel,indexdiff,ntraits, &
                     & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                     & hsgroupsoff,proggroupsdams,proggroupsoffs,nstag) ! stage 1
               	    call info_sources2(i,xtraits(i),dtempsource3,dits3(i),dtempsource2, &
                     & dits2(i),dpheninfo(i),dproginfo(i),initindsel,indexdiff,ntraits, &
                     & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                     & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 2
                    goto 1100
                  else
                    continue
	          end if
	        else if (pheninfoinit.eq."c") then
	          do p=1,ntraits
	            if (spheninfo(p).eq."y" .or. dpheninfo(p).eq."y") then
	              if (p.gt.i) then
	                print *,"genetic correlation between:",xtraits(i),"and ",xtraits(p)
	                print *,"was: ",gcorr(i,p)
	                print *,"new value:"
                        print *," "
                        read *,gcorr(i,p)
                        write(unit=10, fmt=11008) gcorr(i,p),xtraits(i),xtraits(p)
                        gcorr(p,i)=gcorr(i,p)
	                goto 1175
	              else if (i.gt.p) then
	                print *,"genetic correlation between:",xtraits(i),"and ",xtraits(p)
                        print *,"was: ",gcorr(i,p)
                        print *,"new value:"
                        print *," "
                        read *,gcorr(p,i)
                        write(unit=10, fmt=11008) gcorr(p,i),xtraits(p),xtraits(i)
                        gcorr(i,p)=gcorr(p,i)
                        goto 1175
	              else
	                continue
	              end if
	            end if
	          end do
	        else
	          continue
	        end if
1175	      end if
	    end if
          end do
        else    ! check sires
1180	  do i=1,ntraits
	    if (spheninfo(i).eq."n") then
	      do j=1,ntraits
	        if (spheninfo(j).eq."y") then
	          if (gcorr(i,j).ne.0.0) then
	            posgcorr(i)="y"
	          end if
	        end if
	      end do
       	      if (posgcorr(i).eq."n") then
	        call note_pheninfo(xtraits(i),pheninfoinit)
	        if (pheninfoinit.eq."i") then
                  initindsel="n"
	          call info_sources(i,xtraits(i),stempsource,sits(i),stempsource3, &
                   & sits3(i),spheninfo(i),sproginfo(i),initindsel,indexdiff,ntraits, &
                   & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                   & hsgroupsoff,proggroupsdams,proggroupsoffs,nstag) ! stage 1
                  call info_sources2(i,xtraits(i),stempsource3,sits3(i),stempsource2, &
                   & sits2(i),spheninfo(i),sproginfo(i),initindsel,indexdiff,ntraits, &
                   & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                   & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 2
	          dits(i)=sits(i)
	          dits2(i)=sits2(i)
	          dpheninfo(i)=spheninfo(i)
	          dproginfo(i)=sproginfo(i)
	          dtempsource=stempsource
	          dtempsource2=stempsource2
	          goto 1180
	        else if (pheninfoinit.eq."c") then
	          do p=1,ntraits
	            if (spheninfo(p).eq."y") then
	              if (p.gt.i) then
	                print *,"genetic correlation between:",xtraits(i),"and ",xtraits(p)
	                print *,"was: ",gcorr(i,p)
	                print *,"new value:"
                        print *," "
                        read *,gcorr(i,p)
                        write(unit=10, fmt=11008) gcorr(i,p),xtraits(i),xtraits(p)
                        gcorr(p,i)=gcorr(i,p)
	                goto 1190
	              else if (i.gt.p) then
	                print *,"genetic correlation between:",xtraits(i),"and ",xtraits(p)
                        print *,"was: ",gcorr(i,p)
                        print *,"new value:"
                        print *," "
                        read *,gcorr(p,i)
                        write(unit=10, fmt=11008) gcorr(p,i),xtraits(p),xtraits(i)
                        gcorr(i,p)=gcorr(p,i)
	                goto 1190
	              else
	                continue
	              end if
	            end if
	          end do
	        else
	          continue
	        end if
1190	      end if
            end if
	  end do
        end if

	! get dimension for real p-matrix
	ssumits=0
	ssumits2=0
	dsumits=0
	dsumits2=0
	do p=1,ntraits
	  if (sdesttraits(p).eq."i" .or. sdesttraits(p).eq."b") then
	    ssumits=ssumits+(sits(p)-1)
	  end if
	  if (ddesttraits(p).eq."i" .or. ddesttraits(p).eq."b") then
	    dsumits=dsumits+(dits(p)-1)
	  end if
	  if (sdesttraits2(p).eq."i" .or. sdesttraits2(p).eq."b") then
	    ssumits2=ssumits2+(sits2(p)-1)
	  end if
	  if (ddesttraits2(p).eq."i" .or. ddesttraits2(p).eq."b") then
	    dsumits2=dsumits2+(dits2(p)-1)
	  end if
	end do
  !      print *,"ssumits ",ssumits
   !     print *,"dsumits ",dsumits
    !    print *,"ssumits2 ",ssumits2
     !   print *,"dsumits2 ",dsumits2

        ! get progeny testing information
        if (initprog.eq."y" .and. initc.eq."y") then
          do q=1,ntraits
960         print *,"common environmental effect in the progeny test"
            print *," = c-square for ",xtraits(q)," ?"
            print *," "
            read *,ccprog(q)
            write(unit=10, fmt=11016) ccprog(q),xtraits(q)
            if (ccprog(q).le.0) then
              print *,"wrong input, com.env.effect must be higher than 0!"
              goto 960
            else if (ccprog(q).ge.1) then
              print *,"wrong input, com.env.effect must be lower than 1!"
              goto 960
            else
              continue
            end if
          end do
        end if

        ! get truncation points
        pvalse=pvals*pvals2
        pvalde=pvald*pvald2
        call trunc((pvalse),dum1,dum2,is,ks)
        call trunc((pvalde),dum1,dum2,id,kd)

  !	print *,"ks is",ks,is
   !	print *,"kd id",kd,id


        allocate(sb(ssumits,1), db(dsumits,1), sinvp(ssumits,ssumits))
        allocate(spartrealg(ssumits,1), dpartrealg(dsumits,1), dinvp(dsumits,dsumits))
        allocate(stempcov1(ssumits,1), stempcov2(ssumits,1), srealg(ssumits,ntraits))
        allocate(dtempcov1(dsumits,1), dtempcov2(dsumits,1), drealg(dsumits,ntraits))

        allocate(sb2(ssumits2,1), db2(dsumits2,1), sinvp2(ssumits2,ssumits2))
        allocate(spartrealg2(ssumits2,1), dpartrealg2(dsumits2,1), dinvp2(dsumits2,dsumits2))
        allocate(stempcov12(ssumits2,1), stempcov22(ssumits2,1), srealg2(ssumits2,ntraits))
        allocate(dtempcov12(dsumits2,1), dtempcov22(dsumits2,1), drealg2(dsumits2,ntraits))
    !	  print *,"allocaten gaat goed"

        ! variance starting values
        ssigmai=0.0
        do p=1,ntraits
	  sigmaa(p)=hh(p)*sigmap(p)
	  sigmac(p)=cc(p)*sigmap(p)
          progsigmac(p)=ccprog(p)*sigmap(p)
	  sigmaas(p)=0.25*sigmaa(p)
          sigmaad(p)=0.25*sigmaa(p)
	  sigmaaw(p)=0.5*sigmaa(p)
          sigmae(p)=sigmap(p)-sigmaa(p)-sigmac(p)
          if (sdesttraits(p).eq."h" .or. sdesttraits(p).eq."b") then
            temp3sigmai=hh(p)*sigmaa(p)*tempev(p,1)*tempev(p,1)
            ssigmai=ssigmai+temp3sigmai
          end if
          if (indexdiff.eq."y") then
            if (ddesttraits(p).eq."h" .or. ddesttraits(p).eq."b") then
              temp3sigmai=hh(p)*sigmaa(p)*tempev(p,1)*tempev(p,1)
              dsigmai=dsigmai+temp3sigmai
            end if
          else
            dsigmai=ssigmai
          end if
	end do
        ssigmai=ssigmai*(1-ks)
        ssigmai2=ssigmai*(1-ks)
        dsigmai=dsigmai*(1-kd)
        dsigmai2=dsigmai*(1-kd)
     !	print *,"varianties zijn goed"

	! covariance starting values
	do p=1,ntraits
          do q=1,ntraits
            scovapi(q)=hh(q)*tempev(q,1)*sigmaa(q)
            dcovapi(q)=scovapi(q)
            covipi(q)=hh(q)*tempev(q,1)*sigmaa(q)
	    covp(p,q)=phcorr(p,q)*(sqrt(sigmap(p))*sqrt(sigmap(q)))
	    covas(p,q)=gcorr(p,q)*(sqrt(sigmaas(p))*sqrt(sigmaas(q)))
	    covad(p,q)=gcorr(p,q)*(sqrt(sigmaad(p))*sqrt(sigmaad(q)))
       	    covaw(p,q)=gcorr(p,q)*(sqrt(sigmaaw(p))*sqrt(sigmaaw(q)))
            covc(p,q)=ccorr(p,q)*(sqrt(sigmac(p))*sqrt(sigmac(q)))
      !      print *,"covc",p,q,covc
            covcprog(p,q)=ccorr(p,q)*(sqrt(progsigmac(p))*sqrt(progsigmac(q)))

            genpart=((sqrt(hh(p)))*(sqrt(hh(q)))*gcorr(p,q))
            comenvpart=((sqrt(cc(p)))*(sqrt(cc(q)))*ccorr(p,q))
            errpart=(sqrt(1-hh(p)-cc(p))*sqrt(1-hh(q)-cc(q)))
 	    ecorr(p,q)=(phcorr(p,q)-genpart-comenvpart)/errpart

	    cove(p,q)=ecorr(p,q)*(sqrt(sigmae(p))*sqrt(sigmae(q)))
 	    covapiq(p,q)=hh(q)*gcorr(p,q)*(sqrt(sigmaa(p))*(sqrt(sigmaa(q))))
            covapaq(p,q)=gcorr(p,q)*(sqrt(sigmaa(p))*(sqrt(sigmaa(q))))
            fs(p,q)=covas(p,q)+covad(p,q)+covc(p,q)
            hs(p,q)=covas(p,q)
            s(p,q)=covapiq(p,q)-((scovapi(p)*covipi(q)*ks)/ssigmai)
            d(p,q)=covapiq(p,q)-((dcovapi(p)*covipi(q)*kd)/dsigmai)
          end do
        end do
  !      print *," starting s ",s
   !     print *," starting d ",d

  !  	print *,"covarianties zijn goed"

        close(unit=10)

        ! 12 times index calculations for stage 2
    !    print *,"stempsource",stempsource
     !   print *,"dtempsource",dtempsource
      !  print *,"stempsource2",stempsource2
       ! print *,"dtempsource2",dtempsource2
        selrounds=25
        response=0
        do p=1,selrounds
          initindsel="s"
!          print *,"sdesttraits2",sdesttraits2
    !    print *," sires "
    !    print *," "
   	  call selection_index(ntraits,ssigmai2,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,scovapi,ssumits2,sdesttraits2,sits2,stempsource2,sresponse2, &
            & stotalresponse2,srih2,srealg2,sb2,sinvp2,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvalse,nsires,neffdams,noffs,scorrfs2,scorrhs2, &
            & fsgroups,hsgroups,proggroups)
          initindsel="d"
     !   print *," dams "
     !   print *," "
          call selection_index(ntraits,dsigmai2,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,dcovapi,dsumits2,ddesttraits2,dits2,dtempsource2,dresponse2, &
            & dtotalresponse2,drih2,drealg2,db2,dinvp2,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvalde,nsires,neffdams,noffd,dcorrfs2,dcorrhs2, &
            & fsgroups,hsgroups,proggroups)

          call covariance_update(ntraits,ssigmai2,dsigmai2,covp,covas,covad, &
            & covaw,covc,cove,covapaq,ssumits2,sits2,sresponse2,stotalresponse2,srealg2, &
            & sb2,sinvp2,dsumits2,dits2,dresponse2,dtotalresponse2,drealg2,db2,dinvp2,ks,kd, &
            & response2,totalresponse2,tempev,scovapi,dcovapi,fs,hs,s,d)
      !  print *," updated s ",s
       ! print *," updated d ",d

        end do

        do p=1,ntraits
  !        print *,"sresponse2",p,sresponse2(p)
   !       print *,"dresponse2",p,dresponse2(p)
        end do
    !    print *,"totalresponse2",(stotalresponse2+dtotalresponse2)/2

        ! 1 time index calculations for stage 1
        initindsel="s"
   	call selection_index(ntraits,ssigmai,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,scovapi,ssumits,sdesttraits,sits,stempsource,sresponse, &
            & stotalresponse,srih,srealg,sb,sinvp,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvals,nsires,neffdams,noffs,scorrfs,scorrhs, &
            & fsgroups,hsgroups,proggroups)
    !    print *,"srih",srih

        call covai_update(ntraits,ssigmai,ssumits,sresponsec,stotalresponsec, &
          & srealg,sb,pvals,noffs,neffdams,nsires,scorrfs,scorrhs,srealp)

        call trunc(pvals,dum1,dum2,is,ks)
        isc=rawl3(pvals,noffs,neffdams,nsires,scorrfs,scorrhs)

        do p=1,ntraits
          sresponse(p)=sresponsec(p)*(is/isc)
     !     print *,"sresponse",sresponse(p)
      !    print *,"sresponsec",sresponsec(p)
        end do
        stotalresponse=stotalresponsec*(is/isc)
       ! print *,"stotalresponse",stotalresponse
        !print *,"stotalresponsec",stotalresponsec
     !   print *,"is/isc",is/isc

        initindsel="d"
        call selection_index(ntraits,dsigmai,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,dcovapi,dsumits,ddesttraits,dits,dtempsource,dresponse, &
            & dtotalresponse,drih,drealg,db,dinvp,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvald,nsires,neffdams,noffd,dcorrfs,dcorrhs, &
            & fsgroups,hsgroups,proggroups)
      !  print *,"drih",drih

        call covai_update(ntraits,dsigmai,dsumits,dresponsec,dtotalresponsec, &
          & drealg,db,pvald,noffd,neffdams,nsires,dcorrfs,dcorrhs,drealp)

        call trunc(pvald,dum1,dum2,id,kd)
        idc=rawl3(pvald,noffd,neffdams,nsires,dcorrfs,dcorrhs)

        do p=1,ntraits
          dresponse(p)=dresponsec(p)*(id/idc)
       !   print *,"dresponse",dresponse(p)
        !  print *,"dresponsec",dresponsec(p)
        end do
        dtotalresponse=dtotalresponsec*(id/idc)
   !     print *,"dtotalresponse",dtotalresponse
    !    print *,"dtotalresponsec",dtotalresponsec
     !   print *,"id/idc",id/idc

        ! calculate response and totalresponse based on index 1
        do j=1,ntraits
          response(j)=(sresponse(j)+dresponse(j))/2
          responsec(j)=(sresponsec(j)+dresponsec(j))/2
      !    print *,"response",j,response(j)
        end do
        totalresponse=(stotalresponse+dtotalresponse)/2
        totalresponsec=(stotalresponsec+dtotalresponsec)/2
      !  print *,"totalresponse",totalresponse
       ! print *,"totalresponsec",totalresponsec

	! print output
        call intro(2)

        ! print trait information
        write(unit=20, fmt=*) " TRAITS"
        write(unit=20, fmt=*) " "
        do p=1,ntraits
	  write(unit=20, fmt=*) "   ",xtraits(p)
        end do
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "

        ! print trait parameters
        write(unit=20, fmt=*) "  TRAIT PARAMETERS"
        write(unit=20, fmt=*) "  "
        if (initc.eq."y") then
          write(unit=20, fmt=*) "       phenotypic variance  heritability  com.env.effect"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3,8x,f8.3)') xtraits(p),sigmap(p),hh(p),cc(p)
          end do
        else
          write(unit=20, fmt=*) "       phenotypic variance  heritability"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3)') xtraits(p),sigmap(p),hh(p)
          end do
        end if
        write(unit=20, fmt=*) " "


        if (ntraits.gt.1) then
          ! print phenotypic correlations
          write(unit=20, fmt=*) "  PHENOTYPIC CORRELATIONS"
          write(unit=20, fmt=*) "  "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),(phcorr(p,j), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print genetic correlations
          write(unit=20, fmt=*) "  GENETIC CORRELATIONS"
          write(unit=20, fmt=*) "  "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),(gcorr(p,j), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print common environmental correlations
          if (initc.eq."y") then
            write(unit=20, fmt=*) "  COMMON ENVIRONMENTAL CORRELATIONS"
            write(unit=20, fmt=*) "  "
            write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
            do p=1,ntraits
              write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),(ccorr(p,j), j=1,p)
            end do
          end if
          write(unit=20, fmt=*) " "
        end if

        ! print breeding goal information
        write(unit=20, fmt=*) " BREEDING GOAL INFORMATION"
        write(unit=20, fmt=*) " "
        do p=1,ntraits
	  if (sdesttraits(p).eq."h" .or. sdesttraits(p).eq."b") then
	    write(unit=20, fmt=11018) tempev(p,1),xtraits(p)
          end if
        end do
        write(unit=20, fmt=*) " "

        ! print population parameters
        write(unit=20, fmt=*) "  POPULATION SIZE"
        write(unit=20, fmt=*) "  "
        write(unit=20, fmt='(a49,f8.3)') "                      number of selected sires : ",nsires
        write(unit=20, fmt='(a49,f8.3)') "                       number of selected dams : ",ndams
        write(unit=20, fmt='(a49,f8.3)') " number of male selection candidates per dam   : ",noffs
        write(unit=20, fmt='(a49,f8.3)') " number of female selection candidates per dam : ",noffd
        write(unit=20, fmt=*) " "
        write(unit=20, fmt='(a49,f5.3)') "          selected proportion sires in stage 1 : ",pvals
        write(unit=20, fmt='(a49,f5.3)') "          selected proportion sires in stage 2 : ",pvals2
        write(unit=20, fmt='(a49,f5.3)') "               total selected proportion sires : ",pvals*pvals2
        write(unit=20, fmt=*) " "
        write(unit=20, fmt='(a49,f5.3)') "           selected proportion dams in stage 1 : ",pvald
        write(unit=20, fmt='(a49,f5.3)') "           selected proportion dams in stage 2 : ",pvald2
        write(unit=20, fmt='(a49,f5.3)') "                total selected proportion dams : ",pvald*pvald2
        write(unit=20, fmt=*) " "
        if (fsgroups.gt.0 .or. hsgroups.gt.0 .or. proggroups.gt.0) then
          write(unit=20, fmt=*) " CHARACTERISTICS OF THE USED GROUPS"
          write(unit=20, fmt=*) " "
        end if

        do i=1,fsgroups
          write(unit=20, fmt=*) " full-sib group ",i," with ",fsgroupsoff(i)," animals"
        end do
        do i=1,hsgroups
          write(unit=20, fmt=*) " half-sib group ",i," with ",hsgroupsdams(i)," dams, producing ",hsgroupsoff(i),"animals"
        end do
        if (proggroups.gt.0) then
          write(unit=20, fmt=*) " progeny group information"
          do i=1,proggroups
            write(unit=20, fmt=*) " progeny group ",i," with ",proggroupsdams(i)," dams, producing",proggroupsoffs(i),"progeny"
          end do
  !        write(unit=20, fmt=*) " progeny group information for dams"
   !       do i=1,proggroups
    !        write(unit=20, fmt=*) " progeny group ",i," with 1 dam, producing",proggroupsoffd(i),"progeny"
     !     end do
        end if

        ! print index 1 information
 	i=0
        write(unit=20, fmt=*) " "
        if (indexdiff.eq."y") then
          write(unit=20, fmt=*) " STAGE 1 INDEX INFORMATION FOR SIRES :"
        else
          write(unit=20, fmt=*) " STAGE 1 INDEX INFORMATION:"
        end if
        write(unit=20, fmt=*) " "
    	xsource(1)="own performance"
     	xsource(2)="ebv of the dam"
        xsource(3)="ebv of the sire"
        do p=4,23
          xsource(p)="information of fs-group "
        end do
        do p=24,43
          xsource(p)="information of hs-group "
        end do
        do p=44,63
          xsource(p)="mean ebv of the dams of hs-group "
        end do
        do p=64,83
          xsource(p)="information of progeny group "
        end do
      	do p=1,ntraits
       	  if (sdesttraits(p).eq."i" .or. sdesttraits(p).eq."b") then
	    do q=1,sits(p)-1
	      i=i+1
              if (stempsource(p,q).le.3) then
      	        write(unit=20, fmt=11000) xsource(stempsource(p,q)),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.4 .and. stempsource(p,q).le.23) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-3),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.24 .and. stempsource(p,q).le.43) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-23),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.44 .and. stempsource(p,q).le.63) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-43),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.64 .and. stempsource(p,q).le.83) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-63),xtraits(p), &
                  & sb(i,1)
              else
                continue
              end if
            end do
      	    write(unit=20, fmt=*) " "
       	  end if
     	end do
        if (indexdiff.eq."y") then
          i=0
	  write(unit=20, fmt=*) " STAGE 1 INDEX INFORMATION FOR DAMS:"
          do p=1,ntraits
	    if (ddesttraits(p).eq."i" .or. ddesttraits(p).eq."b") then
	      do q=1,dits(p)-1
	        i=i+1
                if (dtempsource(p,q).le.3) then
       	          write(unit=20, fmt=11000) xsource(dtempsource(p,q)),xtraits(p), &
                    & db(i,1)
                else if (dtempsource(p,q).ge.4 .and. dtempsource(p,q).le.23) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-3,xtraits(p), &
                    db(i,1)
                else if (dtempsource(p,q).ge.24 .and. dtempsource(p,q).le.43) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-23,xtraits(p), &
                    db(i,1)
                else if (dtempsource(p,q).ge.44 .and. dtempsource(p,q).le.63) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-43,xtraits(p), &
                    db(i,1)
                else if (dtempsource(p,q).ge.64 .and. dtempsource(p,q).le.83) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-63,xtraits(p), &
                    db(i,1)
                else
                  continue
                end if
      	      end do
       	      write(unit=20, fmt=*) " "
	    end if
      	  end do
        end if

        ! print index 2 information
 	i=0
        if (indexdiff.eq."y") then
          write(unit=20, fmt=*) " STAGE 2 INDEX INFORMATION FOR SIRES :"
        else
          write(unit=20, fmt=*) " STAGE 2 INDEX INFORMATION :"
        end if
      	do p=1,ntraits
       	  if (sdesttraits2(p).eq."i" .or. sdesttraits2(p).eq."b") then
	    do q=1,sits2(p)-1
	      i=i+1
              if (stempsource2(p,q).le.3) then
      	        write(unit=20, fmt=11000) xsource(stempsource2(p,q)),xtraits(p), &
                  & sb2(i,1)
              else if (stempsource2(p,q).ge.4 .and. stempsource2(p,q).le.23) then
      	        write(unit=20, fmt=11024) xsource(stempsource2(p,q)),(stempsource2(p,q)-3),xtraits(p), &
                  & sb2(i,1)
              else if (stempsource2(p,q).ge.24 .and. stempsource2(p,q).le.43) then
      	        write(unit=20, fmt=11024) xsource(stempsource2(p,q)),(stempsource2(p,q)-23),xtraits(p), &
                  & sb2(i,1)
              else if (stempsource2(p,q).ge.44 .and. stempsource2(p,q).le.63) then
      	        write(unit=20, fmt=11024) xsource(stempsource2(p,q)),(stempsource2(p,q)-43),xtraits(p), &
                  & sb2(i,1)
              else if (stempsource2(p,q).ge.64 .and. stempsource2(p,q).le.83) then
      	        write(unit=20, fmt=11024) xsource(stempsource2(p,q)),(stempsource2(p,q)-63),xtraits(p), &
                  & sb2(i,1)
              else
                continue
              end if
            end do
      	    write(unit=20, fmt=*) " "
       	  end if
     	end do
        if (indexdiff.eq."y") then
          i=0
          write(unit=20, fmt=*) " STAGE 2 INDEX INFORMATION FOR DAMS :"
          do p=1,ntraits
	    if (ddesttraits2(p).eq."i" .or. ddesttraits2(p).eq."b") then
	      do q=1,dits2(p)-1
	        i=i+1
                if (dtempsource2(p,q).le.3) then
       	          write(unit=20, fmt=11000) xsource(dtempsource2(p,q)),xtraits(p), &
                    & db2(i,1)
                else if (dtempsource2(p,q).ge.4 .and. dtempsource2(p,q).le.23) then
      	          write(unit=20, fmt=11024) xsource(dtempsource2(p,q)),dtempsource2(p,q)-3,xtraits(p), &
                    & db2(i,1)
                else if (dtempsource2(p,q).ge.24 .and. dtempsource2(p,q).le.43) then
      	          write(unit=20, fmt=11024) xsource(dtempsource2(p,q)),dtempsource2(p,q)-23,xtraits(p), &
                    & db2(i,1)
                else if (dtempsource2(p,q).ge.44 .and. dtempsource2(p,q).le.63) then
      	          write(unit=20, fmt=11024) xsource(dtempsource2(p,q)),dtempsource2(p,q)-43,xtraits(p), &
                    & db2(i,1)
                else if (dtempsource2(p,q).ge.64 .and. dtempsource2(p,q).le.83) then
      	          write(unit=20, fmt=11024) xsource(dtempsource2(p,q)),dtempsource2(p,q)-63,xtraits(p), &
                    & db2(i,1)
                else
                  continue
                end if
      	      end do
       	      write(unit=20, fmt=*) " "
	    end if
      	  end do
        end if
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) "             ******************   RESULTS   *******************"
        write(unit=20, fmt=*) " "
        print *, "             ******************   RESULTS   *******************"
        print *, " "

        ! print equilibrium parameters
        write(unit=20, fmt=*) " EQUILIBRIUM PARAMETERS"
        write(unit=20, fmt=*) " "
        if (initc.eq."y") then
          write(unit=20, fmt=*) "       phenotypic variance  heritability  com.env.effect"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3,8x,f8.3)') xtraits(p),covp(p,p),(covapaq(p,p)/covp(p,p)),(covc(p,p)/covp(p,p))
          end do
        else
          write(unit=20, fmt=*) "       phenotypic variance  heritability"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3)') xtraits(p),covp(p,p),(covapaq(p,p)/covp(p,p))
          end do
        end if
        write(unit=20, fmt=*) " "

        if (ntraits.gt.1) then
          ! print equilibrium phenotypic correlations
          write(unit=20, fmt=*) "  PHENOTYPIC CORRELATIONS"
          write(unit=20, fmt=*) " "
          write(unit=20, fmt=*) "  "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((covp(p,j)/(sqrt(covp(p,p))*sqrt(covp(j,j)))), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print equilibrium genetic correlations
          write(unit=20, fmt=*) "  GENETIC CORRELATIONS"
          write(unit=20, fmt=*) " "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((covapaq(p,j)/(sqrt(covapaq(p,p))*sqrt(covapaq(j,j)))), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print equilibrium common environmental correlations
          if (initc.eq."y") then
            write(unit=20, fmt=*) "  COMMON ENVIRONMENTAL CORRELATIONS"
            write(unit=20, fmt=*) " "
            write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
            do p=1,ntraits
              write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((covc(p,j)/(sqrt(covc(p,p))*sqrt(covc(j,j)))), j=1,p)
            end do
          end if
          write(unit=20, fmt=*) " "
        end if

        ! print response
        write(unit=20, fmt=*) " RESPONSE AFTER STAGE 1"
        write(unit=20, fmt=*) "                           sires           dams          total"
        print *, " RESPONSE AFTER STAGE 1"
        print *, "                           sires           dams          total"
        do p=1,ntraits
          if (sdesttraits(p).eq."b" .or. sdesttraits(p).eq."h") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*sresponsec(p),0.5*dresponsec(p),responsec(p)
            write(unit=20, fmt=11022) 0.5*sresponsec(p)*tempev(p,1),0.5*dresponsec(p)*tempev(p,1),responsec(p)*tempev(p,1)
            write(unit=20, fmt=11023) ((0.5*sresponsec(p)*tempev(p,1))/totalresponsec)*100, &
              & ((0.5*dresponsec(p)*tempev(p,1))/totalresponsec)*100, &
              & ((responsec(p)*tempev(p,1))/totalresponsec)*100
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*sresponsec(p),0.5*dresponsec(p),responsec(p)
            print 11022, 0.5*sresponsec(p)*tempev(p,1),0.5*dresponsec(p)*tempev(p,1),responsec(p)*tempev(p,1)
            print 11023, ((0.5*sresponsec(p)*tempev(p,1))/totalresponsec)*100, &
              & ((0.5*dresponsec(p)*tempev(p,1))/totalresponsec)*100, &
              & ((responsec(p)*tempev(p,1))/totalresponsec)*100
            print *, " "
         end if
        end do
        ! print correlated response
        do p=1,ntraits
          if (sdesttraits(p).eq."i" .or. ddesttraits(p).eq."i") then
            write(unit=20, fmt=*) " CORRELATED RESPONSE AFTER STAGE 1"
            write(unit=20, fmt=*) "                           sires           dams          total"
            print *, " CORRELATED RESPONSE AFTER STAGE 1"
            print *, "                           sires           dams          total"
            goto 10010
          end if
        end do
10010   do p=1,ntraits
          if (sdesttraits(p).eq."i" .or. ddesttraits(p).eq."i") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*sresponsec(p),0.5*dresponsec(p),responsec(p)
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*sresponsec(p),0.5*dresponsec(p),responsec(p)
            print *, " "
          end if
        end do
        ! print total response
        write(unit=20, fmt=*) " TOTAL RESPONSE AFTER STAGE 1"
        write(unit=20, fmt=*) "                           sires           dams          total"
        write(unit=20, fmt=11022) 0.5*stotalresponsec,0.5*dtotalresponsec,totalresponsec
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "
        print *, " TOTAL RESPONSE AFTER STAGE 1"
        print *, "                           sires           dams          total"
        print 11022, 0.5*stotalresponsec,0.5*dtotalresponsec,totalresponsec
        print *, " "
        print *, " "
        if (ssigmai.ne.dsigmai) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "  index variance sires : ",ssigmai,"    index variance dams : ",dsigmai
                       print '(a25,f13.3,a26,f13.3)', "  index variance sires : ",ssigmai,"    index variance dams : ",dsigmai
        else
          write(unit=20, fmt='(a25,f13.3)') "        index variance : ",ssigmai
                       print '(a25,f13.3)', "        index variance : ",ssigmai
        end if
        write(unit=20, fmt='(a25,f13.3)') "breeding goal variance : ",sigmah
                     print '(a25,f13.3)', "breeding goal variance : ",sigmah
        if (srih.ne.drih) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "accuracy of sire index : ",srih,"  accuracy of dam index : ",drih
                       print '(a25,f13.3,a26,f13.3)', "accuracy of sire index : ",srih,"  accuracy of dam index : ",drih
        else
          write(unit=20, fmt='(a25,f13.3)') "     accuracy of index : ",srih
                       print '(a25,f13.3)', "     accuracy of index : ",srih
        end if
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "
        print *, " "


        ! 1 time index calculations for stage 2
        initindsel="s"
   	  call selection_index(ntraits,ssigmai2,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,dcovapi,ssumits2,sdesttraits2,sits2,stempsource2,sresponse2, &
            & stotalresponse2,srih2,srealg2,sb2,sinvp2,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvalse,nsires,neffdams,noffs,scorrfs2,scorrhs2, &
            & fsgroups,hsgroups,proggroups)
          initindsel="d"
          call selection_index(ntraits,dsigmai2,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,dcovapi,dsumits2,ddesttraits2,dits2,dtempsource2,dresponse2, &
            & dtotalresponse2,drih2,drealg2,db2,dinvp2,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvalde,nsires,neffdams,noffd,dcorrfs2,dcorrhs2, &
            & fsgroups,hsgroups,proggroups)

        ! calculation of truncation points and some conversions of real*8
        call racine
        dumpvals=pvals
   !     print *,"pvals",pvals
        call sseuil1(dumpvals,seuil1)
        print *,"seuil1 s",seuil1
        dumtrunc1s=seuil1
        trunc1s=dumtrunc1s
        pvalse=pvals*pvals2
        dumpvals=pvalse
        dumcorrsrih=srih/srih2
        if (dumcorrsrih.gt.0.93) then
          dumcorrsrih=0.93
        end if
        corrsrih=dumcorrsrih
     !   print *,"dumpvals",dumpvals
      !  print *,"dumtrunc1s",dumtrunc1s
       ! print *,"dumcorrsrih",dumcorrsrih
        call sseuil2(dumpvals,dumtrunc1s,dumcorrsrih,seuil2)
        print *,"seuil2 s",seuil2
        dumtrunc2s=seuil2
        trunc2s=dumtrunc2s
        dumpvald=pvald
    !    print *,"pvald",pvald
        call sseuil1(dumpvald,seuil1)
        print *,"seuil1 d",seuil1
        dumtrunc1d=seuil1
        trunc1d=dumtrunc1d
        pvalde=pvald*pvald2
        dumpvald=pvalde
        dumcorrdrih=drih/drih2
        if (dumcorrdrih.gt.0.93) then
          dumcorrdrih=0.93
        end if
        corrdrih=dumcorrdrih
     !   print *,"dumpvald",dumpvald
      !  print *,"dumtrunc1d",dumtrunc1d
       ! print *,"dumcorrdrih",dumcorrdrih
        call sseuil2(dumpvald,dumtrunc1d,dumcorrdrih,seuil2)
        print *,"seuil2 d",seuil2
        dumtrunc2d=seuil2
        trunc2d=dumtrunc2d
        pi=3.14159265358979

        ! calculate response after stage 1 for sires
        tempsresponse1=((2*pi)**(-0.5))*(exp(-0.5*trunc1s*trunc1s))
        t1s=(trunc2s-(corrsrih*trunc1s))/(sqrt(1-(corrsrih**2)))
        dumt=t1s
        call sdutt1(20,dumt,dumr)
        tempsresponse2=dumr
        tempsresponse3=((2*pi)**(-0.5))*(exp(-0.5*trunc2s*trunc2s))
 !       print *,"trunc1s",trunc1s
  !      print *,"trunc2s",trunc2s
   !     print *,"corrsrih",corrsrih
        t2s=(trunc1s-(corrsrih*trunc2s))/(sqrt(1-(corrsrih**2)))
        dumt=t2s
        call sdutt1(20,dumt,dumr)
        tempsresponse4=dumr
    !    print *,"tempsresponse1",tempsresponse1
     !   print *,"tempsresponse2",tempsresponse2
      !  print *,"tempsresponse3",tempsresponse3
       ! print *,"tempsresponse4",tempsresponse4
        msstotalresponse=((tempsresponse1*tempsresponse2)+(corrsrih*tempsresponse3*tempsresponse4))* &
          & ((sqrt(ssigmai))/(pvals*pvals2))

        ! calculate response after stage 2 for sires
        msstotalresponse2=((tempsresponse3*tempsresponse4)+(corrsrih*tempsresponse1*tempsresponse2))* &
          & ((sqrt(ssigmai2))/(pvals*pvals2))

        ! calculate response after stage 1 for dams
        tempdresponse1=((2*pi)**(-0.5))*(exp(-0.5*trunc1d*trunc1d))
        t1d=(trunc2d-(corrdrih*trunc1d))/(sqrt(1-(corrdrih**2)))
        dumt=t1d
        call sdutt1(20,dumt,dumr)
        tempdresponse2=dumr
        tempdresponse3=((2*pi)**(-0.5))*(exp(-0.5*trunc2d*trunc2d))
 !       print *,"trunc1d",trunc1d
  !      print *,"trunc2d",trunc2d
   !     print *,"corrdrih",corrdrih
        t2d=(trunc1d-(corrdrih*trunc2d))/(sqrt(1-(corrdrih**2)))
        dumt=t2d
        call sdutt1(20,dumt,dumr)
        tempdresponse4=dumr
    !    print *,"tempdresponse1",tempdresponse1
     !   print *,"tempdresponse2",tempdresponse2
      !  print *,"tempdresponse3",tempdresponse3
       ! print *,"tempdresponse4",tempdresponse4
        msdtotalresponse=((tempdresponse1*tempdresponse2)+(corrdrih*tempdresponse3*tempdresponse4))* &
          & ((sqrt(dsigmai))/(pvald*pvald2))

        ! calculate response after stage 2 for dams
        msdtotalresponse2=((tempdresponse3*tempdresponse4)+(corrdrih*tempdresponse1*tempdresponse2))* &
          & ((sqrt(dsigmai2))/(pvald*pvald2))

        ! calculate totalresponse after stage 1
        mstotalresponse=(msstotalresponse+msdtotalresponse)/2

        ! calculate totalresponse after stage 2
        mstotalresponse2=(msstotalresponse2+msdtotalresponse2)/2
   !     print *,"msstotalresponse",msstotalresponse
    !    print *,"msdtotalresponse",msdtotalresponse
    !    print *,"msstotalresponse2",msstotalresponse2
     !   print *,"msdtotalresponse2",msdtotalresponse2

        allocate(sgcol(ssumits,1), sgcol2(ssumits2,1))
        allocate(dgcol(dsumits,1), dgcol2(dsumits2,1))

        ! calculate response per trait after stage 2 for sires
        v(1,1)=ssigmai
        v(1,2)=ssigmai
        v(2,1)=ssigmai
        v(2,2)=ssigmai2
        dumv(1,1)=v(1,1)
        dumv(1,2)=v(1,2)
        dumv(2,1)=v(2,1)
        dumv(2,2)=v(2,2)
        call invrt(dumv,2,2)
        v(1,1)=dumv(1,1)
        v(1,2)=dumv(1,2)
        v(2,1)=dumv(2,1)
        v(2,2)=dumv(2,2)
        do p=1,ntraits
          do q=1,ssumits
            sgcol(q,1)=srealg(q,p)
          end do
          g1=matmul(transpose(sb),sgcol)
          do q=1,ssumits2
            sgcol2(q,1)=srealg2(q,p)
          end do
          g2=matmul(transpose(sb2),sgcol2)
          tempg1=g1(1,1)
          tempg2=g2(1,1)
          g(1,1)=tempg1
          g(2,1)=tempg2
          beta=matmul(v,g)
          mssresponse2(p)=(beta(1,1)*msstotalresponse)+(beta(2,1)*msstotalresponse2)
      !    print *,"mssresponse2",mssresponse2(p)
        end do

        ! calculate response per trait after stage 2 for dams
        v(1,1)=dsigmai
        v(1,2)=dsigmai
        v(2,1)=dsigmai
        v(2,2)=dsigmai2
        dumv(1,1)=v(1,1)
        dumv(1,2)=v(1,2)
        dumv(2,1)=v(2,1)
        dumv(2,2)=v(2,2)
        call invrt(dumv,2,2)
        v(1,1)=dumv(1,1)
        v(1,2)=dumv(1,2)
        v(2,1)=dumv(2,1)
        v(2,2)=dumv(2,2)
        do p=1,ntraits
          do q=1,dsumits
            dgcol(q,1)=drealg(q,p)
          end do
          g1=matmul(transpose(db),dgcol)
          do q=1,dsumits2
            dgcol2(q,1)=drealg2(q,p)
          end do
          g2=matmul(transpose(db2),dgcol2)
          tempg1=g1(1,1)
          tempg2=g2(1,1)
          g(1,1)=tempg1
          g(2,1)=tempg2
          beta=matmul(v,g)
          msdresponse2(p)=(beta(1,1)*msdtotalresponse)+(beta(2,1)*msdtotalresponse2)
   !       print *,"msdresponse2",msdresponse2(p)
        end do

        call trunc(pvals*pvals2,dum1,dum2,is2,ks)
        is2c=rawl3(pvals*pvals2,noffs,neffdams,nsires,scorrfs2,scorrhs2)

        call trunc(pvald*pvald2,dum1,dum2,id2,kd)
        id2c=rawl3(pvald*pvald2,noffd,neffdams,nsires,dcorrfs2,dcorrhs2)

        do p=1,ntraits
          if (tempev(p,1).ne.0) then
            prs(p)=(mssresponse2(p)*tempev(p,1))/msstotalresponse2
            prs(p)=prs(p)/2
            prd(p)=(msdresponse2(p)*tempev(p,1))/msdtotalresponse2
            prd(p)=prd(p)/2
          end if
        end do
        msstotalresponse2c=msstotalresponse2*(is2c/is2)
        msdtotalresponse2c=msdtotalresponse2*(id2c/id2)
        mstotalresponse2c=(msstotalresponse2c+msdtotalresponse2c)/2

        ! print response after stage 2
        write(unit=20, fmt=*) " RESPONSE AFTER STAGE 2"
        write(unit=20, fmt=*) "                           sires           dams          total"
        print *, " RESPONSE AFTER STAGE 2"
        print *, "                           sires           dams          total"
        do p=1,ntraits
          if (sdesttraits2(p).eq."b" .or. sdesttraits2(p).eq."h") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) (prs(p)*msstotalresponse2c)/tempev(p,1),(prd(p)*msdtotalresponse2c)/tempev(p,1), &
              &  ((prs(p)*msstotalresponse2c)/tempev(p,1))+((prd(p)*msdtotalresponse2c)/tempev(p,1))
            write(unit=20, fmt=11022) prs(p)*msstotalresponse2c,prd(p)*msdtotalresponse2c, &
              & (prs(p)*msstotalresponse2c)+(prd(p)*msdtotalresponse2c)
            write(unit=20, fmt=11023) ((prs(p)*msstotalresponse2c)/mstotalresponse2c)*100, &
              & ((prd(p)*msdtotalresponse2c)/mstotalresponse2c)*100, &
              & (((prs(p)*msstotalresponse2c)/mstotalresponse2c)*100)+(((prd(p)*msdtotalresponse2c)/mstotalresponse2c)*100)
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, (prs(p)*msstotalresponse2c)/tempev(p,1),(prd(p)*msdtotalresponse2c)/tempev(p,1), &
              &  ((prs(p)*msstotalresponse2c)/tempev(p,1))+((prd(p)*msdtotalresponse2c)/tempev(p,1))
            print 11022, prs(p)*msstotalresponse2c,prd(p)*msdtotalresponse2c, &
              & (prs(p)*msstotalresponse2c)+(prd(p)*msdtotalresponse2c)
            print 11023, ((prs(p)*msstotalresponse2c)/mstotalresponse2c)*100, &
              & ((prd(p)*msdtotalresponse2c)/mstotalresponse2c)*100, &
              & (((prs(p)*msstotalresponse2c)/mstotalresponse2c)*100)+(((prd(p)*msdtotalresponse2c)/mstotalresponse2c)*100)
            print *, " "
         end if
        end do
        ! print correlated response after stage 2
        do p=1,ntraits
          if (sdesttraits2(p).eq."i" .or. ddesttraits2(p).eq."i") then
            write(unit=20, fmt=*) " CORRELATED RESPONSE AFTER STAGE 2"
            write(unit=20, fmt=*) "                           sires           dams          total"
            print *, " CORRELATED RESPONSE AFTER STAGE 2"
            print *, "                           sires           dams          total"
            goto 10011
          end if
        end do
10011   do p=1,ntraits
          if (sdesttraits2(p).eq."i" .or. ddesttraits2(p).eq."i") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*mssresponse2(p)*(is2c/is2),0.5*msdresponse2(p)*(id2c/id2), &
              &  (0.5*mssresponse2(p)*(is2c/is2))+(0.5*msdresponse2(p)*(id2c/id2))
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*mssresponse2(p)*(is2c/is2),0.5*msdresponse2(p)*(id2c/id2), &
              &  (0.5*mssresponse2(p)*(is2c/is2))+(0.5*msdresponse2(p)*(id2c/id2))
            print *, " "
          end if
        end do
        ! print total response after stage 2
        write(unit=20, fmt=*) " TOTAL RESPONSE AFTER STAGE 2"
        write(unit=20, fmt=*) "                           sires           dams          total"
        write(unit=20, fmt=11022) msstotalresponse2c/2,msdtotalresponse2c/2, &
          & mstotalresponse2c
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "
        print *, " TOTAL RESPONSE AFTER STAGE 2"
        print *, "                           sires           dams          total"
        print 11022, msstotalresponse2c/2,msdtotalresponse2c/2, &
          & mstotalresponse2c
        print *, " "
        print *, " "
        if (ssigmai2.ne.dsigmai2) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "  index variance sires : ",ssigmai2,"    index variance dams : ",dsigmai2
                       print '(a25,f13.3,a26,f13.3)', "  index variance sires : ",ssigmai2,"    index variance dams : ",dsigmai2
        else
          write(unit=20, fmt='(a25,f13.3)') "        index variance : ",ssigmai2
                       print '(a25,f13.3)', "        index variance : ",ssigmai2
        end if
        write(unit=20, fmt='(a25,f13.3)') "breeding goal variance : ",sigmah
                     print '(a25,f13.3)', "breeding goal variance : ",sigmah
        if (srih2.ne.drih2) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "accuracy of sire index : ",srih2,"  accuracy of dam index : ",drih2
                       print '(a25,f13.3,a26,f13.3)', "accuracy of sire index : ",srih2,"  accuracy of dam index : ",drih2
        else
          write(unit=20, fmt='(a25,f13.3)') "     accuracy of index : ",srih2
                       print '(a25,f13.3)', "     accuracy of index : ",srih2
        end if
        write(unit=20, fmt=*) " "
        ! check for incoherent parameters
        posdefph="y"
        posdefg="y"
        allocate(jacvec(ntraits))
        call jacobi(phcorr,ntraits,jacvec)
        do p=1,ntraits
       !   print *,"jacvec(p)",jacvec(p)
          if (jacvec(p).lt.0) then
            posdefph="n"
          end if
        end do
        jacvec=0
        call jacobi(gcorr,ntraits,jacvec)
        do p=1,ntraits
       !   print *,"jacvec(p)",jacvec(p)
          if (jacvec(p).lt.0) then
            posdefg="n"
          end if
        end do
        if (posdefph.eq."n" .or. posdefg.eq."n") then
          write(unit=20, fmt=*) " ** incoherent genetic parameters detected"
          print *, " "
          print *, " ** incoherent genetic parameters detected"
        end if
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) "                      ******  end of output  ******"
        print *, " "
        print *, "                      ******  end of output  ******"

        ! format statements
	11000 format(5x,a33,"    for ",a8,"  (",f8.3,")")
        11001 format(i10," ! number of traits")
        11002 format(a10," ! different indices for sires and dams")
        11003 format(a10," ! use of common environment")
        11004 format(f10.3," ! phenotypic variance ",a8)
        11005 format(f10.3," ! heritability ",a8)
        11006 format(f10.3," ! common environmental effect ",a8)
        11007 format(f10.3," ! phenotypic correlation between ",a8," and ",a8)
        11008 format(f10.3," ! genetic correlation between ",a8," and ",a8)
        11009 format(f10.3," ! com.env. correlation between ",a8," and ",a8)
        11010 format(a10," ! sire or dam information to be changed")
        11011 format(f10.3," ! number of sires")
        11012 format(f10.3," ! number of dams")
        11013 format(f10.3," ! proportion sires in stage 1")
        11014 format(f10.3," ! number of dams for progeny test")
        11015 format(f10.3," ! number of offspring per dam in progeny test")
        11016 format(f10.3," ! common environmental effect in progeny test ",a8)
        11017 format(i10," ! number of generations")
	11018 format(5x,f10.3," * ",a8)
        11019 format(f10.3," ! proportion dams in stage 1")
        11021 format(f10.3," ! number of male offspring per dam")
	11024 format(5x,a33,i3," for ",a8,"  (",f8.3,")")
        11027 format(f10.3," ! proportion dams in stage 2")
        11020 format("         trait units : ",f10.3,5x,f10.3,5x,f10.3)
        11022 format("      economic units : ",f10.3,5x,f10.3,5x,f10.3)
        11023 format(" % of total response : ",f10.3,5x,f10.3,5x,f10.3)
        11026 format(f10.3," ! proportion sires in stage 2")
        11028 format(f10.3," ! number of female offspring per dam")

        close(unit=20)

        end subroutine sel2s

 !================================================================

        subroutine sel3s

        use selparameters
        use seltools
        use selroutines

	implicit none
        print *,"filename? (max = 8 characters)"
        print *," "
        read *,fnam

        fnamein=trim(fnam)//".in "
        fnameout=trim(fnam)//".out"
        print *,"input is written to ",fnamein
        print *,"output is written to ",fnameout

        open(unit=10, file=fnamein, status="unknown", form="formatted")
        open(unit=20, file=fnameout, status="unknown", form="formatted")

        write(unit=10, fmt=*) "        3 ! stage selection"
        write(unit=10, fmt=*) " ",fnam," ! filenames"

        ! read general info
        print *,"number of traits? "
        print *," "
        read *,ntraits
        write(unit=10, fmt=11001) ntraits

        allocate(sigmaa(ntraits), sigmap(ntraits))
        allocate(sigmaas(ntraits), sigmac(ntraits),sigmaad(ntraits))
        allocate(sigmaaw(ntraits), sigmae(ntraits))
        allocate(covipi(ntraits), hs(ntraits,ntraits))
        allocate(covapiq(ntraits,ntraits), covapaq(ntraits,ntraits))
        allocate(phcorr(ntraits,ntraits), gcorr(ntraits,ntraits))
        allocate(ccorr(ntraits,ntraits), ecorr(ntraits,ntraits))
        allocate(hh(ntraits), cc(ntraits), ccprog(ntraits))
        allocate(response(ntraits), tempev(ntraits,1))
        allocate(xtraits(ntraits), progsigmac(ntraits))
        allocate(fs(ntraits,ntraits), prs(ntraits), prd(ntraits))
        allocate(covp(ntraits,ntraits), covas(ntraits,ntraits),covad(ntraits,ntraits))
        allocate(covaw(ntraits,ntraits), covc(ntraits,ntraits),cove(ntraits,ntraits))

        allocate(scovapi(ntraits), scovipi(ntraits))
        allocate(scovapiq(ntraits,ntraits), scovapaq(ntraits,ntraits))
	allocate(spheninfo(ntraits), s(ntraits,ntraits), response2(ntraits))
        allocate(sresponse(ntraits), d(ntraits,ntraits), sresponse3(ntraits))
        allocate(sdesttraits(ntraits), sdesttraits2(ntraits), response3(ntraits))
	allocate(posgcorr(ntraits), covcprog(ntraits,ntraits), sdesttraits3(ntraits))
	allocate(scovp(ntraits,ntraits), scovas(ntraits,ntraits), scovad(ntraits,ntraits))
        allocate(scovaw(ntraits,ntraits), scovc(ntraits,ntraits), scove(ntraits,ntraits))

        allocate(dcovapi(ntraits), dcovipi(ntraits), dresponse3(ntraits))
        allocate(dcovapiq(ntraits,ntraits), dcovapaq(ntraits,ntraits), msresponse3c(ntraits))
        allocate(dpheninfo(ntraits), sproginfo(ntraits), dproginfo(ntraits))
        allocate(dresponse(ntraits), sresponse2(ntraits), dresponse2(ntraits))
        allocate(ddesttraits(ntraits), ddesttraits2(ntraits), ddesttraits3(ntraits))
        allocate(dcovp(ntraits,ntraits), dcovas(ntraits,ntraits),dcovad(ntraits,ntraits))
        allocate(dcovaw(ntraits,ntraits), dcovc(ntraits,ntraits),dcove(ntraits,ntraits))

        allocate(sresponse3c(ntraits), dresponse3c(ntraits), response3c(ntraits))
        allocate(mssresponse3(ntraits), msdresponse3(ntraits), msresponse3(ntraits))
        allocate(sresponsec(ntraits), sresponse2c(ntraits), mssresponse2c(ntraits))
        allocate(dresponsec(ntraits), dresponse2c(ntraits), msdresponse2c(ntraits))

        allocate(responsec(ntraits), response2c(ntraits), msresponse2c(ntraits))
        allocate(mssresponse2(ntraits), msdresponse2(ntraits), msresponse2(ntraits))

        allocate(mssresponse3c(ntraits), msdresponse3c(ntraits))
        allocate(sits(ntraits), dits(ntraits), sits2(ntraits), dits2(ntraits))
        allocate(sits3(ntraits), dits3(ntraits), sitst(ntraits), ditst(ntraits))


        allocate(v(2,2), dumv(2,2), g(2,1), beta(2,1))

	! group arrays (dimension 20) are only populated for p=1..hsgroups/
	! fsgroups/proggroups by the read loops below; selection_index in
	! selroutines.f90 unconditionally sums/indexes the full 20 elements,
	! so unused slots must be zeroed here rather than left uninitialized.
	fsgroupsoff=0.0
	hsgroupsoff=0.0
	hsgroupsdams=0.0
	proggroupsdams=0.0
	proggroupsoffs=0.0
	proggroupsoffd=0.0

	! economic values in temparray set to zero
	tempev=0
	spheninfo="n"
	dpheninfo="n"
        posgcorr="n"
        sdesttraits="n"
        sdesttraits2="n"
        sdesttraits3="n"
        ddesttraits="n"
        ddesttraits2="n"
        ddesttraits3="n"

        ! get trait information stage 1
630     print *, "use different indices or information sources for sires and dams? y/n"
        print *," "
        read *,indexdiff
        write(unit=10, fmt=11002) indexdiff
        nstag=1
        call traitinfo 	! for sires
        if (indexdiff.eq."y") then
          call traitinfo2     ! for dams
        else
          ddesttraits=sdesttraits
        end if
        sdesttraits2=sdesttraits
        ddesttraits2=ddesttraits

  	! check the number of breeding goal traits
	if (totalh.lt.1) then
	  print *,"the breeding goal must contain 1 trait minimum!"
	  print *,"start over please"
	  goto 630
	end if

        ! get trait information stage 2
        if (ntraits.gt.1) then
          call traitinfo3 	! for sires
          if (indexdiff.eq."y") then
            call traitinfo4     ! for dams
          else
            ddesttraits2=sdesttraits2
          end if
        else
          sdesttraits2(1)="b"
          ddesttraits2(1)="b"
        end if
        sdesttraits3=sdesttraits2
        ddesttraits3=ddesttraits2

        ! get trait information stage 3
        if (ntraits.gt.1) then
          call traitinfo5 	! for sires
          if (indexdiff.eq."y") then
            call traitinfo6     ! for dams
          else
            ddesttraits3=sdesttraits3
          end if
        else
          sdesttraits3(1)="b"
          ddesttraits3(1)="b"
        end if

          ! create vector with economic values
        allocate(ev(totalh,1))
        j=0
        do i=1,ntraits
          if (tempev(i,1).ne.0) then
            j=j+1
            ev(j,1)=tempev(i,1)
          end if
        end do

800	print *,"use of common environmental effects? (y/n):"
        print *," "
	read *,initc
        write(unit=10, fmt=11003) initc
	if (initc.eq."y") then
	  print *,"use of com.env.effects enabled"
	else if (initc.eq."n") then
	  print *,"use of com.env.effects disabled"
	  do p=1,ntraits
	    cc(p)=0
	  end do
	else
          print *,"wrong input!"
	  goto 800
	end if

	! read trait parameters
	do p=1,ntraits
	  print *,"phenotypic variance for ",xtraits(p)," ?"
          print *," "
	  read *,sigmap(p)
          write(unit=10, fmt=11004) sigmap(p),xtraits(p)

900	  print *,"heritability = h-square for ",xtraits(p)," ?"
          print *," "
	  read *,hh(p)
          write(unit=10, fmt=11005) hh(p),xtraits(p)

	  if (hh(p).le.0) then
	    print *,"wrong input, heritability must be higher than 0!"
	    goto 900
	  else if (hh(p).ge.1) then
	    print *,"wrong input, heritability must be lower than 1!"
	    goto 900
	  else
	    print *," "
	  end if

          cc(p)=0
          if (initc.eq."y") then
950         print *,"common environmental effect = c-square for ",xtraits(p)," ?"
            print *," "
            read *,cc(p)
            write(unit=10, fmt=11006) cc(p),xtraits(p)

            if (cc(p).lt.0) then
              print *,"wrong input, com.env.effect must be higher than 0!"
              goto 950
            else if (cc(p).ge.1) then
              print *,"wrong input, com.env.effect must be lower than 1!"
              goto 950
            else
              print *," "
            end if

	    if (cc(p)+hh(p).ge.1) then
	      print *,"heritability + com.env.effect must be lower than 1!"
	      goto 900
	    end if
	  end if
        end do

        ! read number of fs-, hs- and progeny groups
        print *,"use full-sib groups ? y/n"
        print *," "
        read *,initfs
        write(unit=10, fmt=*) "        ",initfs," ! full-sib groups ?"
        if (initfs.eq."y") then
          print *,"number of full-sib groups ? max=20"
          print *," "
          read *,fsgroups
          write(unit=10, fmt='(i10,a21)') fsgroups," ! number of fsgroups"
          do p=1,fsgroups
            print *,"number of animals in full-sib group ",p
            print *," "
            read *,fsgroupsoff(p)
            write(unit=10, fmt='(f10.3,a31,i3)') fsgroupsoff(p)," ! number of animals in fsgroup",p
          end do
        end if
        print *,"use half-sib groups ? y/n"
        print *," "
        read *,iniths
        write(unit=10, fmt=*) "        ",iniths," ! half-sib groups ?"
        if (iniths.eq."y") then
          print *,"number of half-sib groups ? max=20"
          print *," "
          read *,hsgroups
          write(unit=10, fmt='(i10,a21)') hsgroups," ! number of hsgroups"
          do p=1,hsgroups
            print *,"number of dams producing animals in half-sib group ",p
            print *," "
            read *,hsgroupsdams(p)
            write(unit=10, fmt='(f10.3,a29,i3)') hsgroupsdams(p)," ! number of dams in hsgroup ",p
            print *,"number of animals in half-sib group ",p
            print *," "
            read *,hsgroupsoff(p)
            write(unit=10, fmt='(f10.3,a31,i3)') hsgroupsoff(p)," ! number of animals in hsgroup",p
          end do
        end if
        print *,"use progeny groups ? y/n"
        print *," "
        read *,initprog
        write(unit=10, fmt=*) "        ",initprog," ! progeny groups ?"
        if (initprog.eq."y") then
          print *,"number of progeny groups ? max=20"
          print *," "
          read *,proggroups
          write(unit=10, fmt='(i10,a23)') proggroups," ! number of proggroups"
          print *," "
          do p=1,proggroups
            print *,"number of dams producing animals in progeny group ",p
            print *," "
            read *,proggroupsdams(p)
            write(unit=10, fmt='(f10.3,a30,i3)') proggroupsdams(p)," ! number of dams in proggroup",p
   !         print *," if candidate is male :"
            print *," "
            print *,"number of animals in progeny group ",p
            print *," "
            read *,proggroupsoffs(p)
            write(unit=10, fmt='(f10.3,a33,i3)') proggroupsoffs(p)," ! number of animals in proggroup",p
    !        print *," if candidate is female :"
            print *," "
     !       print *,"number of animals in progeny group ",p
      !      print *," "
            proggroupsoffd(p)=proggroupsoffs(p)/proggroupsdams(p)
       !     read *,proggroupsoffd(p)
      !      write(unit=10, fmt='(f10.3,a33,i3)') proggroupsoffd(p)," ! number of animals in proggroup",p
          end do
        end if

        ! initialise source array
        allocate(stempsource(ntraits,84))
        allocate(stempsource2(ntraits,84))
        allocate(stempsource3(ntraits,84))
        allocate(stempsource4(ntraits,84))
        allocate(stempsourcet(ntraits,84))
        allocate(dtempsource(ntraits,84))
        allocate(dtempsource2(ntraits,84))
        allocate(dtempsource3(ntraits,84))
        allocate(dtempsource4(ntraits,84))
        allocate(dtempsourcet(ntraits,84))
        stempsource=0
        stempsource2=0
        stempsource3=0
        stempsource4=0
        stempsourcet=0
        dtempsource=0
        dtempsource2=0
        dtempsource3=0
        dtempsource4=0
        dtempsourcet=0

	! initialize information source counter
	sits=0
	sits2=0
        sits3=0
        sitst=0
	dits=0
	dits2=0
        dits3=0
        ditst=0

        ! input of information sources stage 1 and stage 2
        initindsel="s"
        do p=1,ntraits ! first sires
          if (sdesttraits(p).eq."i" .or. sdesttraits(p).eq."b") then
            nstag=1
	    call info_sources(p,xtraits(p),stempsource,sits(p),stempsourcet, &
             & sitst(p),spheninfo(p),sproginfo(p),initindsel,indexdiff,ntraits, &
             & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
             & hsgroupsoff,proggroupsdams,proggroupsoffs,nstag) ! stage 1
 	  end if
          if (sdesttraits2(p).eq."i" .or. sdesttraits2(p).eq."b") then
	    call info_sources2(p,xtraits(p),stempsourcet,sitst(p),stempsource2, &
             & sits2(p),spheninfo(p),sproginfo(p),initindsel,indexdiff,ntraits, &
             & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
             & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 2
 	  end if

          if (sdesttraits3(p).eq."i" .or. sdesttraits3(p).eq."b") then
	    call info_sources3(p,xtraits(p),stempsourcet,sitst(p),stempsource3, &
             & sits3(p),spheninfo(p),sproginfo(p),initindsel,indexdiff,ntraits, &
             & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
             & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 3
 	  end if
        end do

        if (indexdiff.eq."y") then
          initindsel="d"
          do p=1,ntraits ! then dams
            if (ddesttraits(p).eq."i" .or. ddesttraits(p).eq."b") then
	      call info_sources(p,xtraits(p),dtempsource,dits(p),dtempsourcet, &
               & ditst(p),dpheninfo(p),dproginfo(p),initindsel,indexdiff,ntraits, &
               & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
               & hsgroupsoff,proggroupsdams,proggroupsoffd,nstag) ! stage 1
	    end if
            if (ddesttraits2(p).eq."i" .or. ddesttraits2(p).eq."b") then
  	      call info_sources2(p,xtraits(p),dtempsourcet,ditst(p),dtempsource2, &
               & dits2(p),dpheninfo(p),dproginfo(p),initindsel,indexdiff,ntraits, &
               & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
               & hsgroupsoff,proggroupsdams,proggroupsoffd) ! stage 2
	    end if
            if (ddesttraits3(p).eq."i" .or. ddesttraits3(p).eq."b") then
  	      call info_sources3(p,xtraits(p),dtempsourcet,ditst(p),dtempsource3, &
               & dits3(p),dpheninfo(p),dproginfo(p),initindsel,indexdiff,ntraits, &
               & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
               & hsgroupsoff,proggroupsdams,proggroupsoffd) ! stage 2
	    end if
          end do
        else
          dits=sits
          dits2=sits2
          dits3=sits3
          dpheninfo=spheninfo
          dproginfo=sproginfo
          dtempsource=stempsource
          dtempsource2=stempsource2
          dtempsource3=stempsource3
        end if


  !      PRINT *,"tempsource s",stempsource
   !     PRINT *,"tempsource d",dtempsource
     !  PRINT *,"pheninfo s ",spheninfo
      ! PRINT *,"pheninfo d ",dpheninfo

	! read correlations
975	do i=1,ntraits
	  do j=1,ntraits
	    if (j.gt.i) then
1000	      print *,"correlations between ",xtraits(i)," and ",xtraits(j)," ?"
	      print *,"phenotypic ?"
              print *," "
  	      read *,phcorr(i,j)
              write(unit=10, fmt=11007) phcorr(i,j),xtraits(i),xtraits(j)

              if (phcorr(i,j).le.-1 .or. phcorr(i,j).ge.1) then
                print *,"wrong input!"
                goto 1000
              end if
	      print *,"genetic ?"
              print *," "
	      read *,gcorr(i,j)
              write(unit=10, fmt=11008) gcorr(i,j),xtraits(i),xtraits(j)

              if (gcorr(i,j).le.-1 .or. gcorr(i,j).ge.1) then
                print *,"wrong input!"
                goto 1000
              end if
              if (initc.eq."y") then
	        print *,"common environmental ?"
                print *," "
    	        read *,ccorr(i,j)
                write(unit=10, fmt=11009) ccorr(i,j),xtraits(i),xtraits(j)

                if (ccorr(i,j).le.-1 .or. ccorr(i,j).ge.1) then
                  print *,"wrong input!"
                  goto 1000
                end if
              end if
	    end if
	  end do
	end do

	! setup correlations between traits
	do i=1,ntraits
	  do j=1,ntraits
	    if (i.eq.j) then
	      phcorr(i,j)=1
	      gcorr(i,j)=1
              ccorr(i,j)=1
	    else if (j.gt.i) then
              phcorr(j,i)=phcorr(i,j)
              gcorr(j,i)=gcorr(i,j)
              ccorr(j,i)=ccorr(i,j)
	    else
	      continue
	    end if
	  end do
	end do

        ! get selection information
1200    print *,"number of selected sires? "
        print *," "
	read *,nsires
        write(unit=10, fmt=11011) nsires
        print *,"number of selected dams? "
        print *," "
	read *,ndams
        write(unit=10, fmt=11012) ndams
        print *,"number of male selection candidates per dam? "
        print *," "
	read *,noffs
        write(unit=10, fmt=11021) noffs
        print *,"number of female selection candidates per dam? "
        print *," "
	read *,noffd
        write(unit=10, fmt=11029) noffd
        print *,"proportion selected sires in stage 1 ? "
        print *," "
        read *,pvals
        write(unit=10, fmt=11013) pvals
        print *,"proportion selected sires in stage 2 ? "
        print *," "
        read *,pvals2
        write(unit=10, fmt=11025) pvals2
        print *,"proportion selected sires in stage 3 ? "
        print *," "
        read *,pvals3
        write(unit=10, fmt=11027) pvals3
        print *,"proportion selected dams in stage 1 ? "
        print *," "
        read *,pvald
        write(unit=10, fmt=11019) pvald
        print *,"proportion selected dams in stage 2 ? "
        print *," "
        read *,pvald2
        write(unit=10, fmt=11026) pvald2
        print *,"proportion selected dams in stage 3 ? "
        print *," "
        read *,pvald3
        write(unit=10, fmt=11028) pvald3
        neffdams=ndams/nsires

        ! check info sources if mating ratio = 1
        initnotematrat="n"
        if (nsires.eq.ndams) then
          spheninfo="n"
          dpheninfo="n"
          do p=1,ntraits
            i=0
            do q=1,sits3(p)
              if (stempsource3(p,q).ge.24 .and. stempsource3(p,q).le.63) then
                initnotematrat="y"
              else
                i=i+1
                stempsource4(p,i)=stempsource3(p,q)
                if (stempsource3(p,q).eq.1) then
                  spheninfo(p)="y"
                else if (stempsource3(p,q).ge.4 .and. stempsource3(p,q).le.23) then
                  spheninfo(p)="y"
                else if (stempsource3(p,q).ge.64 .and. stempsource3(p,q).le.83) then
                  spheninfo(p)="y"
                else
                  continue
                end if
              end if
            end do
            do q=1,84
              if (q.le.i) then
                stempsource3(p,q)=stempsource4(p,q)
              else
                stempsource3(p,q)=0
              end if
            end do
            sits3(p)=i
          end do
          if (indexdiff.eq."y") then
            do p=1,ntraits
              i=0
              do q=1,dits3(p)
                if (dtempsource3(p,q).ge.24 .and. dtempsource3(p,q).le.63) then
                  initnotematrat="y"
                else
                  i=i+1
                  dtempsource4(p,i)=dtempsource3(p,q)
                  if (dtempsource3(p,q).eq.1) then
                    dpheninfo(p)="y"
                  else if (dtempsource3(p,q).ge.4 .and. dtempsource3(p,q).le.23) then
                    dpheninfo(p)="y"
                  else if (dtempsource3(p,q).ge.64 .and. dtempsource3(p,q).le.83) then
                    dpheninfo(p)="y"
                  else
                    continue
                  end if
                end if
              end do
              do q=1,84
                if (q.le.i) then
                  dtempsource3(p,q)=dtempsource4(p,q)
                else
                  dtempsource3(p,q)=0
                end if
              end do
              dits3(p)=i
            end do
          else
            do p=1,ntraits
              do q=1,84
                dtempsource3(p,q)=stempsource3(p,q)
              end do
              dpheninfo(p)=spheninfo(p)
              dits3(p)=sits3(p)
            end do
          end if
        end if
        if (initnotematrat.eq."y") then
          call note_matrat
        end if

        ! check if traits without phenotypic infosources are genetically correlated with
	! traits which do have phenotypic infosources
	if (indexdiff.eq."y") then   ! check sires and dams
1100   	  do i=1,ntraits
	    if (spheninfo(i).eq."n" .and. dpheninfo(i).eq."n") then
	      do j=1,ntraits
	        if (spheninfo(j).eq."y" .or. dpheninfo(j).eq."y") then
	          if (gcorr(i,j).ne.0.0) then
	            posgcorr(i)="y"
	          end if
	        end if
	      end do
	      if (posgcorr(i).eq."n") then
	        call note_pheninfo(xtraits(i),pheninfoinit)
	        if (pheninfoinit.eq."i") then
                  print *," change sire or dam information sources s/d ?"
                  print *," "
                  read *,sourcesd
                  write(unit=10, fmt=11010) sourcesd
                  if (sourcesd.eq."s") then
                    initindsel="s"
	            call info_sources(i,xtraits(i),stempsource,sits(i),stempsourcet, &
                     & sitst(i),spheninfo(i),sproginfo(i),initindsel,indexdiff,ntraits, &
                     & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                     & hsgroupsoff,proggroupsdams,proggroupsoffs,nstag) ! stage 1
              	    call info_sources2(i,xtraits(i),stempsourcet,sitst(i),stempsource2, &
                     & sits2(i),spheninfo(i),sproginfo(i),initindsel,indexdiff,ntraits, &
                     & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                     & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 2
              	    call info_sources3(i,xtraits(i),stempsourcet,sitst(i),stempsource3, &
                     & sits3(i),spheninfo(i),sproginfo(i),initindsel,indexdiff,ntraits, &
                     & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                     & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 3
	            goto 1100
	          else if (sourcesd.eq."d") then
                    initindsel="d"
	            call info_sources(i,xtraits(i),dtempsource,dits(i),dtempsourcet, &
                     & ditst(i),dpheninfo(i),dproginfo(i),initindsel,indexdiff,ntraits, &
                     & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                     & hsgroupsoff,proggroupsdams,proggroupsoffs,nstag) ! stage 1
               	    call info_sources2(i,xtraits(i),dtempsourcet,ditst(i),dtempsource2, &
                     & dits2(i),dpheninfo(i),dproginfo(i),initindsel,indexdiff,ntraits, &
                     & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                     & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 2
               	    call info_sources3(i,xtraits(i),dtempsourcet,ditst(i),dtempsource3, &
                     & dits3(i),dpheninfo(i),dproginfo(i),initindsel,indexdiff,ntraits, &
                     & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                     & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 3
                    goto 1100
                  else
                    continue
	          end if
	        else if (pheninfoinit.eq."c") then
	          do p=1,ntraits
	            if (spheninfo(p).eq."y" .or. dpheninfo(p).eq."y") then
	              if (p.gt.i) then
	                print *,"genetic correlation between:",xtraits(i),"and ",xtraits(p)
	                print *,"was: ",gcorr(i,p)
	                print *,"new value:"
                        print *," "
                        read *,gcorr(i,p)
                        write(unit=10, fmt=11008) gcorr(i,p),xtraits(i),xtraits(p)
                        gcorr(p,i)=gcorr(i,p)
	                goto 1175
	              else if (i.gt.p) then
	                print *,"genetic correlation between:",xtraits(i),"and ",xtraits(p)
                        print *,"was: ",gcorr(i,p)
                        print *,"new value:"
                        print *," "
                        read *,gcorr(p,i)
                        write(unit=10, fmt=11008) gcorr(p,i),xtraits(p),xtraits(i)
                        gcorr(i,p)=gcorr(p,i)
                        goto 1175
	              else
	                continue
	              end if
	            end if
	          end do
	        else
	          continue
	        end if
1175	      end if
	    end if
          end do
        else    ! check sires
1180	  do i=1,ntraits
	    if (spheninfo(i).eq."n") then
	      do j=1,ntraits
	        if (spheninfo(j).eq."y") then
	          if (gcorr(i,j).ne.0.0) then
	            posgcorr(i)="y"
	          end if
	        end if
	      end do
       	      if (posgcorr(i).eq."n") then
	        call note_pheninfo(xtraits(i),pheninfoinit)
	        if (pheninfoinit.eq."i") then
                  initindsel="n"
	          call info_sources(i,xtraits(i),stempsource,sits(i),stempsourcet, &
                   & sitst(i),spheninfo(i),sproginfo(i),initindsel,indexdiff,ntraits, &
                   & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                   & hsgroupsoff,proggroupsdams,proggroupsoffs,nstag) ! stage 1
                  call info_sources2(i,xtraits(i),stempsourcet,sitst(i),stempsource2, &
                   & sits2(i),spheninfo(i),sproginfo(i),initindsel,indexdiff,ntraits, &
                   & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                   & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 2
                  call info_sources3(i,xtraits(i),stempsourcet,sitst(i),stempsource3, &
                   & sits3(i),spheninfo(i),sproginfo(i),initindsel,indexdiff,ntraits, &
                   & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                   & hsgroupsoff,proggroupsdams,proggroupsoffs) ! stage 3
	          dits(i)=sits(i)
	          dits2(i)=sits2(i)
	          dits3(i)=sits3(i)
	          dpheninfo(i)=spheninfo(i)
	          dproginfo(i)=sproginfo(i)
	          dtempsource=stempsource
	          dtempsource2=stempsource2
	          dtempsource3=stempsource3
	          goto 1180
	        else if (pheninfoinit.eq."c") then
	          do p=1,ntraits
	            if (spheninfo(p).eq."y") then
	              if (p.gt.i) then
	                print *,"genetic correlation between:",xtraits(i),"and ",xtraits(p)
	                print *,"was: ",gcorr(i,p)
	                print *,"new value:"
                        print *," "
                        read *,gcorr(i,p)
                        write(unit=10, fmt=11008) gcorr(i,p),xtraits(i),xtraits(p)
                        gcorr(p,i)=gcorr(i,p)
	                goto 1190
	              else if (i.gt.p) then
	                print *,"genetic correlation between:",xtraits(i),"and ",xtraits(p)
                        print *,"was: ",gcorr(i,p)
                        print *,"new value:"
                        print *," "
                        read *,gcorr(p,i)
                        write(unit=10, fmt=11008) gcorr(p,i),xtraits(p),xtraits(i)
                        gcorr(i,p)=gcorr(p,i)
	                goto 1190
	              else
	                continue
	              end if
	            end if
	          end do
	        else
	          continue
	        end if
1190	      end if
            end if
	  end do
        end if

	! get dimension for real p-matrix
	ssumits=0
	ssumits2=0
	ssumits3=0
	dsumits=0
	dsumits2=0
	dsumits3=0
	do p=1,ntraits
	  if (sdesttraits(p).eq."i" .or. sdesttraits(p).eq."b") then
	    ssumits=ssumits+(sits(p)-1)
	  end if
	  if (ddesttraits(p).eq."i" .or. ddesttraits(p).eq."b") then
	    dsumits=dsumits+(dits(p)-1)
	  end if
	  if (sdesttraits2(p).eq."i" .or. sdesttraits2(p).eq."b") then
	    ssumits2=ssumits2+(sits2(p)-1)
	  end if
	  if (ddesttraits2(p).eq."i" .or. ddesttraits2(p).eq."b") then
	    dsumits2=dsumits2+(dits2(p)-1)
	  end if
	  if (sdesttraits3(p).eq."i" .or. sdesttraits3(p).eq."b") then
	    ssumits3=ssumits3+(sits3(p)-1)
	  end if
	  if (ddesttraits3(p).eq."i" .or. ddesttraits3(p).eq."b") then
	    dsumits3=dsumits3+(dits3(p)-1)
	  end if
	end do
    !    print *,"ssumits ",ssumits
     !   print *,"dsumits ",dsumits

        ! get progeny testing information
        if (initprog.eq."y" .and. initc.eq."y") then
          do q=1,ntraits
960         print *,"common environmental effect in the progeny test"
            print *," = c-square for ",xtraits(q)," ?"
            print *," "
            read *,ccprog(q)
            write(unit=10, fmt=11016) ccprog(q),xtraits(q)
            if (ccprog(q).le.0) then
              print *,"wrong input, com.env.effect must be higher than 0!"
              goto 960
            else if (ccprog(q).ge.1) then
              print *,"wrong input, com.env.effect must be lower than 1!"
              goto 960
            else
              continue
            end if
          end do
        end if

        ! get truncation points
        pvalse=pvals*pvals2*pvals3
        pvalde=pvald*pvald2*pvald3
        call trunc(pvalse,dum1,dum2,is3,ks)
        call trunc(pvalde,dum1,dum2,id3,kd)

  !	print *,"ks is",ks,is
   !	print *,"kd id",kd,id


        allocate(sb(ssumits,1), db(dsumits,1), sinvp(ssumits,ssumits))
        allocate(dinvp(dsumits,dsumits))
        allocate(stempcov1(ssumits,1), stempcov2(ssumits,1), srealg(ssumits,ntraits))
        allocate(dtempcov1(dsumits,1), dtempcov2(dsumits,1), drealg(dsumits,ntraits))

        allocate(sb2(ssumits2,1), db2(dsumits2,1), sinvp2(ssumits2,ssumits2))
        allocate(dinvp2(dsumits2,dsumits2))
        allocate(stempcov12(ssumits2,1), stempcov22(ssumits2,1), srealg2(ssumits2,ntraits))
        allocate(dtempcov12(dsumits2,1), dtempcov22(dsumits2,1), drealg2(dsumits2,ntraits))

        allocate(sb3(ssumits3,1), db3(dsumits3,1), sinvp3(ssumits3,ssumits3))
        allocate(dinvp3(dsumits3,dsumits3))
        allocate(srealg3(ssumits3,ntraits), drealg3(dsumits3,ntraits))
   !    allocate(stempcov12(ssumits2,1), stempcov22(ssumits2,1))
    !   allocate(dtempcov12(dsumits2,1), dtempcov22(dsumits2,1)
    !	  print *,"allocaten gaat goed"

        ! variance starting values
        ssigmai=0.0
        do p=1,ntraits
	  sigmaa(p)=hh(p)*sigmap(p)
	  sigmac(p)=cc(p)*sigmap(p)
          progsigmac(p)=ccprog(p)*sigmap(p)
	  sigmaas(p)=0.25*sigmaa(p)
          sigmaad(p)=0.25*sigmaa(p)
	  sigmaaw(p)=0.5*sigmaa(p)
          sigmae(p)=sigmap(p)-sigmaa(p)-sigmac(p)
          if (sdesttraits(p).eq."h" .or. sdesttraits(p).eq."b") then
            temp3sigmai=hh(p)*sigmaa(p)*tempev(p,1)*tempev(p,1)
            ssigmai=ssigmai+temp3sigmai
          end if
          if (indexdiff.eq."y") then
            if (ddesttraits(p).eq."h" .or. ddesttraits(p).eq."b") then
              temp3sigmai=hh(p)*sigmaa(p)*tempev(p,1)*tempev(p,1)
              dsigmai=dsigmai+temp3sigmai
            end if
          else
            dsigmai=ssigmai
          end if
	end do
        ssigmai=ssigmai*(1-ks)
        ssigmai2=ssigmai
        ssigmai3=ssigmai
        dsigmai=dsigmai*(1-kd)
        dsigmai2=dsigmai
        dsigmai3=dsigmai
     !	print *,"varianties zijn goed"

	! covariance starting values
	do p=1,ntraits
          do q=1,ntraits
            scovapi(q)=hh(q)*tempev(q,1)*sigmaa(q)
            dcovapi(q)=scovapi(q)
            covipi(q)=hh(q)*tempev(q,1)*sigmaa(q)
	    covp(p,q)=phcorr(p,q)*(sqrt(sigmap(p))*sqrt(sigmap(q)))
	    covas(p,q)=gcorr(p,q)*(sqrt(sigmaas(p))*sqrt(sigmaas(q)))
	    covad(p,q)=gcorr(p,q)*(sqrt(sigmaad(p))*sqrt(sigmaad(q)))
       	    covaw(p,q)=gcorr(p,q)*(sqrt(sigmaaw(p))*sqrt(sigmaaw(q)))
            covc(p,q)=ccorr(p,q)*(sqrt(sigmac(p))*sqrt(sigmac(q)))
      !      print *,"covc",p,q,covc
            covcprog(p,q)=ccorr(p,q)*(sqrt(progsigmac(p))*sqrt(progsigmac(q)))

            genpart=((sqrt(hh(p)))*(sqrt(hh(q)))*gcorr(p,q))
            comenvpart=((sqrt(cc(p)))*(sqrt(cc(q)))*ccorr(p,q))
            errpart=(sqrt(1-hh(p)-cc(p))*sqrt(1-hh(q)-cc(q)))
 	    ecorr(p,q)=(phcorr(p,q)-genpart-comenvpart)/errpart

	    cove(p,q)=ecorr(p,q)*(sqrt(sigmae(p))*sqrt(sigmae(q)))
 	    covapiq(p,q)=hh(q)*gcorr(p,q)*(sqrt(sigmaa(p))*(sqrt(sigmaa(q))))
            covapaq(p,q)=gcorr(p,q)*(sqrt(sigmaa(p))*(sqrt(sigmaa(q))))
            fs(p,q)=covas(p,q)+covad(p,q)+covc(p,q)
            hs(p,q)=covas(p,q)
            s(p,q)=covapiq(p,q)-((scovapi(p)*covipi(q)*ks)/ssigmai)
            d(p,q)=covapiq(p,q)-((dcovapi(p)*covipi(q)*kd)/dsigmai)
          end do
        end do
  !  	print *,"covarianties zijn goed"

        close(unit=10)

        ! 12 times index calculations for stage 3
        selrounds=25
        response=0
        do p=1,selrounds
          initindsel="s"
!          print *,"sdesttraits2",sdesttraits2
 !         print *,"stempsource2",stempsource2
   	  call selection_index(ntraits,ssigmai3,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,scovapi,ssumits3,sdesttraits3,sits3,stempsource3,sresponse3, &
            & stotalresponse3,srih3,srealg3,sb3,sinvp3,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvalse,nsires,neffdams,noffs,scorrfs3,scorrhs3, &
            & fsgroups,hsgroups,proggroups)
          initindsel="d"
          call selection_index(ntraits,dsigmai3,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,dcovapi,dsumits3,ddesttraits3,dits3,dtempsource3,dresponse3, &
            & dtotalresponse3,drih3,drealg3,db3,dinvp3,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvalde,nsires,neffdams,noffd,dcorrfs3,dcorrhs3, &
            & fsgroups,hsgroups,proggroups)

          call covariance_update(ntraits,ssigmai3,dsigmai3,covp,covas,covad, &
            & covaw,covc,cove,covapaq,ssumits3,sits3,sresponse3,stotalresponse3,srealg3, &
            & sb3,sinvp3,dsumits3,dits3,dresponse3,dtotalresponse3,drealg3,db3,dinvp3,ks,kd, &
            & response3,totalresponse3,tempev,scovapi,dcovapi,fs,hs,s,d)
        end do

    !   do p=1,ntraits
  !        print *,"sresponse2",p,sresponse2(p)
   !       print *,"dresponse2",p,dresponse2(p)
     !  end do
    !    print *,"totalresponse2",(stotalresponse2+dtotalresponse2)/2

        ! 1 time index calculations for stage 1
        initindsel="s"
   	call selection_index(ntraits,ssigmai,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,scovapi,ssumits,sdesttraits,sits,stempsource,sresponse, &
            & stotalresponse,srih,srealg,sb,sinvp,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvals,nsires,neffdams,noffs,scorrfs,scorrhs, &
            & fsgroups,hsgroups,proggroups)
        call covai_update(ntraits,ssigmai,ssumits,sresponsec,stotalresponsec, &
          & srealg,sb,pvals,noffs,neffdams,nsires,scorrfs,scorrhs,srealp)
        call trunc(pvals,dum1,dum2,is,ks)
        isc=rawl3(pvals,noffs,neffdams,nsires,scorrfs,scorrhs)
        do p=1,ntraits
          sresponse(p)=sresponsec(p)*(is/isc)
        end do
        stotalresponse=stotalresponsec*(is/isc)

        initindsel="d"
        call selection_index(ntraits,dsigmai,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,dcovapi,dsumits,ddesttraits,dits,dtempsource,dresponse, &
            & dtotalresponse,drih,drealg,db,dinvp,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvald,nsires,neffdams,noffd,dcorrfs,dcorrhs, &
            & fsgroups,hsgroups,proggroups)
        call covai_update(ntraits,dsigmai,dsumits,dresponsec,dtotalresponsec, &
          & drealg,db,pvald,noffd,neffdams,nsires,dcorrfs,dcorrhs,drealp)
        call trunc(pvald,dum1,dum2,id,kd)
        idc=rawl3(pvald,noffd,neffdams,nsires,dcorrfs,dcorrhs)
        do p=1,ntraits
          dresponse(p)=dresponsec(p)*(id/idc)
        end do
        dtotalresponse=dtotalresponsec*(id/idc)

        ! calculate response and totalresponse based on index 1
        do j=1,ntraits
          response(j)=(sresponse(j)+dresponse(j))/2
          responsec(j)=(sresponsec(j)+dresponsec(j))/2
      !    print *,"response",j,response(j)
        end do
        totalresponse=(stotalresponse+dtotalresponse)/2
        totalresponsec=(stotalresponsec+dtotalresponsec)/2
      !  print *,"totalresponse",totalresponse
       ! print *,"totalresponsec",totalresponsec

	! print output
        call intro(2)

        ! print trait information
        write(unit=20, fmt=*) " TRAITS"
        write(unit=20, fmt=*) " "
        do p=1,ntraits
	  write(unit=20, fmt=*) "   ",xtraits(p)
        end do
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "

        ! print trait parameters
        write(unit=20, fmt=*) "  TRAIT PARAMETERS"
        write(unit=20, fmt=*) "  "
        if (initc.eq."y") then
          write(unit=20, fmt=*) "       phenotypic variance  heritability  com.env.effect"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3,8x,f8.3)') xtraits(p),sigmap(p),hh(p),cc(p)
          end do
        else
          write(unit=20, fmt=*) "       phenotypic variance  heritability"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3)') xtraits(p),sigmap(p),hh(p)
          end do
        end if
        write(unit=20, fmt=*) " "


        if (ntraits.gt.1) then
          ! print phenotypic correlations
          write(unit=20, fmt=*) "  PHENOTYPIC CORRELATIONS"
          write(unit=20, fmt=*) "  "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),(phcorr(p,j), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print genetic correlations
          write(unit=20, fmt=*) "  GENETIC CORRELATIONS"
          write(unit=20, fmt=*) "  "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),(gcorr(p,j), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print common environmental correlations
          if (initc.eq."y") then
            write(unit=20, fmt=*) "  COMMON ENVIRONMENTAL CORRELATIONS"
            write(unit=20, fmt=*) "  "
            write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
            do p=1,ntraits
              write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),(ccorr(p,j), j=1,p)
            end do
          end if
          write(unit=20, fmt=*) " "
        end if

        ! print breeding goal information
        write(unit=20, fmt=*) " BREEDING GOAL INFORMATION"
        write(unit=20, fmt=*) " "
        do p=1,ntraits
	  if (sdesttraits(p).eq."h" .or. sdesttraits(p).eq."b") then
	    write(unit=20, fmt=11018) tempev(p,1),xtraits(p)
          end if
        end do
        write(unit=20, fmt=*) " "

        ! print population parameters
        write(unit=20, fmt=*) "  POPULATION SIZE"
        write(unit=20, fmt=*) "  "
        write(unit=20, fmt='(a49,f8.3)') "                      number of selected sires : ",nsires
        write(unit=20, fmt='(a49,f8.3)') "                       number of selected dams : ",ndams
        write(unit=20, fmt='(a49,f8.3)') " number of male selection candidates per dam   : ",noffs
        write(unit=20, fmt='(a49,f8.3)') " number of female selection candidates per dam : ",noffd
        write(unit=20, fmt=*) " "
        write(unit=20, fmt='(a49,f5.3)')          " selected proportion sires in stage 1 : ",pvals
        write(unit=20, fmt='(a49,f5.3)') "          selected proportion sires in stage 2 : ",pvals2
        write(unit=20, fmt='(a49,f5.3)') "          selected proportion sires in stage 3 : ",pvals3
        write(unit=20, fmt='(a49,f5.3)') "               total selected proportion sires : ",pvals*pvals2*pvals3
        write(unit=20, fmt=*) " "
        write(unit=20, fmt='(a49,f5.3)') "           selected proportion dams in stage 1 : ",pvald
        write(unit=20, fmt='(a49,f5.3)') "           selected proportion dams in stage 2 : ",pvald2
        write(unit=20, fmt='(a49,f5.3)') "           selected proportion dams in stage 3 : ",pvald3
        write(unit=20, fmt='(a49,f5.3)') "                total selected proportion dams : ",pvald*pvald2*pvald3
        write(unit=20, fmt=*) " "
        if (fsgroups.gt.0 .or. hsgroups.gt.0 .or. proggroups.gt.0) then
          write(unit=20, fmt=*) " CHARACTERISTICS OF THE USED GROUPS"
          write(unit=20, fmt=*) " "
        end if

        do i=1,fsgroups
          write(unit=20, fmt=*) " full-sib group ",i," with ",fsgroupsoff(i)," animals"
        end do
        do i=1,hsgroups
          write(unit=20, fmt=*) " half-sib group ",i," with ",hsgroupsdams(i)," dams, producing ",hsgroupsoff(i),"animals"
        end do
        if (proggroups.gt.0) then
          write(unit=20, fmt=*) " progeny group information"
          do i=1,proggroups
            write(unit=20, fmt=*) " progeny group ",i," with ",proggroupsdams(i)," dams, producing",proggroupsoffs(i),"progeny"
          end do
   !       write(unit=20, fmt=*) " progeny group information for dams"
    !      do i=1,proggroups
     !       write(unit=20, fmt=*) " progeny group ",i," with 1 dam, producing",proggroupsoffd(i),"progeny"
      !    end do
        end if

        ! print index 1 information
 	i=0
        write(unit=20, fmt=*) " "
        if (indexdiff.eq."y") then
          write(unit=20, fmt=*) " STAGE 1 INDEX INFORMATION FOR SIRES :"
        else
          write(unit=20, fmt=*) " STAGE 1 INDEX INFORMATION:"
        end if
        write(unit=20, fmt=*) " "
    	xsource(1)="own performance"
     	xsource(2)="ebv of the dam"
        xsource(3)="ebv of the sire"
        do p=4,23
          xsource(p)="information of fs-group "
        end do
        do p=24,43
          xsource(p)="information of hs-group "
        end do
        do p=44,63
          xsource(p)="mean ebv of the dams of hs-group "
        end do
        do p=64,83
          xsource(p)="information of progeny group "
        end do
      	do p=1,ntraits
       	  if (sdesttraits(p).eq."i" .or. sdesttraits(p).eq."b") then
	    do q=1,sits(p)-1
	      i=i+1
              if (stempsource(p,q).le.3) then
      	        write(unit=20, fmt=11000) xsource(stempsource(p,q)),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.4 .and. stempsource(p,q).le.23) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-3),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.24 .and. stempsource(p,q).le.43) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-23),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.44 .and. stempsource(p,q).le.63) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-43),xtraits(p), &
                  & sb(i,1)
              else if (stempsource(p,q).ge.64 .and. stempsource(p,q).le.83) then
      	        write(unit=20, fmt=11024) xsource(stempsource(p,q)),(stempsource(p,q)-63),xtraits(p), &
                  & sb(i,1)
              else
                continue
              end if
            end do
      	    write(unit=20, fmt=*) " "
       	  end if
     	end do
        if (indexdiff.eq."y") then
          i=0
	  write(unit=20, fmt=*) " STAGE 1 INDEX INFORMATION FOR DAMS:"
          do p=1,ntraits
	    if (ddesttraits(p).eq."i" .or. ddesttraits(p).eq."b") then
	      do q=1,dits(p)-1
	        i=i+1
                if (dtempsource(p,q).le.3) then
       	          write(unit=20, fmt=11000) xsource(dtempsource(p,q)),xtraits(p), &
                    & db(i,1)
                else if (dtempsource(p,q).ge.4 .and. dtempsource(p,q).le.23) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-3,xtraits(p), &
                    & db(i,1)
                else if (dtempsource(p,q).ge.24 .and. dtempsource(p,q).le.43) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-23,xtraits(p), &
                    & db(i,1)
                else if (dtempsource(p,q).ge.44 .and. dtempsource(p,q).le.63) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-43,xtraits(p), &
                    & db(i,1)
                else if (dtempsource(p,q).ge.64 .and. dtempsource(p,q).le.83) then
      	          write(unit=20, fmt=11024) xsource(dtempsource(p,q)),dtempsource(p,q)-63,xtraits(p), &
                    & db(i,1)
                else
                  continue
                end if
      	      end do
       	      write(unit=20, fmt=*) " "
	    end if
      	  end do
        end if

        ! 1 time index calculations for stage 2
        initindsel="s"
   	  call selection_index(ntraits,ssigmai2,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,scovapi,ssumits2,sdesttraits2,sits2,stempsource2,sresponse2, &
            & stotalresponse2,srih2,srealg2,sb2,sinvp2,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvals*pvals2,nsires,neffdams,noffs,scorrfs2,scorrhs2, &
            & fsgroups,hsgroups,proggroups)
          initindsel="d"
          call selection_index(ntraits,dsigmai2,sigmah,covp,covas,covad,covaw,covc, &
            & cove,covapaq,dcovapi,dsumits2,ddesttraits2,dits2,dtempsource2,dresponse2, &
            & dtotalresponse2,drih2,drealg2,db2,dinvp2,totalh,initindsel,ev,tempev, &
            & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
            & proggroupsdams,covcprog,pvald*pvald2,nsires,neffdams,noffd,dcorrfs2,dcorrhs2, &
            & fsgroups,hsgroups,proggroups)

        ! print index 2 information
 	i=0
        if (indexdiff.eq."y") then
          write(unit=20, fmt=*) " STAGE 2 INDEX INFORMATION FOR SIRES :"
        else
          write(unit=20, fmt=*) " STAGE 2 INDEX INFORMATION :"
        end if

      	do p=1,ntraits
       	  if (sdesttraits2(p).eq."i" .or. sdesttraits2(p).eq."b") then
	    do q=1,sits2(p)-1
	      i=i+1
              if (stempsource2(p,q).le.3) then
      	        write(unit=20, fmt=11000) xsource(stempsource2(p,q)),xtraits(p), &
                  & sb2(i,1)
              else if (stempsource2(p,q).ge.4 .and. stempsource2(p,q).le.23) then
      	        write(unit=20, fmt=11024) xsource(stempsource2(p,q)),(stempsource2(p,q)-3),xtraits(p), &
                  & sb2(i,1)
              else if (stempsource2(p,q).ge.24 .and. stempsource2(p,q).le.43) then
      	        write(unit=20, fmt=11024) xsource(stempsource2(p,q)),(stempsource2(p,q)-23),xtraits(p), &
                   & sb2(i,1)
              else if (stempsource2(p,q).ge.44 .and. stempsource2(p,q).le.63) then
      	        write(unit=20, fmt=11024) xsource(stempsource2(p,q)),(stempsource2(p,q)-43),xtraits(p), &
                  & sb2(i,1)
              else if (stempsource2(p,q).ge.64 .and. stempsource2(p,q).le.83) then
      	        write(unit=20, fmt=11024) xsource(stempsource2(p,q)),(stempsource2(p,q)-63),xtraits(p), &
                  & sb2(i,1)
              else
                continue
              end if
            end do
      	    write(unit=20, fmt=*) " "
       	  end if
     	end do
        if (indexdiff.eq."y") then
          i=0
          write(unit=20, fmt=*) " STAGE 2 INDEX INFORMATION FOR DAMS :"
          do p=1,ntraits
	    if (ddesttraits2(p).eq."i" .or. ddesttraits2(p).eq."b") then
	      do q=1,dits2(p)-1
	        i=i+1
                if (dtempsource2(p,q).le.3) then
       	          write(unit=20, fmt=11000) xsource(dtempsource2(p,q)),xtraits(p), &
                    & db2(i,1)
                else if (dtempsource2(p,q).ge.4 .and. dtempsource2(p,q).le.23) then
      	          write(unit=20, fmt=11024) xsource(dtempsource2(p,q)),dtempsource2(p,q)-3,xtraits(p), &
                    & db2(i,1)
                else if (dtempsource2(p,q).ge.24 .and. dtempsource2(p,q).le.43) then
      	          write(unit=20, fmt=11024) xsource(dtempsource2(p,q)),dtempsource2(p,q)-23,xtraits(p), &
                    & db2(i,1)
                else if (dtempsource2(p,q).ge.44 .and. dtempsource2(p,q).le.63) then
      	          write(unit=20, fmt=11024) xsource(dtempsource2(p,q)),dtempsource2(p,q)-43,xtraits(p), &
                    & db2(i,1)
                else if (dtempsource2(p,q).ge.64 .and. dtempsource2(p,q).le.83) then
      	          write(unit=20, fmt=11024) xsource(dtempsource2(p,q)),dtempsource2(p,q)-63,xtraits(p), &
                    & db2(i,1)
                else
                  continue
                end if
      	      end do
       	      write(unit=20, fmt=*) " "
	    end if
      	  end do
        end if

        ! print index 3 information
 	i=0
        if (indexdiff.eq."y") then
          write(unit=20, fmt=*) " STAGE 3 INDEX INFORMATION FOR SIRES :"
        else
          write(unit=20, fmt=*) " STAGE 3 INDEX INFORMATION :"
        end if

      	do p=1,ntraits
       	  if (sdesttraits3(p).eq."i" .or. sdesttraits3(p).eq."b") then
	    do q=1,sits3(p)-1
	      i=i+1
              if (stempsource3(p,q).le.3) then
      	        write(unit=20, fmt=11000) xsource(stempsource3(p,q)),xtraits(p), &
                  & sb3(i,1)
              else if (stempsource3(p,q).ge.4 .and. stempsource3(p,q).le.23) then
      	        write(unit=20, fmt=11024) xsource(stempsource3(p,q)),(stempsource3(p,q)-3),xtraits(p), &
                  & sb3(i,1)
              else if (stempsource3(p,q).ge.24 .and. stempsource3(p,q).le.43) then
      	        write(unit=20, fmt=11024) xsource(stempsource3(p,q)),(stempsource3(p,q)-23),xtraits(p), &
                  & sb3(i,1)
              else if (stempsource3(p,q).ge.44 .and. stempsource3(p,q).le.63) then
      	        write(unit=20, fmt=11024) xsource(stempsource3(p,q)),(stempsource3(p,q)-43),xtraits(p), &
                  & sb3(i,1)
              else if (stempsource3(p,q).ge.64 .and. stempsource3(p,q).le.83) then
      	        write(unit=20, fmt=11024) xsource(stempsource3(p,q)),(stempsource3(p,q)-63),xtraits(p), &
                  & sb3(i,1)
              else
                continue
              end if
            end do
      	    write(unit=20, fmt=*) " "
       	  end if
     	end do
        if (indexdiff.eq."y") then
          i=0
          write(unit=20, fmt=*) " STAGE 3 INDEX INFORMATION FOR DAMS :"
          do p=1,ntraits
	    if (ddesttraits3(p).eq."i" .or. ddesttraits3(p).eq."b") then
	      do q=1,dits3(p)-1
	        i=i+1
                if (dtempsource3(p,q).le.3) then
       	          write(unit=20, fmt=11000) xsource(dtempsource3(p,q)),xtraits(p), &
                    & db3(i,1)
                else if (dtempsource3(p,q).ge.4 .and. dtempsource3(p,q).le.23) then
      	          write(unit=20, fmt=11024) xsource(dtempsource3(p,q)),dtempsource3(p,q)-3,xtraits(p), &
                    & db3(i,1)
                else if (dtempsource3(p,q).ge.24 .and. dtempsource3(p,q).le.43) then
      	          write(unit=20, fmt=11024) xsource(dtempsource3(p,q)),dtempsource3(p,q)-23,xtraits(p), &
                    & db3(i,1)
                else if (dtempsource3(p,q).ge.44 .and. dtempsource3(p,q).le.63) then
      	          write(unit=20, fmt=11024) xsource(dtempsource3(p,q)),dtempsource3(p,q)-43,xtraits(p), &
                    & db3(i,1)
                else if (dtempsource3(p,q).ge.64 .and. dtempsource3(p,q).le.83) then
      	          write(unit=20, fmt=11024) xsource(dtempsource3(p,q)),dtempsource3(p,q)-63,xtraits(p), &
                    & db3(i,1)
                else
                  continue
                end if
      	      end do
       	      write(unit=20, fmt=*) " "
	    end if
      	  end do
        end if

        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) "             ******************   RESULTS   *******************"
        print *, "             ******************   RESULTS   *******************"
        write(unit=20, fmt=*) " "
        print *, " "

        ! print equilibrium parameters
        write(unit=20, fmt=*) " EQUILIBRIUM PARAMETERS"
        write(unit=20, fmt=*) " "
        if (initc.eq."y") then
          write(unit=20, fmt=*) "       phenotypic variance  heritability  com.env.effect"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3,8x,f8.3)') xtraits(p),covp(p,p),(covapaq(p,p)/covp(p,p)),(covc(p,p)/covp(p,p))
          end do
        else
          write(unit=20, fmt=*) "       phenotypic variance  heritability"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3)') xtraits(p),covp(p,p),(covapaq(p,p)/covp(p,p))
          end do
        end if
        write(unit=20, fmt=*) " "

        if (ntraits.gt.1) then
          ! print equilibrium phenotypic correlations
          write(unit=20, fmt=*) "  PHENOTYPIC CORRELATIONS"
          write(unit=20, fmt=*) " "
          write(unit=20, fmt=*) "  "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((covp(p,j)/(sqrt(covp(p,p))*sqrt(covp(j,j)))), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print equilibrium genetic correlations
          write(unit=20, fmt=*) "  GENETIC CORRELATIONS"
          write(unit=20, fmt=*) " "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((covapaq(p,j)/(sqrt(covapaq(p,p))*sqrt(covapaq(j,j)))), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print equilibrium common environmental correlations
          if (initc.eq."y") then
            write(unit=20, fmt=*) "  COMMON ENVIRONMENTAL CORRELATIONS"
            write(unit=20, fmt=*) " "
            write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
            do p=1,ntraits
              write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((covc(p,j)/(sqrt(covc(p,p))*sqrt(covc(j,j)))), j=1,p)
            end do
          end if
          write(unit=20, fmt=*) " "
        end if

        ! print response
        write(unit=20, fmt=*) " RESPONSE AFTER STAGE 1"
        write(unit=20, fmt=*) "                           sires           dams          total"
        print *, " RESPONSE AFTER STAGE 1"
        print *, "                           sires           dams          total"
        do p=1,ntraits
          if (sdesttraits(p).eq."b" .or. sdesttraits(p).eq."h") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*sresponsec(p),0.5*dresponsec(p),responsec(p)
            write(unit=20, fmt=11022) 0.5*sresponsec(p)*tempev(p,1),0.5*dresponsec(p)*tempev(p,1),responsec(p)*tempev(p,1)
            write(unit=20, fmt=11023) ((0.5*sresponsec(p)*tempev(p,1))/totalresponsec)*100, &
              & ((0.5*dresponsec(p)*tempev(p,1))/totalresponsec)*100, &
              & ((responsec(p)*tempev(p,1))/totalresponsec)*100
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*sresponsec(p),0.5*dresponsec(p),responsec(p)
            print 11022, 0.5*sresponsec(p)*tempev(p,1),0.5*dresponsec(p)*tempev(p,1),responsec(p)*tempev(p,1)
            print 11023, ((0.5*sresponsec(p)*tempev(p,1))/totalresponsec)*100, &
              & ((0.5*dresponsec(p)*tempev(p,1))/totalresponsec)*100, &
              & ((responsec(p)*tempev(p,1))/totalresponsec)*100
            print *, " "
         end if
        end do
        ! print correlated response
        do p=1,ntraits
          if (sdesttraits(p).eq."i" .or. ddesttraits(p).eq."i") then
            write(unit=20, fmt=*) " CORRELATED RESPONSE AFTER STAGE 1"
            write(unit=20, fmt=*) "                           sires           dams          total"
            print *, " CORRELATED RESPONSE AFTER STAGE 1"
            print *, "                           sires           dams          total"
            goto 10010
          end if
        end do
10010   do p=1,ntraits
          if (sdesttraits(p).eq."i" .or. ddesttraits(p).eq."i") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*sresponsec(p),0.5*dresponsec(p),responsec(p)
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*sresponsec(p),0.5*dresponsec(p),responsec(p)
            print *, " "
          end if
        end do
        ! print total response
        write(unit=20, fmt=*) " TOTAL RESPONSE AFTER STAGE 1"
        write(unit=20, fmt=*) "                           sires           dams          total"
        write(unit=20, fmt=11022) 0.5*stotalresponsec,0.5*dtotalresponsec,totalresponsec
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "
        print *, " TOTAL RESPONSE AFTER STAGE 1"
        print *, "                           sires           dams          total"
        print 11022, 0.5*stotalresponsec,0.5*dtotalresponsec,totalresponsec
        print *, " "
        print *, " "
        if (ssigmai.ne.dsigmai) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "  index variance sires : ",ssigmai,"    index variance dams : ",dsigmai
          print '(a25,f13.3,a26,f13.3)', "  index variance sires : ",ssigmai,"    index variance dams : ",dsigmai
        else
          write(unit=20, fmt='(a25,f13.3)') "        index variance : ",ssigmai
          print '(a25,f13.3)', "        index variance : ",ssigmai
        end if
        write(unit=20, fmt='(a25,f13.3)') "breeding goal variance : ",sigmah
        print '(a25,f13.3)', "breeding goal variance : ",sigmah
        if (srih.ne.drih) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "accuracy of sire index : ",srih,"  accuracy of dam index : ",drih
          print '(a25,f13.3,a26,f13.3)', "accuracy of sire index : ",srih,"  accuracy of dam index : ",drih
        else
          write(unit=20, fmt='(a25,f13.3)') "     accuracy of index : ",srih
          print '(a25,f13.3)', "     accuracy of index : ",srih
        end if
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "
        print *, " "

        ! calculation of truncation points and some conversions of real*8
        call racine
        dumpvals=pvals
        call sseuil1(dumpvals,seuil1)
        print *, "sseuil1 s",seuil1
        dumtrunc1s=seuil1
        trunc1s=dumtrunc1s
        dumpvals=pvals*pvals2
        dumcorrsrih12=srih/srih2
        if (dumcorrsrih12.gt.0.93) then
          dumcorrsrih12=0.93
        end if
        corrsrih12=dumcorrsrih12
        call sseuil2(dumpvals,dumtrunc1s,dumcorrsrih12,seuil2)
        print *, "sseuil2 s",seuil2
        dumtrunc2s=seuil2
        trunc2s=dumtrunc2s
        dumpvald=pvald
        call sseuil1(dumpvald,seuil1)
        dumtrunc1d=seuil1
        print *, "dseuil1 d",seuil1
        trunc1d=dumtrunc1d
        dumpvald=pvald*pvald2
        dumcorrdrih12=drih/drih2
        if (dumcorrdrih12.gt.0.93) then
          dumcorrdrih12=0.93
        end if
   !     print *,"dumcorrdrih12",dumcorrdrih12
        corrdrih12=dumcorrdrih12
        call sseuil2(dumpvald,dumtrunc1d,dumcorrdrih12,seuil2)
        print *, "dseuil2 d",seuil2

    !    print *,"seuil2 2 voorbij"
        dumtrunc2d=seuil2
        trunc2d=dumtrunc2d
        ! calculate response after stage 1 for sires
        pi=3.14159265358979
        tempsresponse1=((2*pi)**(-0.5))*(exp(-0.5*trunc1s*trunc1s))
        t1s=(trunc2s-(corrsrih12*trunc1s))/(sqrt(1-(corrsrih12**2)))

        dumt=t1s
        call sdutt1(20,dumt,dumr)
        tempsresponse2=dumr

        tempsresponse3=((2*pi)**(-0.5))*(exp(-0.5*trunc2s*trunc2s))
  !      print *,"trunc1s",trunc1s
   !     print *,"trunc2s",trunc2s
    !    print *,"corrsrih12",corrsrih12
        t2s=(trunc1s-(corrsrih12*trunc2s))/(sqrt(1-(corrsrih12**2)))

        dumt=t2s
        call sdutt1(20,dumt,dumr)
        tempsresponse4=dumr
 !       print *,"tempsresponse1",tempsresponse1
  !      print *,"tempsresponse2",tempsresponse2
   !     print *,"tempsresponse3",tempsresponse3
    !    print *,"tempsresponse4",tempsresponse4

        msstotalresponse=((tempsresponse1*tempsresponse2)+(corrsrih12*tempsresponse3*tempsresponse4))* &
          & ((sqrt(ssigmai))/(pvals*pvals2))
        ! calculate response after stage 2 for sires
        msstotalresponse2=((tempsresponse3*tempsresponse4)+(corrsrih12*tempsresponse1*tempsresponse2))* &
          & ((sqrt(ssigmai2))/(pvals*pvals2))

        ! calculate response after stage 1 for dams
        tempdresponse1=((2*pi)**(-0.5))*(exp(-0.5*trunc1d*trunc1d))
        t1d=(trunc2d-(corrdrih12*trunc1d))/(sqrt(1-(corrdrih12**2)))

        dumt=t1d
        call sdutt1(20,dumt,dumr)
        tempdresponse2=dumr

        tempdresponse3=((2*pi)**(-0.5))*(exp(-0.5*trunc2d*trunc2d))
  !      print *,"trunc1d",trunc1d
   !     print *,"trunc2d",trunc2d
    !    print *,"corrdrih12",corrdrih12
        t2d=(trunc1d-(corrdrih12*trunc2d))/(sqrt(1-(corrdrih12**2)))

        dumt=t2d
        call sdutt1(20,dumt,dumr)
        tempdresponse4=dumr
  !      print *,"tempdresponse1",tempdresponse1
   !     print *,"tempdresponse2",tempdresponse2
    !    print *,"tempdresponse3",tempdresponse3
     !   print *,"tempdresponse4",tempdresponse4

        msdtotalresponse=((tempdresponse1*tempdresponse2)+(corrdrih12*tempdresponse3*tempdresponse4))* &
          & ((sqrt(dsigmai))/(pvald*pvald2))
        ! calculate response after stage 2 for dams
        msdtotalresponse2=((tempdresponse3*tempdresponse4)+(corrdrih12*tempdresponse1*tempdresponse2))* &
          & ((sqrt(dsigmai2))/(pvald*pvald2))

        ! calculate totalresponse after stage 1
        mstotalresponse=(msstotalresponse+msdtotalresponse)/2
        ! calculate totalresponse after stage 2
        mstotalresponse2=(msstotalresponse2+msdtotalresponse2)/2

        allocate(sgcol(ssumits,1), sgcol2(ssumits2,1), sgcol3(ssumits3,1))
        allocate(dgcol(dsumits,1), dgcol2(dsumits2,1), dgcol3(dsumits3,1))
        ! calculate response per trait after stage 2 for sires
        v(1,1)=ssigmai
        v(1,2)=ssigmai
        v(2,1)=ssigmai
        v(2,2)=ssigmai2
        dumv(1,1)=v(1,1)
        dumv(1,2)=v(1,2)
        dumv(2,1)=v(2,1)
        dumv(2,2)=v(2,2)
        call invrt(dumv,2,2)
        v(1,1)=dumv(1,1)
        v(1,2)=dumv(1,2)
        v(2,1)=dumv(2,1)
        v(2,2)=dumv(2,2)
        do p=1,ntraits
          do q=1,ssumits
            sgcol(q,1)=srealg(q,p)
          end do
          g1=matmul(transpose(sb),sgcol)
          do q=1,ssumits2
            sgcol2(q,1)=srealg2(q,p)
          end do
          g2=matmul(transpose(sb2),sgcol2)
          tempg1=g1(1,1)
          tempg2=g2(1,1)
          g(1,1)=tempg1
          g(2,1)=tempg2
          beta=matmul(v,g)
          mssresponse2(p)=(beta(1,1)*msstotalresponse)+(beta(2,1)*msstotalresponse2)
       !   print *,"mssresponse2",mssresponse2(p)
        end do

        ! calculate response per trait after stage 2 for dams
        v(1,1)=dsigmai
        v(1,2)=dsigmai
        v(2,1)=dsigmai
        v(2,2)=dsigmai2
        dumv(1,1)=v(1,1)
        dumv(1,2)=v(1,2)
        dumv(2,1)=v(2,1)
        dumv(2,2)=v(2,2)
        call invrt(dumv,2,2)
        v(1,1)=dumv(1,1)
        v(1,2)=dumv(1,2)
        v(2,1)=dumv(2,1)
        v(2,2)=dumv(2,2)
        do p=1,ntraits
          do q=1,dsumits
            dgcol(q,1)=drealg(q,p)
          end do
          g1=matmul(transpose(db),dgcol)
          do q=1,dsumits2
            dgcol2(q,1)=drealg2(q,p)
          end do
          g2=matmul(transpose(db2),dgcol2)
          tempg1=g1(1,1)
          tempg2=g2(1,1)
          g(1,1)=tempg1
          g(2,1)=tempg2
          beta=matmul(v,g)
          msdresponse2(p)=(beta(1,1)*msdtotalresponse)+(beta(2,1)*msdtotalresponse2)
        end do

        call trunc(pvals*pvals2,dum1,dum2,is2,ks)
        is2c=rawl3(pvals*pvals2,noffs,neffdams,nsires,scorrfs2,scorrhs2)

        call trunc(pvald*pvald2,dum1,dum2,id2,kd)
        id2c=rawl3(pvald*pvald2,noffd,neffdams,nsires,dcorrfs2,dcorrhs2)

        do p=1,ntraits
          if (tempev(p,1).ne.0) then
            prs(p)=(mssresponse2(p)*tempev(p,1))/msstotalresponse2
            prs(p)=prs(p)/2
            prd(p)=(msdresponse2(p)*tempev(p,1))/msdtotalresponse2
            prd(p)=prd(p)/2
          end if
        end do
        msstotalresponse2c=msstotalresponse2*(is2c/is2)
        msdtotalresponse2c=msdtotalresponse2*(id2c/id2)
        mstotalresponse2c=(msstotalresponse2c+msdtotalresponse2c)/2

        ! print response after stage 2
        write(unit=20, fmt=*) " RESPONSE AFTER STAGE 2"
        write(unit=20, fmt=*) "                           sires           dams          total"
        print *, " RESPONSE AFTER STAGE 2"
        print *, "                           sires           dams          total"
        do p=1,ntraits
          if (sdesttraits2(p).eq."b" .or. sdesttraits2(p).eq."h") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) (prs(p)*msstotalresponse2c)/tempev(p,1),(prd(p)*msdtotalresponse2c)/tempev(p,1), &
              &  ((prs(p)*msstotalresponse2c)/tempev(p,1))+((prd(p)*msdtotalresponse2c)/tempev(p,1))
            write(unit=20, fmt=11022) prs(p)*msstotalresponse2c,prd(p)*msdtotalresponse2c, &
              & (prs(p)*msstotalresponse2c)+(prd(p)*msdtotalresponse2c)
            write(unit=20, fmt=11023) ((prs(p)*msstotalresponse2c)/mstotalresponse2c)*100, &
              & ((prd(p)*msdtotalresponse2c)/mstotalresponse2c)*100, &
              & (((prs(p)*msstotalresponse2c)/mstotalresponse2c)*100)+(((prd(p)*msdtotalresponse2c)/mstotalresponse2c)*100)
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, (prs(p)*msstotalresponse2c)/tempev(p,1),(prd(p)*msdtotalresponse2c)/tempev(p,1), &
              &  ((prs(p)*msstotalresponse2c)/tempev(p,1))+((prd(p)*msdtotalresponse2c)/tempev(p,1))
            print 11022, prs(p)*msstotalresponse2c,prd(p)*msdtotalresponse2c, &
              & (prs(p)*msstotalresponse2c)+(prd(p)*msdtotalresponse2c)
            print 11023, ((prs(p)*msstotalresponse2c)/mstotalresponse2c)*100, &
              & ((prd(p)*msdtotalresponse2c)/mstotalresponse2c)*100, &
              & (((prs(p)*msstotalresponse2c)/mstotalresponse2c)*100)+(((prd(p)*msdtotalresponse2c)/mstotalresponse2c)*100)
            print *, " "
         end if
        end do
        ! print correlated response after stage 2
        do p=1,ntraits
          if (sdesttraits2(p).eq."i" .or. ddesttraits2(p).eq."i") then
            write(unit=20, fmt=*) " CORRELATED RESPONSE AFTER STAGE 2"
            write(unit=20, fmt=*) "                           sires           dams          total"
            print *, " CORRELATED RESPONSE AFTER STAGE 2"
            print *, "                           sires           dams          total"
            goto 10011
          end if
        end do
10011   do p=1,ntraits
          if (sdesttraits2(p).eq."i" .or. ddesttraits2(p).eq."i") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*mssresponse2(p)*(is2c/is2),0.5*msdresponse2(p)*(id2c/id2), &
              &  (0.5*mssresponse2(p)*(is2c/is2))+(0.5*msdresponse2(p)*(id2c/id2))
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*mssresponse2(p)*(is2c/is2),0.5*msdresponse2(p)*(id2c/id2), &
              &  (0.5*mssresponse2(p)*(is2c/is2))+(0.5*msdresponse2(p)*(id2c/id2))
            print *, " "
          end if
        end do
        ! print total response after stage 2
        write(unit=20, fmt=*) " TOTAL RESPONSE AFTER STAGE 2"
        write(unit=20, fmt=*) "                           sires           dams          total"
        write(unit=20, fmt=11022) msstotalresponse2c/2,msdtotalresponse2c/2, &
          & mstotalresponse2c
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "
        print *, " TOTAL RESPONSE AFTER STAGE 2"
        print *, "                           sires           dams          total"
        print 11022, msstotalresponse2c/2,msdtotalresponse2c/2, &
          & mstotalresponse2c
        print *, " "
        print *, " "
        if (ssigmai2.ne.dsigmai2) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "  index variance sires : ",ssigmai2,"    index variance dams : ",dsigmai2
          print '(a25,f13.3,a26,f13.3)', "  index variance sires : ",ssigmai2,"    index variance dams : ",dsigmai2
        else
          write(unit=20, fmt='(a25,f13.3)') "        index variance : ",ssigmai2
          print '(a25,f13.3)', "        index variance : ",ssigmai2
        end if
        write(unit=20, fmt='(a25,f13.3)') "breeding goal variance : ",sigmah
        print '(a25,f13.3)', "breeding goal variance : ",sigmah
        if (srih2.ne.drih2) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "accuracy of sire index : ",srih2,"  accuracy of dam index : ",drih2
          print '(a25,f13.3,a26,f13.3)', "accuracy of sire index : ",srih2,"  accuracy of dam index : ",drih2
        else
          write(unit=20, fmt='(a25,f13.3)') "     accuracy of index : ",srih2
          print '(a25,f13.3)', "     accuracy of index : ",srih2
        end if
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "

        ! index calculations for stage 3
        initindsel="s"
	call selection_index(ntraits,ssigmai3,sigmah,covp,covas,covad,covaw,covc, &
          & cove,covapaq,scovapi,ssumits3,sdesttraits3,sits3,stempsource3,sresponse3, &
          & stotalresponse3,srih3,srealg3,sb3,sinvp3,totalh,initindsel,ev,tempev, &
          & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
          & proggroupsdams,covcprog,pvalse,nsires,neffdams,noffs,scorrfs3,scorrhs3, &
          & fsgroups,hsgroups,proggroups)
        initindsel="d"
        call selection_index(ntraits,dsigmai3,sigmah,covp,covas,covad,covaw,covc, &
          & cove,covapaq,dcovapi,dsumits3,ddesttraits3,dits3,dtempsource3,dresponse3, &
          & dtotalresponse3,drih3,drealg3,db3,dinvp3,totalh,initindsel,ev,tempev, &
          & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd,hsgroupsdams, &
          & proggroupsdams,covcprog,pvalde,nsires,neffdams,noffd,dcorrfs3,dcorrhs3, &
          & fsgroups,hsgroups,proggroups)

        corrsrih12=srih/srih2
        if (corrsrih12.gt.0.93) then
          corrsrih12=0.93
        end if
        corrsrih13=srih/srih3
        if (corrsrih13.gt.0.93) then
          corrsrih13=0.93
        end if
        corrsrih23=srih2/srih3
        if (corrsrih23.gt.0.93) then
          corrsrih23=0.93
        end if
        corrdrih12=drih/drih2
        if (corrdrih12.gt.0.93) then
          corrdrih12=0.93
        end if
        corrdrih13=drih/drih3
        if (corrdrih13.gt.0.93) then
          corrdrih13=0.93
        end if
        corrdrih23=drih2/drih3
        if (corrdrih23.gt.0.93) then
          corrdrih23=0.93
        end if

        dumcorrsrih123=(corrsrih12-corrsrih13*corrsrih23)/((sqrt(1-corrsrih13**2))*(sqrt(1-corrsrih23**2)))
        dumcorrsrih132=0.0
        dumcorrsrih231=(corrsrih23-corrsrih12*corrsrih13)/((sqrt(1-corrsrih12**2))*(sqrt(1-corrsrih13**2)))


     !   print *,"dumcorrsrih123",dumcorrsrih123
      !  print *,"dumcorrsrih132",dumcorrsrih132
       ! print *,"dumcorrsrih231",dumcorrsrih231

        dumcorrdrih123=(corrdrih12-corrdrih13*corrdrih23)/((sqrt(1-corrdrih13**2))*(sqrt(1-corrdrih23**2)))
        dumcorrdrih132=0.0
        dumcorrdrih231=(corrdrih23-corrdrih12*corrdrih13)/((sqrt(1-corrdrih12**2))*(sqrt(1-corrdrih13**2)))

  !      print *,"dumcorrdrih123",dumcorrdrih123
   !     print *,"dumcorrdrih132",dumcorrdrih132
    !    print *,"dumcorrdrih231",dumcorrdrih231

        dumpvals=pvals*pvals2*pvals3
        pvalse=dumpvals
        dumcorrsrih12=corrsrih12
        if (dumcorrsrih12.gt.0.93) then
          dumcorrsrih12=0.93
        end if
        dumcorrsrih13=corrsrih13
        if (dumcorrsrih13.gt.0.93) then
          dumcorrsrih13=0.93
        end if
        dumcorrsrih23=corrsrih23
        if (dumcorrsrih23.gt.0.93) then
          dumcorrsrih23=0.93
        end if
        call sseuil3(dumpvals,dumtrunc1s,dumtrunc2s,dumcorrsrih12,dumcorrsrih13,dumcorrsrih23,seuil3)
        print *, "sseuil3 s",seuil3

        dumtrunc3s=seuil3
        trunc3s=dumtrunc3s

        dumpvald=pvald*pvald2*pvald3
        pvalde=dumpvald
        dumcorrdrih12=corrdrih12
        if (dumcorrdrih12.gt.0.93) then
          dumcorrdrih12=0.93
        end if
        dumcorrdrih13=corrdrih13
        if (dumcorrdrih13.gt.0.93) then
          dumcorrdrih13=0.93
        end if
        dumcorrdrih23=corrdrih23
        if (dumcorrdrih23.gt.0.93) then
          dumcorrdrih23=0.93
        end if
        call sseuil3(dumpvald,dumtrunc1d,dumtrunc2d,dumcorrdrih12,dumcorrdrih13,dumcorrdrih23,seuil3)
        print *, "dseuil3 d",seuil3
        dumtrunc3d=seuil3
        trunc3d=dumtrunc3d

        t12s=(trunc2s-(corrsrih12*trunc1s))/(sqrt(1-(corrsrih12**2)))
        t21s=(trunc1s-(corrsrih12*trunc2s))/(sqrt(1-(corrsrih12**2)))
        t13s=(trunc3s-(corrsrih13*trunc1s))/(sqrt(1-(corrsrih13**2)))
        t31s=(trunc1s-(corrsrih13*trunc3s))/(sqrt(1-(corrsrih13**2)))
        t23s=(trunc3s-(corrsrih23*trunc2s))/(sqrt(1-(corrsrih23**2)))
        t32s=(trunc2s-(corrsrih23*trunc3s))/(sqrt(1-(corrsrih23**2)))
        tempsresponse1=((2*pi)**(-0.5))*(exp(-0.5*trunc1s*trunc1s))
        call sdutt2(20,t12s,t13s,dumcorrsrih231,dutt2)
        tempsresponse2=dutt2
        tempsresponse3=((2*pi)**(-0.5))*(exp(-0.5*trunc2s*trunc2s))
        call sdutt2(20,t21s,t23s,dumcorrsrih132,dutt2)
        tempsresponse4=dutt2
        tempsresponse5=((2*pi)**(-0.5))*(exp(-0.5*trunc3s*trunc3s))
        call sdutt2(20,t31s,t32s,dumcorrsrih123,dutt2)
        tempsresponse6=dutt2
        ! calculate response after stage 1 for sires
        msstotalresponse=((tempsresponse1*tempsresponse2)+(corrsrih12*tempsresponse3* &
          & tempsresponse4)+(corrsrih13*tempsresponse5*tempsresponse6))*((sqrt(ssigmai))/pvalse)
        ! calculate response after stage 2 for sires
        call sdutt2(20,t32s,t31s,dumcorrsrih123,dutt2)
        tempsresponse6=dutt2
        msstotalresponse2=((tempsresponse3*tempsresponse4)+(corrsrih12*tempsresponse1* &
          & tempsresponse2)+(corrsrih23*tempsresponse5*tempsresponse6))*((sqrt(ssigmai2))/pvalse)
        ! calculate response after stage 3 for sires
        call sdutt2(20,t23s,t21s,dumcorrsrih132,dutt2)
        tempsresponse2=dutt2
        call sdutt2(20,t13s,t12s,dumcorrsrih231,dutt2)
        tempsresponse4=dutt2
        msstotalresponse3=((tempsresponse5*tempsresponse6)+(corrsrih23*tempsresponse3* &
          & tempsresponse2)+(corrsrih13*tempsresponse1*tempsresponse4))*((sqrt(ssigmai3))/pvalse)

        t12d=(trunc2d-(corrdrih12*trunc1d))/(sqrt(1-(corrdrih12**2)))
        t21d=(trunc1d-(corrdrih12*trunc2d))/(sqrt(1-(corrdrih12**2)))
        t13d=(trunc3d-(corrdrih13*trunc1d))/(sqrt(1-(corrdrih13**2)))
        t31d=(trunc1d-(corrdrih13*trunc3d))/(sqrt(1-(corrdrih13**2)))
        t23d=(trunc3d-(corrdrih23*trunc2d))/(sqrt(1-(corrdrih23**2)))
        t32d=(trunc2d-(corrdrih23*trunc3d))/(sqrt(1-(corrdrih23**2)))
        tempdresponse1=((2*pi)**(-0.5))*(exp(-0.5*trunc1d*trunc1d))
        call sdutt2(20,t12d,t13d,dumcorrdrih231,dutt2)
        tempdresponse2=dutt2
        tempdresponse3=((2*pi)**(-0.5))*(exp(-0.5*trunc2d*trunc2d))
        call sdutt2(20,t21d,t23d,dumcorrdrih132,dutt2)
        tempdresponse4=dutt2
        tempdresponse5=((2*pi)**(-0.5))*(exp(-0.5*trunc3d*trunc3d))
        call sdutt2(20,t31d,t32d,dumcorrdrih123,dutt2)
        tempdresponse6=dutt2

        ! calculate response after stage 1 for dams
        msdtotalresponse=((tempdresponse1*tempdresponse2)+(corrdrih12*tempdresponse3* &
          & tempdresponse4)+(corrdrih13*tempdresponse5*tempdresponse6))*((sqrt(dsigmai))/pvalde)
        ! calculate response after stage 2 for dams
        call sdutt2(20,t32d,t31d,dumcorrdrih123,dutt2)
        tempdresponse6=dutt2
        msdtotalresponse2=((tempdresponse3*tempdresponse4)+(corrdrih12*tempdresponse1* &
          & tempdresponse2)+(corrdrih23*tempdresponse5*tempdresponse6))*((sqrt(dsigmai2))/pvalde)
        ! calculate response after stage 3 for dams
        call sdutt2(20,t23d,t21d,dumcorrdrih132,dutt2)
        tempdresponse2=dutt2
        call sdutt2(20,t13d,t12d,dumcorrdrih231,dutt2)
        tempdresponse4=dutt2
        msdtotalresponse3=((tempdresponse5*tempdresponse6)+(corrdrih23*tempdresponse3* &
          & tempdresponse2)+(corrdrih13*tempdresponse1*tempdresponse4))*((sqrt(dsigmai3))/pvalde)

        ! calculate totalresponse after stage 1
        mstotalresponse=(msstotalresponse+msdtotalresponse)/2
        ! calculate totalresponse after stage 2
        mstotalresponse2=(msstotalresponse2+msdtotalresponse2)/2
        ! calculate totalresponse after stage 3
        mstotalresponse3=(msstotalresponse3+msdtotalresponse3)/2

        deallocate(v,dumv,g,beta)
        allocate(v(3,3), dumv(3,3), g(3,1), beta(3,1))


        ! calculate response per trait after stage 3 for sires
        v(1,1)=ssigmai
        v(1,2)=ssigmai
        v(1,3)=ssigmai
        v(2,1)=ssigmai
        v(3,1)=ssigmai
        v(2,2)=ssigmai2
        v(2,3)=ssigmai2
        v(3,2)=ssigmai2
        v(3,3)=ssigmai3
        dumv(1,1)=v(1,1)
        dumv(1,2)=v(1,2)
        dumv(1,3)=v(1,3)
        dumv(2,1)=v(2,1)
        dumv(2,2)=v(2,2)
        dumv(2,3)=v(2,3)
        dumv(3,1)=v(3,1)
        dumv(3,2)=v(3,2)
        dumv(3,3)=v(3,3)
        call invrt(dumv,3,3)
        v(1,1)=dumv(1,1)
        v(1,2)=dumv(1,2)
        v(1,3)=dumv(1,3)
        v(2,1)=dumv(2,1)
        v(2,2)=dumv(2,2)
        v(2,3)=dumv(2,3)
        v(3,1)=dumv(3,1)
        v(3,2)=dumv(3,2)
        v(3,3)=dumv(3,3)
        do p=1,ntraits
          do q=1,ssumits
            sgcol(q,1)=srealg(q,p)
          end do
          g1=matmul(transpose(sb),sgcol)
          do q=1,ssumits2
            sgcol2(q,1)=srealg2(q,p)
          end do
          g2=matmul(transpose(sb2),sgcol2)
          do q=1,ssumits3
            sgcol3(q,1)=srealg3(q,p)
          end do
          g3=matmul(transpose(sb3),sgcol3)
          tempg1=g1(1,1)
          tempg2=g2(1,1)
          tempg3=g3(1,1)
          g(1,1)=tempg1
          g(2,1)=tempg2
          g(3,1)=tempg3
          beta=matmul(v,g)
          mssresponse3(p)=(beta(1,1)*msstotalresponse)+(beta(2,1)*msstotalresponse2)+(beta(3,1)*msstotalresponse3)
     !     print *,"mssresponse3",mssresponse3(p)
        end do

        ! calculate response per trait after stage 3 for dams
        v(1,1)=dsigmai
        v(1,2)=dsigmai
        v(1,3)=dsigmai
        v(2,1)=dsigmai
        v(3,1)=dsigmai
        v(2,2)=dsigmai2
        v(2,3)=dsigmai2
        v(3,2)=dsigmai2
        v(3,3)=dsigmai3
        dumv(1,1)=v(1,1)
        dumv(1,2)=v(1,2)
        dumv(1,3)=v(1,3)
        dumv(2,1)=v(2,1)
        dumv(2,2)=v(2,2)
        dumv(2,3)=v(2,3)
        dumv(3,1)=v(3,1)
        dumv(3,2)=v(3,2)
        dumv(3,3)=v(3,3)
        call invrt(dumv,3,3)
        v(1,1)=dumv(1,1)
        v(1,2)=dumv(1,2)
        v(1,3)=dumv(1,3)
        v(2,1)=dumv(2,1)
        v(2,2)=dumv(2,2)
        v(2,3)=dumv(2,3)
        v(3,1)=dumv(3,1)
        v(3,2)=dumv(3,2)
        v(3,3)=dumv(3,3)
        do p=1,ntraits
          do q=1,dsumits
            dgcol(q,1)=drealg(q,p)
          end do
          g1=matmul(transpose(db),dgcol)
          do q=1,dsumits2
            dgcol2(q,1)=drealg2(q,p)
          end do
          g2=matmul(transpose(db2),dgcol2)
          do q=1,dsumits3
            dgcol3(q,1)=drealg3(q,p)
          end do
          g3=matmul(transpose(db3),dgcol3)
          tempg1=g1(1,1)
          tempg2=g2(1,1)
          tempg3=g3(1,1)
          g(1,1)=tempg1
          g(2,1)=tempg2
          g(3,1)=tempg3
          beta=matmul(v,g)
          msdresponse3(p)=(beta(1,1)*msdtotalresponse)+(beta(2,1)*msdtotalresponse2)+(beta(3,1)*msdtotalresponse3)
      !    print *,"msdresponse3",msdresponse3(p)
        end do

        call trunc((pvals*pvals2*pvals3),dum1,dum2,ise,ks)
        isec=rawl3((pvals*pvals2*pvals3),noffs,neffdams,nsires,scorrfs3,scorrhs3)

        call trunc((pvald*pvald2*pvald3),dum1,dum2,ide,kd)
        idec=rawl3((pvald*pvald2*pvald3),noffd,neffdams,nsires,dcorrfs3,dcorrhs3)

        do p=1,ntraits
          if (tempev(p,1).ne.0) then
            prs(p)=(mssresponse3(p)*tempev(p,1))/msstotalresponse3
            prs(p)=prs(p)/2
            prd(p)=(msdresponse3(p)*tempev(p,1))/msdtotalresponse3
            prd(p)=prd(p)/2
          end if
        end do
        msstotalresponse3c=msstotalresponse3*(isec/ise)
        msdtotalresponse3c=msdtotalresponse3*(idec/ide)
        mstotalresponse3c=(msstotalresponse3c+msdtotalresponse3c)/2

        ! print response after stage 3
        write(unit=20, fmt=*) " RESPONSE AFTER STAGE 3"
        write(unit=20, fmt=*) "                           sires           dams          total"
        print *, " RESPONSE AFTER STAGE 3"
        print *, "                           sires           dams          total"
        do p=1,ntraits
          if (sdesttraits3(p).eq."b" .or. sdesttraits3(p).eq."h") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) (prs(p)*msstotalresponse3c)/tempev(p,1),(prd(p)*msdtotalresponse3c)/tempev(p,1), &
              &  ((prs(p)*msstotalresponse3c)/tempev(p,1))+((prd(p)*msdtotalresponse3c)/tempev(p,1))
            write(unit=20, fmt=11022) prs(p)*msstotalresponse3c,prd(p)*msdtotalresponse3c, &
              & (prs(p)*msstotalresponse3c)+(prd(p)*msdtotalresponse3c)
            write(unit=20, fmt=11023) ((prs(p)*msstotalresponse3c)/mstotalresponse3c)*100, &
              & ((prd(p)*msdtotalresponse3c)/mstotalresponse3c)*100, &
              & (((prs(p)*msstotalresponse3c)/mstotalresponse3c)*100)+(((prd(p)*msdtotalresponse3c)/mstotalresponse3c)*100)
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, (prs(p)*msstotalresponse3c)/tempev(p,1),(prd(p)*msdtotalresponse3c)/tempev(p,1), &
              &  ((prs(p)*msstotalresponse3c)+(prd(p)*msdtotalresponse3c)/2)/tempev(p,1)
            print 11022, prs(p)*msstotalresponse3c,prd(p)*msdtotalresponse3c, &
              & (prs(p)*msstotalresponse3c)+(prd(p)*msdtotalresponse3c)/2
            print 11023, ((prs(p)*msstotalresponse3c)/mstotalresponse3c)*100, &
              & ((prd(p)*msdtotalresponse3c)/mstotalresponse3c)*100, &
              & (((prs(p)*msstotalresponse3c)/mstotalresponse3c)*100)+(((prd(p)*msdtotalresponse3c)/mstotalresponse3c)*100)
            print *, " "
         end if
        end do
        ! print correlated response after stage 3
        do p=1,ntraits
          if (sdesttraits3(p).eq."i" .or. ddesttraits3(p).eq."i") then
            write(unit=20, fmt=*) " CORRELATED RESPONSE AFTER STAGE 3"
            write(unit=20, fmt=*) "                           sires           dams          total"
            print *, " CORRELATED RESPONSE AFTER STAGE 3"
            print *, "                           sires           dams          total"
            goto 10012
          end if
        end do
10012   do p=1,ntraits
          if (sdesttraits3(p).eq."i" .or. ddesttraits3(p).eq."i") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*mssresponse3(p)*(isec/ise),0.5*msdresponse3(p)*(idec/ide), &
              &  (0.5*mssresponse3(p)*(isec/ise))+(0.5*msdresponse3(p)*(idec/ide))
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*mssresponse3(p)*(isec/ise),0.5*msdresponse3(p)*(idec/ide), &
              &  (0.5*mssresponse3(p)*(isec/ise))+(0.5*msdresponse3(p)*(idec/ide))
            print *, " "
          end if
        end do
        ! print total response after stage 3
        write(unit=20, fmt=*) " TOTAL RESPONSE AFTER STAGE 3"
        write(unit=20, fmt=*) "                           sires           dams          total"
        write(unit=20, fmt=11022) msstotalresponse3c/2,msdtotalresponse3c/2, &
          & mstotalresponse3c
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "
        print *, " TOTAL RESPONSE AFTER STAGE 3"
        print *, "                           sires           dams          total"
        print 11022, msstotalresponse3c/2,msdtotalresponse3c/2, &
          & mstotalresponse3c
        print *, " "
        print *, " "
        if (ssigmai3.ne.dsigmai3) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "  index variance sires : ",ssigmai3,"    index variance dams : ",dsigmai3
          print '(a25,f13.3,a26,f13.3)', "  index variance sires : ",ssigmai3,"    index variance dams : ",dsigmai3
        else
          write(unit=20, fmt='(a25,f13.3)') "        index variance : ",ssigmai3
          print '(a25,f13.3)', "        index variance : ",ssigmai3
        end if
        write(unit=20, fmt='(a25,f13.3)') "breeding goal variance : ",sigmah
        print '(a25,f13.3)', "breeding goal variance : ",sigmah
        if (srih3.ne.drih3) then
          write(unit=20, fmt='(a25,f13.3,a26,f13.3)') "accuracy of sire index : ",srih3,"  accuracy of dam index : ",drih3
          print '(a25,f13.3,a26,f13.3)', "accuracy of sire index : ",srih3,"  accuracy of dam index : ",drih3
        else
          write(unit=20, fmt='(a25,f13.3)') "     accuracy of index : ",srih3
          print '(a25,f13.3)', "     accuracy of index : ",srih3
        end if
        write(unit=20, fmt=*) " "
        ! check for incoherent parameters
        posdefph="y"
        posdefg="y"
        allocate(jacvec(ntraits))
        call jacobi(phcorr,ntraits,jacvec)
        do p=1,ntraits
       !   print *,"jacvec(p)",jacvec(p)
          if (jacvec(p).lt.0) then
            posdefph="n"
          end if
        end do
        jacvec=0
        call jacobi(gcorr,ntraits,jacvec)
        do p=1,ntraits
       !   print *,"jacvec(p)",jacvec(p)
          if (jacvec(p).lt.0) then
            posdefg="n"
          end if
        end do
        if (posdefph.eq."n" .or. posdefg.eq."n") then
          write(unit=20, fmt=*) " ** incoherent genetic parameters detected"
          print *, " "
          print *, " ** incoherent genetic parameters detected"
        end if
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) "                      ******  end of output  ******"
        print *, " "
        print *, "                      ******  end of output  ******"


        ! format statements
	11000 format(5x,a33,"    for ",a8,"  (",f8.3,")")
        11001 format(i10," ! number of traits")
        11002 format(a10," ! different indices for sires and dams")
        11003 format(a10," ! use of common environment")
        11004 format(f10.3," ! phenotypic variance ",a8)
        11005 format(f10.3," ! heritability ",a8)
        11006 format(f10.3," ! common environmental effect ",a8)
        11007 format(f10.3," ! phenotypic correlation between ",a8," and ",a8)
        11008 format(f10.3," ! genetic correlation between ",a8," and ",a8)
        11009 format(f10.3," ! com.env. correlation between ",a8," and ",a8)
        11010 format(a10," ! sire or dam information to be changed")
        11011 format(f10.3," ! number of sires")
        11012 format(f10.3," ! number of dams")
        11013 format(f10.3," ! proportion sires in stage 1")
        11014 format(f10.3," ! number of dams for progeny test")
        11015 format(f10.3," ! number of offspring per dam in progeny test")
        11016 format(f10.3," ! common environmental effect in progeny test ",a8)
        11017 format(i10," ! number of generations")
	11018 format(5x,f10.3," * ",a8)
        11019 format(f10.3," ! proportion dams in stage 1")
        11021 format(f10.3," ! number of male offspring per dam")
        11029 format(f10.3," ! number of female offspring per dam")
	11024 format(5x,a33,i3," for ",a8,"  (",f8.3,")")
        11025 format(f10.3," ! proportion sires in stage 2")
        11026 format(f10.3," ! proportion dams in stage 2")
        11027 format(f10.3," ! proportion sires in stage 3")
        11028 format(f10.3," ! proportion dams in stage 3")

        11020 format("         trait units : ",f10.3,5x,f10.3,5x,f10.3)
        11022 format("      economic units : ",f10.3,5x,f10.3,5x,f10.3)
        11023 format(" % of total response : ",f10.3,5x,f10.3,5x,f10.3)

        close(unit=20)

        end subroutine sel3s


	end module discrete
