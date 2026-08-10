!     Last change:  MR    6 Nov 2000    1:30 pm
	module selovlp
        implicit none

        contains

        subroutine ovlp

        use selparameters
        use seltools
        use selroutines

	implicit none
        real :: genints_local, genintd_local, genint_local


        print *,"filename? (max = 8 characters)"
        print *," "
        read *,fnam

        fnamein=trim(fnam)//".in "
        fnameout=trim(fnam)//".out"
        print *,"input is written to ",fnamein
        print *,"output is written to ",fnameout

        open(unit=10, file=fnamein, status="unknown", form="formatted")
        open(unit=20, file=fnameout, status="unknown", form="formatted")

        write(unit=10, fmt=*) "        o ! selection"
        write(unit=10, fmt=*) " ",fnam," ! filenames"

        ! read general info
        print *,"number of traits? "
        print *," "
        read *,ntraits
        write(unit=10, fmt=11001) ntraits
        indexdiff="n"
        nstag=0

        ! get selection information
        print *,"total number of selected sires? "
        print *," "
	read *,nsires
        write(unit=10, fmt=11011) nsires
        print *,"total number of selected dams? "
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
        neffdams=ndams/nsires

        ! read number of ageclasses
        print *,"number of age classes per sex?"
        print *," "
        read *,nclass
        write(unit=10, fmt=11032) nclass
        do p=1,nclass
          print *,"age class ",p,": sire-class ",p,"     age class ",p+nclass,": dam-class ",p
        end do

        allocate(tempsource(2*nclass,ntraits,84), smean(ntraits), tempev(ntraits,1))
        allocate(osigmai(2*nclass), desttraits(ntraits), tempresponse4(1,1))
        allocate(mean(2*nclass,ntraits), pvalcl(2*nclass), xtraits(ntraits))
        allocate(sigmaa(ntraits), sigmap(ntraits), sumits(2*nclass), dmean(ntraits))
        allocate(sigmaas(ntraits), sigmac(ntraits),sigmaad(ntraits))
        allocate(sigmaaw(ntraits), sigmae(ntraits), ccprog(ntraits))
        allocate(hh(ntraits), cc(ntraits), its(2*nclass,ntraits))
        allocate(phcorr(ntraits,ntraits), gcorr(ntraits,ntraits), ccorr(ntraits,ntraits))
        allocate(ecorr(ntraits,ntraits), stempsource(ntraits,84))
        allocate(oresponse(ntraits), sresponse(ntraits), dresponse(ntraits))
        allocate(omatc(ntraits,ntraits), osigmah(1,1))
        allocate(nanim(2*nclass), nselec(2*nclass))

        ! define number of animals in age classes
        print *,"truncation selection or set the number of animals per age-class? t/n"
        print *," "
        read *,initsk
        write(unit=10, fmt=11025) initsk
1340    nanim=0.0
        nselec=0.0
        pvalcl=0.0
        print *," "
        print *,"age class  1  has ",ndams*noffs," male selection candidates"
        print *,"age class ",nclass+1," has ",ndams*noffd," female selection candidates"
        nanim(1)=ndams*noffs
        nanim(nclass+1)=ndams*noffd
        do p=1,2*nclass
          if (p.eq.1 .or. p.eq.(nclass+1)) then
            continue
          else
            if (p.le.nclass) then
              print *," "
              print *,"number of male selection candidates in age class ",p," ?"
              print *," "
              read *,nanim(p)
              write(unit=10, fmt=11026) nanim(p),p
            else
              print *," "
              print *,"number of female selection candidates in age class ",p," ?"
              print *," "
              read *,nanim(p)
              write(unit=10, fmt=11026) nanim(p),p
            end if
          end if
        end do
        sums=0.0
        sumd=0.0
        do p=1,2*nclass
          if (p.le.nclass) then
            sums=sums+nanim(p)
          else
            sumd=sumd+nanim(p)
          end if
        end do
        if (initsk.eq."n") then
          do p=1,2*nclass
            if (p.le.nclass) then
              print *," "
              print *,"number of selected sires in age class ",p," ?"
              print *," "
              read *,nselec(p)
              write(unit=10, fmt=11027) nselec(p),p
              pvalcl(p)=nselec(p)/nanim(p)
            else
              print *," "
              print *,"number of selected dams in age class ",p," ?"
              print *," "
              read *,nselec(p)
              write(unit=10, fmt=11027) nselec(p),p
              pvalcl(p)=nselec(p)/nanim(p)
            end if
          end do
          if (abs(sum(nselec)-(nsires+ndams)).gt.0.1) then
            print *,"the number of selected animals per age-class, is not in agreement with the total"
            print *,"number of selected animals previously defined, start over please"
            goto 1340
          end if
        else
          ! continue ! define truncation selection starting values
          do p=1,2*nclass
            if (p.le.nclass) then
              pvalcl(p)=nsires/sums
       !       print *,pvalcl(p)," in klasse ",p
            else
              pvalcl(p)=ndams/sumd
        !      print *,pvalcl(p)," in klasse ",p
            end if
            nselec(p)=pvalcl(p)*nanim(p)
          end do
        endif

        ! calculate the number of selected animals per sexe
        sselec=0.0
        dselec=0.0
        do p=1,2*nclass
          if (p.le.nclass) then
            sselec=sselec+nselec(p)
       !     print *,sselec
          else
            dselec=dselec+nselec(p)
        !    print *,dselec
          end if
        end do

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

        ! pheninfo/proginfo/posgcorr must be allocated before use; moved
        ! forward from where they were previously allocated (much later,
        ! after the progeny-group input block) since ntraits/nclass are
        ! already known by this point. posgcorr previously had no
        ! allocate at all in this routine.
        allocate(pheninfo(2*nclass,ntraits), proginfo(2*nclass,ntraits))
        allocate(posgcorr(ntraits))

	pheninfo="n"
        posgcorr="n"
        desttraits="n"

        ! get trait information
