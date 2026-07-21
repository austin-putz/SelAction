!     Last change:  MR   14 Sep 2000    2:09 pm
!     Modernized:   AI   28 Jun 2025
module Inbreeding
    use selroutines, only: trunc
    use seltools, only: sabf
    implicit none
    private
    public :: dFmtblup_calc

contains

    function dFmtblup_calc(nt, nim, nif, infom, infof, v_in, cas, cad, cis, cid, pm, pf, d_in, &
                         bm, bf, vim, vif, rfsmm, rfsmf, rfsff, rhsmm, rhsmf, rhsff, nm, nf, m_in, f_in) result(dF)
        !==================================================================================
        !Calculates the rate of inbreeding for multi-trait selection on BLUP-EBV
        !in discrete generations.
        !==================================================================================
        implicit none
        integer, intent(in) :: nt, nim, nif
        integer, dimension(nt, 84), intent(in) :: infom, infof
        real, dimension(nt), intent(in) :: v_in
        real, dimension(nt, nt), intent(in) :: cas, cad, cis, cid
        real, dimension(nim), intent(in) :: bm
        real, dimension(nif), intent(in) :: bf
        real, intent(in) :: vim, vif, pm, pf, d_in, rfsmm, rfsmf, rfsff, rhsmm, rhsmf, rhsff, nm, nf, m_in, f_in
        real :: dF

        real, dimension(nim, nt) :: Cmm, Cmf
        real, dimension(nif, nt) :: Cfm, Cff
        real :: delf, vsa(2), ssqm, ssqf
        real :: imal, ifem, km, kf, xm, xf
        real, dimension(2, 2) :: glambda, gpi, Imat, big
        real, dimension(2, 1) :: half, dum
        real, dimension(2) :: bb

        ! Selection parameters
        call trunc(pm, xm, imal, km)
        call trunc(pf, xf, ifem, kf)

        ! Variance of the selective advantage
        vsa(1) = sum(v_in * matmul(cas, v_in)) + sum(v_in * matmul(cad, v_in)) / d_in
        vsa(2) = sum(v_in * matmul(cas, v_in)) + sum(v_in * matmul(cad, v_in))

        call create_C(nt, nim, nif, infom, infof, cas, cad, cis, cid, d_in, Cmm, Cmf, Cfm, Cff)

        glambda(1, 1) = sum(bm * matmul(Cmm, v_in)) * imal / (sqrt(vim) * vsa(1))
        glambda(1, 2) = sum(bm * matmul(Cmf, v_in)) * imal / (sqrt(vim) * vsa(2))
        glambda(2, 1) = sum(bf * matmul(Cfm, v_in)) * ifem / (sqrt(vif) * vsa(1))
        glambda(2, 2) = sum(bf * matmul(Cff, v_in)) * ifem / (sqrt(vif) * vsa(2))
        glambda = 0.5 * glambda

        gpi(1, 1) = 0.5 - sum(bm * matmul(Cmm, v_in)) * km / vsa(1)
        gpi(1, 2) = 0.5 - sum(bm * matmul(Cmf, v_in)) * km / vsa(2)
        gpi(2, 1) = 0.5 - sum(bf * matmul(Cfm, v_in)) * kf / vsa(1)
        gpi(2, 2) = 0.5 - sum(bf * matmul(Cff, v_in)) * kf / vsa(2)
        gpi = 0.5 * gpi

        ! Solve beta
        Imat = reshape([1.0, 0.0, 0.0, 1.0], [2, 2])
        half = reshape([0.5, 0.5], [2, 1])
        big = Imat - transpose(gpi)
        ! Invert 2x2 matrix
        big = (1.0 / (big(1, 1) * big(2, 2) - big(1, 2) * big(2, 1))) * &
              reshape([big(2, 2), -big(2, 1), -big(1, 2), big(1, 1)], [2, 2])
        dum = matmul(matmul(big, transpose(glambda)), half)
        bb(:) = dum(:, 1)
        bb(1) = bb(1) / m_in
        bb(2) = bb(2) / f_in

        ! Rate of inbreeding without Poisson correction
        vsa(1) = (sum(v_in * matmul(cas, v_in)) + sum(v_in * matmul(cad, v_in)) / d_in) * (1.0 - 1.0 / m_in)
        vsa(2) = sum(v_in * matmul(cas, v_in)) * (1.0 - 1.0 / m_in) + sum(v_in * matmul(cad, v_in)) * (1.0 - 1.0 / f_in)
        ssqm = 1.0 / (4 * m_in) + bb(1) * bb(1) * vsa(1) * m_in
        ssqf = 1.0 / (4 * f_in) + bb(2) * bb(2) * vsa(2) * f_in
        delf = 0.5 * (ssqm + ssqf)

        call Poissoncorr(delf, pm, pf, m_in, f_in, rfsmm, rfsmf, rfsff, rhsmm, rhsmf, rhsff, &
                         glambda, gpi, vsa, d_in, nm, nf, bb)
        dF = delf
    end function dFmtblup_calc

    !=========================================================================
    subroutine create_C(nt, nim, nif, infom, infof, cas, cad, cis, cid, d_in, Cmm, Cmf, Cfm, Cff)
        !calculates the covariance matrices between the selective advantage of the
        !parent and the info-sources of the offspring.
        implicit none
        integer, intent(in) :: nt, nim, nif
        integer, dimension(nt, 84), intent(in) :: infom, infof
        real, dimension(nt, nt), intent(in) :: cas, cad, cis, cid
        real, intent(in) :: d_in
        real, dimension(nim, nt), intent(out) :: Cmm, Cmf
        real, dimension(nif, nt), intent(out) :: Cfm, Cff
        integer :: i, j, k, counter

        ! Male offspring
        counter = 0
        do i = 1, nt
            do j = 1, 84
                if (infom(i, j) == -1) exit
                counter = counter + 1
                select case (infom(i, j))
                case (1) ! own perf
                    Cmm(counter, :) = 0.5 * cas(i, :) + 0.5 * cad(i, :) / d_in
                    Cmf(counter, :) = 0.5 * cas(i, :) + 0.5 * cad(i, :)
                case (2) ! ebv dam
                    Cmm(counter, :) = cid(i, :) / d_in
                    Cmf(counter, :) = cid(i, :)
                case (3) ! ebv sire
                    Cmm(counter, :) = cis(i, :)
                    Cmf(counter, :) = cis(i, :)
                case (4:23) ! full sibs
                    Cmm(counter, :) = 0.5 * cas(i, :) + 0.5 * cad(i, :) / d_in
                    Cmf(counter, :) = 0.5 * cas(i, :) + 0.5 * cad(i, :)
                case (24:43) ! half sibs
                    Cmm(counter, :) = 0.5 * cas(i, :) + 0.5 * cad(i, :) / d_in
                    Cmf(counter, :) = 0.5 * cas(i, :)
                case (44:63) ! damhs ebv
                    Cmm(counter, :) = cid(i, :) / d_in
                    Cmf(counter, :) = 0.0
                case (64:83) ! progeny
                    Cmm(counter, :) = 0.25 * cas(i, :) + 0.25 * cad(i, :) / d_in
                    Cmf(counter, :) = 0.25 * cas(i, :) + 0.25 * cad(i, :)
                case default
                    print *, 'ERROR, inconsistency in info sources males in function dFmtblup'
                    stop
                end select
            end do
        end do
        if (counter /= nim) then
            print *, 'ERROR IN INFOSOURCES FOR MALES IN FUNCTION dFmtblup'
            stop
        end if

        ! Female offspring
        counter = 0
        do i = 1, nt
            do j = 1, 84
                if (infof(i, j) == -1) exit
                counter = counter + 1
                select case (infof(i, j))
                case (1) ! own perf
                    Cfm(counter, :) = 0.5 * cas(i, :) + 0.5 * cad(i, :) / d_in
                    Cff(counter, :) = 0.5 * cas(i, :) + 0.5 * cad(i, :)
                case (2) ! ebv dam
                    Cfm(counter, :) = cid(i, :) / d_in
                    Cff(counter, :) = cid(i, :)
                case (3) ! ebv sire
                    Cfm(counter, :) = cis(i, :)
                    Cff(counter, :) = cis(i, :)
                case (4:23) ! full sibs
                    Cfm(counter, :) = 0.5 * cas(i, :) + 0.5 * cad(i, :) / d_in
                    Cff(counter, :) = 0.5 * cas(i, :) + 0.5 * cad(i, :)
                case (24:43) ! half sibs
                    Cfm(counter, :) = 0.5 * cas(i, :) + 0.5 * cad(i, :) / d_in
                    Cff(counter, :) = 0.5 * cas(i, :)
                case (44:63) ! damhs ebv
                    Cfm(counter, :) = cid(i, :) / d_in
                    Cff(counter, :) = 0.0
                case (64:83) ! progeny
                    Cfm(counter, :) = 0.25 * cas(i, :) + 0.25 * cad(i, :) / d_in
                    Cff(counter, :) = 0.25 * cas(i, :) + 0.25 * cad(i, :)
                case default
                    print *, 'ERROR, inconsistency in info sources females in function dFmtblup'
                    stop
                end select
            end do
        end do
        if (counter /= nif) then
            print *, 'ERROR IN INFOSOURCES FOR FEMALES IN FUNCTION dFmtblup'
            stop
        end if
    end subroutine create_C

    !=========================================================================
    subroutine Poissoncorr(delf, pm, pf, m_in, f_in, rfsmm, rfsmf, rfsff, rhsmm, rhsmf, rhsff, &
                           glambda, gpi, vsa, d_in, nm, nf, bb)
        !calculates the Poisson correction, see Bijma and Woolliams, Genetics 2000
        implicit none
        real, intent(inout) :: delf
        real, intent(in) :: pm, pf, m_in, f_in, rfsmm, rfsmf, rfsff, rhsmm, rhsmf, rhsff
        real, dimension(2, 2), intent(in) :: glambda, gpi
        real, dimension(2), intent(in) :: vsa, bb
        real, intent(in) :: d_in, nm, nf
        real :: kmfs, kmhs, kffs, kfhs, imfs, iffs, imhs, ifhs, pmfs, pffs, pmhs, pfhs, xmfs, xffs
        real :: xmhs, xfhs, rhofsmm, rhofsmf, rhofsff, rhohsmm, rhohsmf, rhohsff, dum
        real :: cSS_fsm, cSS_fsmf, cSS_fsf, cSS_hsm, cSS_hsmf, cSS_hsf
        real :: corr

        rhofsmm = rfsmm - rfsmm * (1.0 - rfsmm**2) * (0.8634 / m_in + 0.954 / f_in)
        rhofsmf = rfsmf - rfsmf * (1.0 - rfsmf**2) * (0.8634 / m_in + 0.954 / f_in)
        rhofsff = rfsff - rfsff * (1.0 - rfsff**2) * (0.8634 / m_in + 0.954 / f_in)
        rhohsmm = rhsmm - rhsmm * (1.0 - rhsmm**2) * (1.4075 / m_in + 1.4581 / f_in)
        rhohsmf = rhsmf - rhsmf * (1.0 - rhsmf**2) * (1.4075 / m_in + 1.4581 / f_in)
        rhohsff = rhsff - rhsff * (1.0 - rhsff**2) * (1.4075 / m_in + 1.4581 / f_in)

        if (m_in < 20) then
            pmfs = (1.0 - rhofsmm) * pm + rhofsmm * max(pm, 1.0 / m_in)
            pffs = (1.0 - rhofsff) * pf + rhofsff * max(pf, 1.0 / m_in)
            pmhs = (1.0 - rhohsmm) * pm + rhohsmm * max(pm, 1.0 / m_in)
            pfhs = (1.0 - rhohsff) * pf + rhohsff * max(pf, 1.0 / m_in)
            call trunc(pmfs, xmfs, imfs, kmfs)
            call trunc(pffs, xffs, iffs, kffs)
            call trunc(pmhs, xmhs, imhs, kmhs)
            call trunc(pfhs, xfhs, ifhs, kfhs)
        else
            call trunc(pm, xmfs, imfs, kmfs)
            call trunc(pf, xffs, iffs, kffs)
            xmhs = xmfs; imhs = imfs; kmhs = kmfs
            xfhs = xffs; ifhs = iffs; kfhs = kffs
        end if

        dum = (imfs * rhofsmm - xmfs) / sqrt(1.0 - kmfs * rhofsmm**2)
        cSS_fsm = sabf(dum) / pmfs
        dum = (imfs * rhofsmf - xffs) / sqrt(1.0 - kmfs * rhofsmf**2)
        cSS_fsmf = sabf(dum) / pffs
        dum = (iffs * rhofsff - xffs) / sqrt(1.0 - kffs * rhofsff**2)
        cSS_fsf = sabf(dum) / pffs

        dum = (imhs * rhohsmm - xmhs) / sqrt(1.0 - kmhs * rhohsmm**2)
        cSS_hsm = sabf(dum) / pmhs
        dum = (imhs * rhohsmf - xfhs) / sqrt(1.0 - kmhs * rhohsmf**2)
        cSS_hsmf = sabf(dum) / pfhs
        dum = (ifhs * rhohsff - xfhs) / sqrt(1.0 - kfhs * rhohsff**2)
        cSS_hsf = sabf(dum) / pfhs

        call hyper_correct(corr, cSS_fsm, cSS_fsmf, cSS_fsf, cSS_hsm, cSS_hsmf, cSS_hsf, &
                           glambda, gpi, vsa, d_in, nm, nf, m_in, f_in, bb)
        delf = delf + corr
    end subroutine Poissoncorr

    !============================================
    subroutine hyper_correct(corr, cSS_fsm, cSS_fsmf, cSS_fsf, cSS_hsm, cSS_hsmf, cSS_hsf, &
                             glambda, gpi, vsa, d_in, nm, nf, m_in, f_in, bb)
        !correction according to Burrows 1984
        implicit none
        real, intent(out) :: corr
        real, intent(in) :: cSS_fsm, cSS_fsmf, cSS_fsf, cSS_hsm, cSS_hsmf, cSS_hsf
        real, dimension(2, 2), intent(in) :: glambda, gpi
        real, dimension(2), intent(in) :: vsa, bb
        real, intent(in) :: d_in, nm, nf, m_in, f_in
        real :: znm, znf, zm, zf, ztm, ztf, d1, d2
        real :: mu_sqm, mu_sqf, mu_sqmf
        real, dimension(2, 2) :: pi_local, Vs, Vd
        real, dimension(2, 1) :: alpha
        real, dimension(2, 1, 1) :: delta
        real, dimension(1, 1) :: temp_matmul

        ztm = nm * f_in
        ztf = nf * f_in
        znm = nm
        znf = nf
        zm = m_in
        zf = f_in

        Vd(1, 1) = znm * (znm - 1.0) * zm * (zm - 1.0) * cSS_fsm / ztm / (ztm - 1.0)
        Vd(1, 2) = znm * znf * zm * zf * cSS_fsmf / ztm / ztf
        Vd(2, 1) = Vd(1, 2)
        Vd(2, 2) = znf * (znf - 1.0) * zf * (zf - 1.0) * cSS_fsf / ztf / (ztf - 1.0)

        Vs(1, 1) = znm * znm * zm * (zm - 1.0) * cSS_hsm / ztm / (ztm - 1.0)
        Vs(1, 2) = znm * znf * zm * zf * cSS_hsmf / ztm / ztf
        Vs(2, 1) = Vs(1, 2)
        Vs(2, 2) = znf * znf * zf * (zf - 1.0) * cSS_hsf / ztf / (ztf - 1.0)

        Vs = d_in * Vd + d_in * (d_in - 1.0) * Vs

        mu_sqm = 1.0 + 2 * glambda(1, 1) * vsa(1) * 2 * glambda(1, 1)
        mu_sqmf = d_in * (1.0 + 2 * glambda(1, 1) * vsa(1) * 2 * glambda(2, 1))
        mu_sqf = d_in * d_in * (1.0 + 2 * glambda(2, 1) * vsa(1) * 2 * glambda(2, 1))
        Vs(1, 1) = Vs(1, 1) - mu_sqm
        Vs(1, 2) = Vs(1, 2) - mu_sqmf
        Vs(2, 1) = Vs(1, 2)
        Vs(2, 2) = Vs(2, 2) - mu_sqf

        mu_sqm = (1.0 + 2 * glambda(1, 2) * vsa(2) * 2 * glambda(1, 2)) / d_in / d_in
        mu_sqmf = (1.0 + 2 * glambda(1, 2) * vsa(2) * 2 * glambda(2, 2)) / d_in
        mu_sqf = 1.0 + 2 * glambda(2, 2) * vsa(2) * 2 * glambda(2, 2)
        Vd(1, 1) = Vd(1, 1) - mu_sqm
        Vd(1, 2) = Vd(1, 2) - mu_sqmf
        Vd(2, 1) = Vd(1, 2)
        Vd(2, 2) = Vd(2, 2) - mu_sqf

        alpha(1, 1) = 1.0 / (2 * m_in)
        alpha(2, 1) = 1.0 / (2 * f_in)
        temp_matmul = matmul(transpose(alpha), matmul(Vs, alpha))
        delta(1, 1, 1) = temp_matmul(1,1)
        temp_matmul = matmul(transpose(alpha), matmul(Vd, alpha))
        delta(2, 1, 1) = temp_matmul(1,1)

        if (m_in > 19) then
            pi_local = 2.0 * gpi
            d1 = bb(1)**2 * pi_local(1, 1)**2 * Vs(1, 1) * vsa(1)
            d1 = d1 + 2.0 * bb(1) * pi_local(1, 1) * bb(2) * pi_local(2, 1) * Vs(1, 2) * vsa(1)
            d1 = d1 + (bb(2) * pi_local(2, 1))**2 * Vs(2, 2) * vsa(1)
            delta(1, 1, 1) = delta(1, 1, 1) + d1

            d2 = bb(1)**2 * pi_local(1, 2)**2 * Vd(1, 1) * vsa(2)
            d2 = d2 + 2.0 * bb(1) * pi_local(1, 2) * bb(2) * pi_local(2, 2) * Vd(1, 2) * vsa(2)
            d2 = d2 + (bb(2) * pi_local(2, 2))**2 * Vd(2, 2) * vsa(2)
            delta(2, 1, 1) = delta(2, 1, 1) + d2
        end if

        corr = 0.125 * (m_in * delta(1, 1, 1) + f_in * delta(2, 1, 1))
    end subroutine hyper_correct

end module Inbreeding