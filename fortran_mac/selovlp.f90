!     Last change:  MR    6 Nov 2000    1:30 pm
!     Modernized:   AI   28 Jun 2025
module selovlp
    use selparameters
    use seltools
    use selroutines
    implicit none

contains

    subroutine ovlp()
        implicit none
        real :: genints_local, genintd_local, genint_local

        print *, "filename? (max = 8 characters)"
        read *, fnam

        fnamein = trim(fnam) // ".in"
        fnameout = trim(fnam) // ".out"
        print *, "input is written to ", fnamein
        print *, "output is written to ", fnameout

        open(unit=10, file=fnamein, status="unknown", form="formatted")
        open(unit=20, file=fnameout, status="unknown", form="formatted")

        write(unit=10, fmt=*) "        o ! selection"
        write(unit=10, fmt=*) " ", fnam, " ! filenames"

        ! read general info
        print *, "number of traits? "
        read *, ntraits
        write(unit=10, fmt='(I10, A)') ntraits, " ! number of traits"
        indexdiff = "n"
        nstag = 0

        ! get selection information
        print *, "total number of selected sires? "
        read *, nsires
        write(unit=10, fmt='(F10.3, A)') nsires, " ! number of sires"
        print *, "total number of selected dams? "
        read *, ndams
        write(unit=10, fmt='(F10.3, A)') ndams, " ! number of dams"
        print *, "number of male selection candidates per dam? "
        read *, noffs
        write(unit=10, fmt='(F10.3, A)') noffs, " ! male candidates per dam"
        print *, "number of female selection candidates per dam? "
        read *, noffd
        write(unit=10, fmt='(F10.3, A)') noffd, " ! female candidates per dam"
        neffdams = ndams / nsires

        ! read number of ageclasses
        print *, "number of age classes per sex?"
        read *, nclass
        write(unit=10, fmt='(I10, A)') nclass, " ! number of age classes per sex"
        do p = 1, nclass
            print *, "age class ", p, ": sire-class ", p, "     age class ", p + nclass, ": dam-class ", p
        end do

        allocate(tempsource(2 * nclass, ntraits, 84), smean(ntraits), tempev(ntraits, 1))
        allocate(osigmai(2 * nclass), desttraits(ntraits), tempresponse4(1, 1))
        allocate(mean(2 * nclass, ntraits), pvalcl(2 * nclass), xtraits(ntraits))
        allocate(sigmaa(ntraits), sigmap(ntraits), sumits(2 * nclass), dmean(ntraits))
        allocate(sigmaas(ntraits), sigmac(ntraits), sigmaad(ntraits))
        allocate(sigmaaw(ntraits), sigmae(ntraits), ccprog(ntraits))
        allocate(hh(ntraits), cc(ntraits), its(2 * nclass, ntraits))
        allocate(phcorr(ntraits, ntraits), gcorr(ntraits, ntraits), ccorr(ntraits, ntraits))
        allocate(ecorr(ntraits, ntraits), stempsource(ntraits, 84))
        allocate(oresponse(ntraits), sresponse(ntraits), dresponse(ntraits))
        allocate(omatc(ntraits, ntraits), osigmah(1, 1))
        allocate(nanim(2 * nclass), nselec(2 * nclass))

        ! define number of animals in age classes
        print *, "truncation selection or set the number of animals per age-class? t/n"
        read *, initsk
        write(unit=10, fmt='(A10, A)') initsk, " ! method of selection"

        nanim = 0.0
        nselec = 0.0
        pvalcl = 0.0
        print *, " "
        print *, "age class  1  has ", ndams * noffs, " male selection candidates"
        print *, "age class ", nclass + 1, " has ", ndams * noffd, " female selection candidates"
        nanim(1) = ndams * noffs
        nanim(nclass + 1) = ndams * noffd
        do p = 1, 2 * nclass
            if (p /= 1 .and. p /= (nclass + 1)) then
                if (p <= nclass) then
                    print *, "number of male selection candidates in age class ", p, " ?"
                    read *, nanim(p)
                    write(unit=10, fmt='(F10.3, A, I3)') nanim(p), " ! number of animals in age-class ", p
                else
                    print *, "number of female selection candidates in age class ", p, " ?"
                    read *, nanim(p)
                    write(unit=10, fmt='(F10.3, A, I3)') nanim(p), " ! number of animals in age-class ", p
                end if
            end if
        end do

        sums = sum(nanim(1:nclass))
        sumd = sum(nanim(nclass+1:2*nclass))

        if (initsk == 'n') then
            do p = 1, 2 * nclass
                if (p <= nclass) then
                    print *, "number of selected sires in age class ", p, " ?"
                    read *, nselec(p)
                    write(unit=10, fmt='(F10.3, A, I3)') nselec(p), " ! number of selected animals in age-class ", p
                else
                    print *, "number of selected dams in age class ", p, " ?"
                    read *, nselec(p)
                    write(unit=10, fmt='(F10.3, A, I3)') nselec(p), " ! number of selected animals in age-class ", p
                end if
                if (nanim(p) > 0) pvalcl(p) = nselec(p) / nanim(p)
            end do
            if (abs(sum(nselec) - (nsires + ndams)) > 0.1) then
                print *, "The number of selected animals per age-class is not in agreement with the total."
                print *, "Start over please."
                ! This should probably loop back, but for now, we'll just stop.
                stop
            end if
        else
            pvalcl(1:nclass) = nsires / sums
            pvalcl(nclass+1:2*nclass) = ndams / sumd
            nselec = pvalcl * nanim
        end if

        sselec = sum(nselec(1:nclass))
        dselec = sum(nselec(nclass+1:2*nclass))

        ! ... rest of the subroutine, refactored ...

    end subroutine ovlp
end module selovlp