630     call traitinfoovlp

  	! check the number of breeding goal traits
      !	print *,"totalh",totalh
	if (totalh.lt.1) then
	  print *,"the breeding goal must contain 1 trait minimum!"
	  print *,"start over please"
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
        if (nsires.lt.ndams) then
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
        else
          continue
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
            print *," "
            print *,"number of animals in progeny group ",p
            print *," "
            read *,proggroupsoffs(p)
            write(unit=10, fmt='(f10.3,a33,i3)') proggroupsoffs(p)," ! number of animals in proggroup",p
            print *," "
            proggroupsoffd(p)=proggroupsoffs(p)/proggroupsdams(p)
         !   write(unit=10, fmt='(f10.3,a33,i3)') proggroupsoffd(p)," ! number of animals in proggroup",p
          end do
        end if

        ! initialise source array (pheninfo/proginfo/posgcorr now allocated earlier, see above)

        tempsource=0

	! initialize information source counter
	its=0

        ! input of information sources
        if (initsk.eq."n") then
          do p=1,2*nclass
            if (pvalcl(p).gt.0.0) then
              do q=1,ntraits
                if (desttraits(q).eq."i" .or. desttraits(q).eq."b") then
                  call info_sourcesovlp(q,p,xtraits(q),tempsource,its(p,q), &
                    & pheninfo(p,q),proginfo(p,q),ntraits,nclass, &
                    & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                    & hsgroupsoff,proggroupsdams,proggroupsoffs)
 	        end if
              end do
            end if
          end do
        else
          ! conditions for truncation selection
          ! sires
          print *,"input of information sources for first sire age-class"
          p=1
          do q=1,ntraits
            if (desttraits(q).eq."i" .or. desttraits(q).eq."b") then
              call info_sourcesovlp(q,p,xtraits(q),tempsource,its(p,q), &
                & pheninfo(p,q),proginfo(p,q),ntraits,nclass, &
                & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                & hsgroupsoff,proggroupsdams,proggroupsoffs)
 	    end if
          end do
          oldo=1
1470      print *,"next sire age-class where the index contains more information"
          print *,"or -1 for end of input"
          print *,"age class ?"
          read *,o
          write(unit=10, fmt='(i10,a18)') o," ! next age-class "
          if (o.ne.-1) then
            if (o-oldo.gt.1) then
              do p=oldo+1,o-1
                do q=1,ntraits
                  do r=1,its(oldo,q)
                    tempsource(p,q,r)=tempsource(oldo,q,r)
                  end do
                  its(p,q)=its(oldo,q)
                  pheninfo(p,q)=pheninfo(oldo,q)
                  proginfo(p,q)=proginfo(oldo,q)
                end do
              end do
              p=o
              do q=1,ntraits
                if (desttraits(q).eq."i" .or. desttraits(q).eq."b") then
                  call info_sourcesovlp(q,p,xtraits(q),tempsource,its(p,q), &
                    & pheninfo(p,q),proginfo(p,q),ntraits,nclass, &
                    & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                    & hsgroupsoff,proggroupsdams,proggroupsoffs)
 	        end if
              end do
            else
              p=o
              do q=1,ntraits
                if (desttraits(q).eq."i" .or. desttraits(q).eq."b") then
                  call info_sourcesovlp(q,p,xtraits(q),tempsource,its(p,q), &
                    & pheninfo(p,q),proginfo(p,q),ntraits,nclass, &
                    & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                    & hsgroupsoff,proggroupsdams,proggroupsoffs)
 	        end if
              end do
            end if
            oldo=o
            goto 1470
          else
            ! -1 :end of input sires
            if (oldo.ne.nclass) then
              do p=oldo+1,nclass
                do q=1,ntraits
                  do r=1,its(oldo,q)
                    tempsource(p,q,r)=tempsource(oldo,q,r)
                  end do
                  its(p,q)=its(oldo,q)
                  pheninfo(p,q)=pheninfo(oldo,q)
                  proginfo(p,q)=proginfo(oldo,q)
                end do
              end do
            end if
          end if
          ! dams
          print *,"input of information sources for first dam age-class"
          p=nclass+1
          do q=1,ntraits
            if (desttraits(q).eq."i" .or. desttraits(q).eq."b") then
              call info_sourcesovlp(q,p,xtraits(q),tempsource,its(p,q), &
                & pheninfo(p,q),proginfo(p,q),ntraits,nclass, &
                & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                & hsgroupsoff,proggroupsdams,proggroupsoffs)
 	    end if
          end do
          oldo=nclass+1
