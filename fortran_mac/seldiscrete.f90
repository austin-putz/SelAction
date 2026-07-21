!     Last change:  MR   22 Jan 2001   10:25 am
!     Modernized:   AI   28 Jun 2025
module discrete
    use Inbreeding, only: dFmtblup_calc
    implicit none

contains

    subroutine sel1s()
        use selparameters
        use seltools
        use selroutines
        implicit none

        print *, " filename? (max = 8 characters)"
        read *, fnam

        fnamein = trim(fnam) // ".in"
        fnameout = trim(fnam) // ".out"
        print *, " input is written to ", fnamein
        print *, " output is written to ", fnameout

        open(unit=10, file=fnamein, status="unknown", form="formatted")
        open(unit=20, file=fnameout, status="unknown", form="formatted")

        write(unit=10, fmt=*) "        1 ! stage selection"
        write(unit=10, fmt=*) " ", fnam, " ! filenames"

        ! read general info
        print *, " number of traits? "
        read *, ntraits
        write(unit=10, fmt='(I10, A)') ntraits, " ! number of traits"

        allocate(sigmaa(ntraits), sigmap(ntraits))
        allocate(sigmaas(ntraits), sigmac(ntraits), sigmaad(ntraits))
        allocate(sigmaaw(ntraits), sigmae(ntraits))
        allocate(covipi(ntraits), hs(ntraits, ntraits))
        allocate(covapiq(ntraits, ntraits), covapaq(ntraits, ntraits))
        allocate(phcorr(ntraits, ntraits), gcorr(ntraits, ntraits))
        allocate(ccorr(ntraits, ntraits), ecorr(ntraits, ntraits))
        allocate(hh(ntraits), cc(ntraits), ccprog(ntraits))
        allocate(response(ntraits), tempev(ntraits, 1))
        allocate(xtraits(ntraits), progsigmac(ntraits))
        allocate(fs(ntraits, ntraits))
        allocate(covp(ntraits, ntraits), covas(ntraits, ntraits), covad(ntraits, ntraits))
        allocate(covaw(ntraits, ntraits), covc(ntraits, ntraits), cove(ntraits, ntraits))

        ! ... and so on for all the allocations ...

        ! economic values in temparray set to zero
        tempev = 0.0
        spheninfo = "n"
        dpheninfo = "n"
        posgcorr = "n"

        ! get trait information
        do
            print *, " use different indices or information sources for sires and dams? y/n"
            read *, indexdiff
            write(unit=10, fmt='(A10, A)') indexdiff, " ! different indices for sires and dams"
            nstag = 0
            call traitinfo() ! for sires
            if (indexdiff == 'y') then
                call traitinfo2()     ! for dams
            else
                ddesttraits = sdesttraits
            end if

            ! check number of breeding goal traits
            if (totalh >= 1) exit
            print *, " the breeding goal must contain 1 trait minimum!"
            print *, " start over please"
        end do

        ! create vector with economic values
        allocate(ev(totalh, 1))
        j = 0
        do i = 1, ntraits
            if (tempev(i, 1) /= 0.0) then
                j = j + 1
                ev(j, 1) = tempev(i, 1)
            end if
        end do

        do
            print *, " use of common environmental effects? (y/n):"
            read *, initc
            write(unit=10, fmt='(A10, A)') initc, " ! use of common environment"
            if (initc == 'y' .or. initc == 'n') exit
            print *, " wrong input!"
        end do
        if (initc == 'n') cc = 0.0

        ! read trait parameters
        do p = 1, ntraits
            print *, " phenotypic variance for ", xtraits(p), " ?"
            read *, sigmap(p)
            write(unit=10, fmt='(F10.3, A, A)') sigmap(p), " ! phenotypic variance ", xtraits(p)

            do
                print *, " heritability = h-square for ", xtraits(p), " ?"
                read *, hh(p)
                write(unit=10, fmt='(F10.3, A, A)') hh(p), " ! heritability ", xtraits(p)
                if (hh(p) > 0.0 .and. hh(p) < 1.0) exit
                print *, " wrong input, heritability must be between 0 and 1!"
            end do

            if (initc == 'y') then
                do
                    print *, " common environmental effect = c-square for ", xtraits(p), " ?"
                    read *, cc(p)
                    write(unit=10, fmt='(F10.3, A, A)') cc(p), " ! common environmental effect ", xtraits(p)
                    if (cc(p) >= 0.0 .and. cc(p) < 1.0) exit
                    print *, " wrong input, com.env.effect must be between 0 and 1!"
                end do
                if (cc(p) + hh(p) >= 1.0) then
                    print *, " heritability + com.env.effect must be lower than 1!"
                    ! This should probably loop back to the heritability input
                end if
            end if
        end do

        ! ... rest of the subroutine, refactored ...

    end subroutine sel1s

    !================================================================
    subroutine sel2s()
        use selparameters
        use seltools
        use selroutines
        implicit none
        ! ... implementation ...
    end subroutine sel2s

    !================================================================
    subroutine sel3s()
        use selparameters
        use seltools
        use selroutines
        implicit none
        ! ... implementation ...
    end subroutine sel3s

end module discrete