1471      print *,"next dam age-class where the index contains more information"
          print *,"or -1 for end of input"
          print *,"age class ?"
          read *,o
          write(unit=10, fmt='(i10,a18)') o," ! next age-class "
          if (o.ne.-1) then
            if (o-oldo.gt.1) then
              do p=oldo+1,o-1
                do q=1,ntraits
                  do r=1,its(oldo,q)
                    tempsource(p,q,r)=tempsource(oldo,q,r)
                  end do
                  its(p,q)=its(oldo,q)
                  pheninfo(p,q)=pheninfo(oldo,q)
                  proginfo(p,q)=proginfo(oldo,q)
                end do
              end do
              p=o
              do q=1,ntraits
                if (desttraits(q).eq."i" .or. desttraits(q).eq."b") then
                  call info_sourcesovlp(q,p,xtraits(q),tempsource,its(p,q), &
                    & pheninfo(p,q),proginfo(p,q),ntraits,nclass, &
                    & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                    & hsgroupsoff,proggroupsdams,proggroupsoffs)
 	        end if
              end do
            else
              p=o
              do q=1,ntraits
                if (desttraits(q).eq."i" .or. desttraits(q).eq."b") then
                  call info_sourcesovlp(q,p,xtraits(q),tempsource,its(p,q), &
                    & pheninfo(p,q),proginfo(p,q),ntraits,nclass, &
                    & fsgroups,hsgroups,proggroups,fsgroupsoff,hsgroupsdams, &
                    & hsgroupsoff,proggroupsdams,proggroupsoffs)
 	        end if
              end do
            end if
            oldo=o
            goto 1471
          else
            ! -1 :end of input dams
            if (oldo.ne.2*nclass) then
              do p=oldo+1,2*nclass
                do q=1,ntraits
                  do r=1,its(oldo,q)
                    tempsource(p,q,r)=tempsource(oldo,q,r)
                  end do
                  its(p,q)=its(oldo,q)
                  pheninfo(p,q)=pheninfo(oldo,q)
                  proginfo(p,q)=proginfo(oldo,q)
                end do
              end do
            end if
          end if
        end if

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

        ! check if traits without phenotypic infosources are genetically correlated with
	! traits which do have phenotypic infosources

	! get dimension for real p-matrix
	sumits=0
	do p=1,2*nclass
          do q=1,ntraits
	    if (desttraits(q).eq."i" .or. desttraits(q).eq."b") then
	      sumits(p)=sumits(p)+(its(p,q)-1)
	    end if
          end do
          if (sumits(p).eq.0) then
            pvalcl(p)=0.0
          end if
	end do

        allocate(ocovp(2*nclass,ntraits,ntraits), ocovas(2*nclass,ntraits,ntraits))
        allocate(ocovad(2*nclass,ntraits,ntraits), ocovaw(2*nclass,ntraits,ntraits))
        allocate(ocovapaq(2*nclass,ntraits,ntraits), ocovc(2*nclass,ntraits,ntraits))
        allocate(ocove(2*nclass,ntraits,ntraits), os(2*nclass,ntraits,ntraits))
        allocate(od(2*nclass,ntraits,ntraits), ofs(2*nclass,ntraits,ntraits))
        allocate(ohs(2*nclass,ntraits,ntraits), oi(2*nclass), ok(2*nclass))
        allocate(ocovcprog(2*nclass,ntraits,ntraits), ocovapiq(2*nclass,ntraits,ntraits))
        allocate(scovapi(ntraits), dcovapi(ntraits), oscovapi(2*nclass,ntraits))
        allocate(rih(2*nclass), corrfs(2*nclass), corrhs(2*nclass), progsigmac(ntraits))
        allocate(orealg(2*nclass,maxval(sumits),ntraits), odcovapi(2*nclass,ntraits))
        allocate(ob(2*nclass,maxval(sumits),1), ocovipi(2*nclass,ntraits))
        allocate(sits(ntraits))

        allocate(covp(ntraits,ntraits), covas(ntraits,ntraits))
        allocate(covad(ntraits,ntraits), covaw(ntraits,ntraits))
        allocate(covc(ntraits,ntraits), cove(ntraits,ntraits))
        allocate(covcprog(ntraits,ntraits), covapaq(ntraits,ntraits))
        allocate(fs(ntraits,ntraits), hs(ntraits,ntraits), s(ntraits,ntraits))
        allocate(d(ntraits,ntraits))


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

        ! variance starting values
        osigmai=0.0
        do p=1,ntraits
          sigmaa(p)=hh(p)*sigmap(p)
          sigmac(p)=cc(p)*sigmap(p)
          progsigmac(p)=ccprog(p)*sigmap(p)
          sigmaas(p)=0.25*sigmaa(p)
          sigmaad(p)=0.25*sigmaa(p)
          sigmaaw(p)=0.5*sigmaa(p)
          sigmae(p)=sigmap(p)-sigmaa(p)-sigmac(p)
        end do
        do p=1,2*nclass
          if (pvalcl(p).gt.0.0) then
            do q=1,ntraits
              if (desttraits(q).eq."h" .or. desttraits(q).eq."b") then
                temp3sigmai=hh(q)*sigmaa(q)*(tempev(q,1)**2)
                osigmai(p)=osigmai(p)+temp3sigmai
              end if
            end do
          else
            osigmai(p)=0.0
          end if
        end do
        ! bulmer effect
        do p=1,2*nclass
          if (pvalcl(p).gt.0.0) then
            call trunc(pvalcl(p),dum1,dum2,oi(p),ok(p))
     !       osigmai(p)=osigmai(p)*(1-ok(p))
          end if
        end do

	! covariance starting values
        do o=1,2*nclass
          do p=1,ntraits
            do q=1,ntraits
              oscovapi(o,p)=hh(p)*tempev(p,1)*sigmaa(p)
              odcovapi(o,p)=hh(p)*tempev(p,1)*sigmaa(p)
              ocovipi(o,p)=hh(p)*tempev(p,1)*sigmaa(p)
	          ocovp(o,p,q)=phcorr(p,q)*(sqrt(sigmap(p))*sqrt(sigmap(q)))
	          ocovas(o,p,q)=gcorr(p,q)*(sqrt(sigmaas(p))*sqrt(sigmaas(q)))
	          ocovad(o,p,q)=gcorr(p,q)*(sqrt(sigmaad(p))*sqrt(sigmaad(q)))
       	          ocovaw(o,p,q)=gcorr(p,q)*(sqrt(sigmaaw(p))*sqrt(sigmaaw(q)))
                  ocovc(o,p,q)=ccorr(p,q)*(sqrt(sigmac(p))*sqrt(sigmac(q)))
                  ocovcprog(o,p,q)=ccorr(p,q)*(sqrt(progsigmac(p))*sqrt(progsigmac(q)))

                  genpart=((sqrt(hh(p)))*(sqrt(hh(q)))*gcorr(p,q))
                  comenvpart=((sqrt(cc(p)))*(sqrt(cc(q)))*ccorr(p,q))
                  errpart=(sqrt(1-hh(p)-cc(p))*sqrt(1-hh(q)-cc(q)))
 	          ecorr(p,q)=(phcorr(p,q)-genpart-comenvpart)/errpart

	          ocove(o,p,q)=ecorr(p,q)*(sqrt(sigmae(p))*sqrt(sigmae(q)))
 	          ocovapiq(o,p,q)=hh(q)*gcorr(p,q)*(sqrt(sigmaa(p))*(sqrt(sigmaa(q))))
                  ocovapaq(o,p,q)=gcorr(p,q)*(sqrt(sigmaa(p))*(sqrt(sigmaa(q))))

                  ofs(o,p,q)=ocovas(o,p,q)+ocovad(o,p,q)+ocovc(o,p,q)
                  ohs(o,p,q)=ocovas(o,p,q)
      !           print *,"ocovapiq(o,p,q)",ocovapiq(o,p,q)
       !          print *,"oscovapi(o,p)",oscovapi(o,p)
        !         print *,"ocovipi(o,q)",ocovipi(o,q)
         !        print *,"ok(o)",ok(o)
                  os(o,p,q)=abs(ocovapiq(o,p,q)-((oscovapi(o,p)*ocovipi(o,q)*ok(o))/osigmai(o)))
                  od(o,p,q)=abs(ocovapiq(o,p,q)-((odcovapi(o,p)*ocovipi(o,q)*ok(o))/osigmai(o)))
                end do
              end do
          end do
        !  print *,"os",os
         ! print *,"od",od

          ! calculate generation interval
          genints_local=0
          genintd_local=0
          do p=1,2*nclass
            if (pvalcl(p).gt.0.0) then
              if (p.le.nclass) then
                tempresponse=((nselec(p)*p)/sselec)
                genints_local=genints+tempresponse
              else
                tempresponse=((nselec(p)*(p-nclass))/dselec)
                genintd_local=genintd+tempresponse
              end if
            end if
          end do
    !      print *,"generation interval s",genints
     !     print *,"generation interval d",genintd
          genint_local=(genints_local+genintd_local)/2

        close(unit=10)

        ! index calculations
        call racine
        selrounds=25
        oresponse=0
        do o=1,selrounds
    !      print *," "
   !       print *,"ronde ",o
      !    print *," "
          do p=1,2*nclass
            if (pvalcl(p).gt.0.0) then
       !       print *," "
    !          print *,"age class ",p
  !            print *," "
              do q=1,ntraits
                scovapi(q)=oscovapi(p,q)
                dcovapi(q)=odcovapi(p,q)
                sits(q)=its(p,q)
                do r=1,ntraits
                  covp(q,r)=ocovp(p,q,r)
                  covas(q,r)=ocovas(p,q,r)
                  covad(q,r)=ocovad(p,q,r)
                  covaw(q,r)=ocovaw(p,q,r)
                  covc(q,r)=ocovc(p,q,r)
                  covcprog(q,r)=ocovcprog(p,q,r)
                  cove(q,r)=ocove(p,q,r)
                  covapaq(q,r)=ocovapaq(p,q,r)
                  fs(q,r)=ofs(p,q,r)
                  hs(q,r)=ohs(p,q,r)
                  s(q,r)=os(p,q,r)
                  d(q,r)=od(p,q,r)
                end do
              end do
              do q=1,ntraits
                do r=1,84
                  stempsource(q,r)=tempsource(p,q,r)
                end do
              end do
              allocate(srealg(sumits(p),ntraits), sb(sumits(p),1))
              allocate(sinvp(sumits(p),sumits(p)))
              if (p.le.nclass) then
                initindsel="s"
                ks=ok(p)
                kd=0.0
                call selection_index(ntraits,osigmai(p),sigmah,covp,covas,covad,covaw,covc, &
                  & cove,covapaq,scovapi,sumits(p),desttraits,sits,stempsource,sresponse, &
                  & ototalresponse,rih(p),srealg,sb,sinvp,totalh,initindsel,ev,tempev, &
                  & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd, &
                  & hsgroupsdams,proggroupsdams,covcprog,pvalcl(p), &
                  & nsires,neffdams,noffs,corrfs(p),corrhs(p), &
                  & fsgroups,hsgroups,proggroups)
                call ovlp_cov_update(ntraits,osigmai(p),covp,covas, &
                  & covaw,covc,cove,covapaq,sumits(p),sits,srealg,sb, &
                  & sinvp,ks,tempev,scovapi,fs,hs,s)
              else
                initindsel="d"
                kd=ok(p)
                ks=0.0
                call selection_index(ntraits,osigmai(p),sigmah,covp,covas,covad,covaw,covc, &
                  & cove,covapaq,scovapi,sumits(p),desttraits,sits,stempsource,sresponse, &
                  & ototalresponse,rih(p),srealg,sb,sinvp,totalh,initindsel,ev,tempev, &
                  & fs,hs,s,d,fsgroupsoff,hsgroupsoff,proggroupsoffs,proggroupsoffd, &
                  & hsgroupsdams,proggroupsdams,covcprog,pvalcl(p), &
                  & nsires,neffdams,noffd,corrfs(p),corrhs(p), &
                  & fsgroups,hsgroups,proggroups)
                call ovlp_cov_update(ntraits,osigmai(p),covp,covad, &
                  & covaw,covc,cove,covapaq,sumits(p),sits,srealg,sb, &
                  & sinvp,kd,tempev,dcovapi,fs,hs,d)
              end if
              do q=1,ntraits
                do r=1,ntraits
                  ocovas(p,q,r)=covas(q,r)
                  ocovad(p,q,r)=covad(q,r)
                  ofs(p,q,r)=fs(q,r)
                  ohs(p,q,r)=hs(q,r)
                  os(p,q,r)=s(q,r)
                  od(p,q,r)=d(q,r)
                end do
              end do
              do q=1,sumits(p)
                do r=1,ntraits
                  orealg(p,q,r)=srealg(q,r)
                  ob(p,q,1)=sb(q,1)
                end do
              end do
              deallocate(srealg)
              deallocate(sb)
              deallocate(sinvp)
            end if
          end do
          ! calculate totalresponse
          ototalresponse=0
          stotalresponse=0
          dtotalresponse=0
          do p=1,2*nclass
            if (pvalcl(p).gt.0.0) then
              if (p.le.nclass) then
                tempresponse=(oi(p)*sqrt(osigmai(p))*nselec(p))/(genint_local*sselec)
          !      print *,"oi(p)",oi(p)
   !             print *,"osigmai",p,osigmai(p)
            !    print *,"pvalcl(p)",pvalcl(p)
             !   print *,"genints",genints
              !  print *,"sumpvals",sumpvals
                stotalresponse=stotalresponse+tempresponse
              else
                tempresponse=(oi(p)*sqrt(osigmai(p))*nselec(p))/(genint_local*dselec)
      !          print *,"oi(p)",oi(p)
    !            print *,"osigmai",p,osigmai(p)
        !        print *,"pvalcl(p)",pvalcl(p)
         !       print *,"genintd",genintd
          !      print *,"sumpvald",sumpvald
                dtotalresponse=dtotalresponse+tempresponse
              end if
            end if
          end do
          ototalresponse=(stotalresponse+dtotalresponse)/2
      !    print *,"ototalresponse",ototalresponse
          ! calculate response per trait
          oresponse=0
          sresponse=0
          dresponse=0
          do p=1,ntraits
            do q=1,2*nclass
              if (pvalcl(q).gt.0.0) then
                allocate(sb(sumits(q),1))
                allocate(spartrealg(sumits(q),1))
                if (pvalcl(q).gt.0.0) then
                  do r=1,sumits(q)
                    spartrealg(r,1)=orealg(q,r,p)
                    sb(r,1)=ob(q,r,1)
                  end do
                  if (q.le.nclass) then
                    tempresponse4=(matmul(transpose(sb),spartrealg)*oi(q))/(sqrt(osigmai(q)))
                    tempresponse=tempresponse4(1,1)
                    tempresponse=(tempresponse*nselec(q))/(genint_local*sselec)
                    sresponse(p)=sresponse(p)+tempresponse
                  else
                    tempresponse4=(matmul(transpose(sb),spartrealg)*oi(q))/(sqrt(osigmai(q)))
                    tempresponse=tempresponse4(1,1)
                    tempresponse=(tempresponse*nselec(q))/(genint_local*dselec)
                    dresponse(p)=dresponse(p)+tempresponse
                  end if
                end if
                deallocate(sb)
                deallocate(spartrealg)
              end if
            end do
            oresponse(p)=(sresponse(p)+dresponse(p))/2
       !     print *,"oresponse(p)",oresponse(p)
          end do
          ! calculate means
          mean=0.0
          do p=1,ntraits
            do q=1,2*nclass
              if (pvalcl(q).gt.0.0) then
                allocate(sb(sumits(q),1))
                allocate(spartrealg(sumits(q),1))
                if (pvalcl(q).gt.0.0) then
                  do r=1,sumits(q)
                    spartrealg(r,1)=orealg(q,r,p)
                    sb(r,1)=ob(q,r,1)
                  end do
                  if (q.le.nclass) then
                    tempresponse4=(matmul(transpose(sb),spartrealg)*oi(q))/(sqrt(osigmai(q))) ! 1x5 5x1 = 1x1
                    tempresponse=tempresponse4(1,1)
                    mean(q,p)=tempresponse-(q*sresponse(p)) !let op
                  else
                    tempresponse4=(matmul(transpose(sb),spartrealg)*oi(q))/(sqrt(osigmai(q))) ! 1x5 5x1 = 1x1
                    tempresponse=tempresponse4(1,1)
                    mean(q,p)=tempresponse-((q-nclass)*dresponse(p)) !let op
                  end if
                end if
                deallocate(spartrealg)
                deallocate(sb)
              end if
            end do
          end do
          ! calculate overall means
          smean=0.0
          dmean=0.0
          do p=1,ntraits
            do q=1,2*nclass
              if (pvalcl(q).gt.0.0) then
                if (q.le.nclass) then
                  tempresponse=mean(q,p)*(nselec(q)/sselec)
                  smean(p)=smean(p)+tempresponse
                else
                  tempresponse=mean(q,p)*(nselec(q)/dselec)
                  dmean(p)=dmean(p)+tempresponse
                end if
              end if
            end do
          end do
          ! overall update
          covas=0.0
          covad=0.0
          s=0.0
          d=0.0
          do p=1,ntraits
            do q=1,ntraits
              do r=1,2*nclass
                if (pvalcl(r).gt.0.0) then
                  if (r.le.nclass) then
                    !covas
                    tempresponse1=ocovas(r,p,q)*(nselec(r)/sselec)
                    tempresponse2=0.25*(mean(r,p)-smean(p))*(mean(r,q)-smean(q))*(nselec(r)/sselec)
                    covas(p,q)=covas(p,q)+tempresponse1+tempresponse2
                    tempresponse1=os(r,p,q)*(nselec(r)/sselec)
                    tempresponse2=(mean(r,p)-smean(p))*(mean(r,q)-smean(q))*(nselec(r)/sselec)
                    s(p,q)=s(p,q)+tempresponse1+tempresponse2
                  else
                    !covad
                    tempresponse1=ocovad(r,p,q)*(nselec(r)/dselec)
                    tempresponse2=0.25*(mean(r,p)-dmean(p))*(mean(r,q)-dmean(q))*(nselec(r)/dselec)
                    covad(p,q)=covad(p,q)+tempresponse1+tempresponse2
                    tempresponse1=od(r,p,q)*(nselec(r)/dselec)
                    tempresponse2=(mean(r,p)-dmean(p))*(mean(r,q)-dmean(q))*(nselec(r)/dselec)
                    d(p,q)=d(p,q)+tempresponse1+tempresponse2
                  end if
                end if
              end do
            end do
          end do
          do p=1,ntraits
            do q=1,ntraits
              do r=1,2*nclass
        !        if (pvalcl(r).gt.0.0) then
                  ofs(r,p,q)=covas(p,q)+covad(p,q)+covc(p,q)
                  ohs(r,p,q)=covas(p,q)
                  ocovapaq(r,p,q)=covas(p,q)+covad(p,q)+covaw(p,q)
                  ocovp(r,p,q)=covapaq(p,q)+covc(p,q)+cove(p,q)
                  ocovas(r,p,q)=covas(p,q)
                  ocovad(r,p,q)=covad(p,q)
                  os(r,p,q)=s(p,q)
                  od(r,p,q)=d(p,q)
         !       end if
              end do
            end do
          end do
          if (initsk.eq."t") then
            ! sires
            tol=0.0000001
            xl=0.0
            xh=0.0
            xln=0.0
            xhn=0.0
     !       print *,"stotalresponse",stotalresponse
            do p=1,nclass
              if (osigmai(p).gt.0.0) then
                xln=((0.0)-((p-1)*stotalresponse))-(1.5*(sqrt(osigmai(p))))
                xhn=((0.0)-((p-1)*stotalresponse))+(1.5*(sqrt(osigmai(p))))
              end if
              if (xln.lt.xl) then
                xl=xln
              end if
              if (xhn.gt.xh) then
                xh=xhn
              end if
            end do
            initindsel="s"
         !   print *," sires"
            call riddr_root(trunc_delta,zriddr,xl,xh,tol)

            ! dams
            xl=0.0
            xh=0.0
            xln=0.0
            xhn=0.0
            do p=nclass+1,2*nclass
              if (osigmai(p).gt.0.0) then
                xln=((0.0)-((p-nclass-1)*dtotalresponse))-(1.5*(sqrt(osigmai(p))))
                xhn=((0.0)-((p-nclass-1)*dtotalresponse))+(1.5*(sqrt(osigmai(p))))
              end if
              if (xln.lt.xl) then
                xl=xln
              end if
              if (xhn.gt.xh) then
                xh=xhn
              end if
            end do
            initindsel="d"
     !       print *," dams"
            call riddr_root(trunc_delta,zriddr,xl,xh,tol)
            oi=0.0
            ok=0.0
     !       print *," "
        !    print *,"pvalcl ",pvalcl
            do p=1,2*nclass
              if (pvalcl(p).gt.0.0) then
                call trunc(pvalcl(p),dum1,dum2,oi(p),ok(p))
              else
                pvalcl(p)=0.0
                oi(p)=0.0
                ok(p)=0.0
              end if
            end do
            ! update generation interval
            genints_local=0
            genintd_local=0
            do p=1,2*nclass
              if (pvalcl(p).gt.0.0) then
                if (p.le.nclass) then
                  tempresponse=((nselec(p)*p)/sselec)
                  genints_local=genints+tempresponse
                else
                  tempresponse=((nselec(p)*(p-nclass))/dselec)
                  genintd_local=genintd+tempresponse
                end if
              end if
            end do
            genint_local=(genints_local+genintd_local)/2

            sselec=0.0
            dselec=0.0
            do p=1,2*nclass
              if (p.le.nclass) then
                sselec=sselec+nselec(p)
              else
                dselec=dselec+nselec(p)
              end if
            end do

          end if
        end do

    !    print *, " passed computations"



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
 	  if (desttraits(p).eq."h" .or. desttraits(p).eq."b") then
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
        do p=1,2*nclass
          if (pvalcl(p).gt.0.0) then
            if (p.le.nclass) then
              write(unit=20, fmt='(a43,i3,a2,f8.3,a3,f8.1,a3,f8.3)') "    selected proportion sires in age class ",p," :", &
                & pvalcl(p)," x ",nanim(p)," = ",pvalcl(p)*nanim(p)
            else
              write(unit=20, fmt='(a43,i3,a2,f8.3,a3,f8.1,a3,f8.3)') "     selected proportion dams in age class ",p," :", &
                & pvalcl(p)," x ",nanim(p)," = ",pvalcl(p)*nanim(p)
            end if
          end if
        end do
        write(unit=20, fmt=*) " "
        write(unit=20, fmt='(a23,f5.2,a18)') " generation interval : ",(genints_local+genintd_local)/2," cohort intervals"
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
        end if

        ! print index information
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
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " INDEX INFORMATION:"
        write(unit=20, fmt=*) " "
        do o=1,2*nclass
          if (pvalcl(o).gt.0.0) then
            i=0
            write(unit=20, fmt=*) " age class ",o
      	    do p=1,ntraits
       	      if (desttraits(p).eq."i" .or. desttraits(p).eq."b") then
	        do q=1,its(o,p)-1
                  i=i+1
                  if (tempsource(o,p,q).le.3) then
      	            write(unit=20, fmt=11000) xsource(tempsource(o,p,q)),xtraits(p), &
                      & ob(o,i,1)
                  else if (tempsource(o,p,q).ge.4 .and. tempsource(o,p,q).le.23) then
                    write(unit=20, fmt=11024) xsource(tempsource(o,p,q)),(tempsource(o,p,q)-3),xtraits(p), &
                      & ob(o,i,1)
                  else if (tempsource(o,p,q).ge.24 .and. tempsource(o,p,q).le.43) then
      	            write(unit=20, fmt=11024) xsource(tempsource(o,p,q)),(tempsource(o,p,q)-23),xtraits(p), &
                      & ob(o,i,1)
                  else if (tempsource(o,p,q).ge.44 .and. tempsource(o,p,q).le.63) then
      	            write(unit=20, fmt=11024) xsource(tempsource(o,p,q)),(tempsource(o,p,q)-43),xtraits(p), &
                      & ob(o,i,1)
                  else if (tempsource(o,p,q).ge.64 .and. tempsource(o,p,q).le.83) then
      	            write(unit=20, fmt=11024) xsource(tempsource(o,p,q)),(tempsource(o,p,q)-63),xtraits(p), &
                      & ob(o,i,1)
                  else
                    continue
                  end if
                end do
      	        write(unit=20, fmt=*) " "
       	      end if
     	    end do
          end if
        end do

        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) "             ******************   RESULTS   *******************"
        print *, "             ******************   RESULTS   *******************"
        write(unit=20, fmt=*) " "
        print *, " "

        ! print equilibrium parameters
        do p=1,2*nclass
          if (pvalcl(p).gt.0.0) then
            r=p
            goto 18900
          end if
        end do
18900   write(unit=20, fmt=*) " EQUILIBRIUM PARAMETERS"
        write(unit=20, fmt=*) " "
        if (initc.eq."y") then
          write(unit=20, fmt=*) "       phenotypic variance  heritability  com.env.effect"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3,8x,f8.3)') xtraits(p),ocovp(r,p,p),(ocovapaq(r,p,p)/ocovp(r,p,p)), &
              & (ocovc(r,p,p)/ocovp(r,p,p))
          end do
        else
          write(unit=20, fmt=*) "       phenotypic variance  heritability"
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,f10.3,8x,f8.3)') xtraits(p),ocovp(r,p,p),(ocovapaq(r,p,p)/ocovp(r,p,p))
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
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((ocovp(r,p,j)/(sqrt(ocovp(r,p,p))*sqrt(ocovp(r,j,j)))), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print equilibrium genetic correlations
          write(unit=20, fmt=*) "  GENETIC CORRELATIONS"
          write(unit=20, fmt=*) " "
          write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
          do p=1,ntraits
            write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((ocovapaq(r,p,j)/(sqrt(ocovapaq(r,p,p))*sqrt(ocovapaq(r,j,j)))), j=1,p)
          end do
          write(unit=20, fmt=*) " "

          ! print equilibrium common environmental correlations
          if (initc.eq."y") then
            write(unit=20, fmt=*) "  COMMON ENVIRONMENTAL CORRELATIONS"
            write(unit=20, fmt=*) " "
            write(unit=20, fmt='(a12,20a9)') "            ",(xtraits(i), i=1,ntraits)
            do p=1,ntraits
              write(unit=20, fmt='(a8,3x,20f9.3)') xtraits(p),((ocovc(r,p,j)/(sqrt(ocovc(r,p,p))*sqrt(ocovc(r,j,j)))), j=1,p)
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
          if (desttraits(p).eq."b" .or. desttraits(p).eq."h") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*sresponse(p),0.5*dresponse(p),oresponse(p)
            write(unit=20, fmt=11022) 0.5*sresponse(p)*tempev(p,1),0.5*dresponse(p)*tempev(p,1),oresponse(p)*tempev(p,1)
            write(unit=20, fmt=11023) ((0.5*sresponse(p)*tempev(p,1))/ototalresponse)*100, &
              & ((0.5*dresponse(p)*tempev(p,1))/ototalresponse)*100, &
              & ((oresponse(p)*tempev(p,1))/ototalresponse)*100
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*sresponse(p),0.5*dresponse(p),oresponse(p)
            print 11022, 0.5*sresponse(p)*tempev(p,1),0.5*dresponse(p)*tempev(p,1),oresponse(p)*tempev(p,1)
            print 11023, ((0.5*sresponse(p)*tempev(p,1))/ototalresponse)*100, &
              & ((0.5*dresponse(p)*tempev(p,1))/ototalresponse)*100, &
              & ((oresponse(p)*tempev(p,1))/ototalresponse)*100
            print *, " "
         end if
        end do
        ! print correlated response
        do p=1,ntraits
          if (desttraits(p).eq."i") then
            write(unit=20, fmt=*) " CORRELATED RESPONSE"
            write(unit=20, fmt=*) "                           sires           dams          total"
            print *, " CORRELATED RESPONSE"
            print *, "                           sires           dams          total"
            goto 10010
          end if
        end do
10010   do p=1,ntraits
          if (desttraits(p).eq."i") then
            write(unit=20, fmt=*) xtraits(p)
            write(unit=20, fmt=11020) 0.5*sresponse(p),0.5*dresponse(p),oresponse(p)
            write(unit=20, fmt=*) " "
            print *, xtraits(p)
            print 11020, 0.5*sresponse(p),0.5*dresponse(p),oresponse(p)
            print *, " "
          end if
        end do
        ! print total response
        write(unit=20, fmt=*) " TOTAL RESPONSE"
        write(unit=20, fmt=*) "                           sires           dams          total"
        write(unit=20, fmt=11022) 0.5*stotalresponse,0.5*dtotalresponse,ototalresponse
        write(unit=20, fmt=*) " "
        write(unit=20, fmt=*) " "
        print *, " TOTAL RESPONSE"
        print *, "                           sires           dams          total"
        print 11022, 0.5*stotalresponse,0.5*dtotalresponse,ototalresponse
        print *, " "
        print *, " "
        do o=1,2*nclass
          if (pvalcl(o).gt.0.0) then
            write(unit=20, fmt='(a10,i3,a18,f13.3,a21,f7.3)') " age class",o,"  index variance :",osigmai(o), &
              & "  accuracy of index :",rih(o)
            print '(a10,i3,a18,f13.3,a21,f7.3)', " age class",o,"  index variance :",osigmai(o), &
              & "  accuracy of index :",rih(o)
          end if
        end do
        sigmah=0.0
        do p=1,ntraits
          do q=1,ntraits
            omatc(p,q)=ocovapaq(r,p,q)
          end do
        end do
        osigmah=matmul(transpose(tempev),matmul(omatc,tempev))
        sigmah=osigmah(1,1)
        write(unit=20, fmt=*) " "
        write(unit=20, fmt='(a31,f13.3)') "      breeding goal variance :",sigmah
        write(unit=20, fmt=*) " "
        print *, " "
        print '(a31,f13.3)', "     breeding goal variance :",sigmah
        print *, " "
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
63      write(unit=20, fmt=*) " "
        print *, " "
        write(unit=20, fmt=*) "                      ******  end of output  ******"
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
        11020 format("         trait units : ",f10.3,5x,f10.3,5x,f10.3)
        11021 format(f10.3," ! number of male offspring per dam")
        11022 format("      economic units : ",f10.3,5x,f10.3,5x,f10.3)
        11023 format(" % of total response : ",f10.3,5x,f10.3,5x,f10.3)
	11024 format(5x,a33,i3," for ",a8,"  (",f8.3,")")

        11025 format(a10," ! method of selection")
        11026 format(f10.3," ! number of animals in age-class ",i3)
        11027 format(f10.3," ! number of selected animals in age-class ",i3)

        11029 format(f10.3," ! number of female offspring per dam")
        11030 format(i10," ! number of age class")
        11031 format(f10.3," ! proportion selected animals in age class",i3)
        11032 format(i10," ! number of age classes per sex")

        close(unit=20)

        end subroutine ovlp
	end module selovlp
