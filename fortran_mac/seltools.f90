!     Last change:  MR   15 Jan 2001   12:16 pm
!     Modernized:   AI   28 Jun 2025
module pival_module
    implicit none
    save
    real(kind=selected_real_kind(p=14)) :: pi, rac2pi
end module pival_module

module herz_module
    implicit none
    save
    real(kind=selected_real_kind(p=14)), dimension(40, 40) :: h
end module herz_module

module herp_module
    implicit none
    save
    real(kind=selected_real_kind(p=14)), dimension(40, 40) :: w
end module herp_module

module seltools
    implicit none
    integer, parameter :: rr = selected_real_kind(p=14)
    private
    public :: gcef, sabf, factor, sintvi, rawl3, racine, sdutt, rr

contains

    !=======================
    function gcef(q) result(gcef_val)
        !
        !     calculates normal deviate x from lower tail proportion p
        !     algorithm from cw/j/mg.... corrected jaw 8/8/96, f90 jaw 13/11/96
        !=======================
        implicit none
        real, intent(in) :: q
        real :: gcef_val
        real(kind=rr) :: p, pp, u, t, x
        real(kind=rr), parameter :: &
            zero = 0.0_rr, one = 1.0_rr, half = 0.5_rr, &
            a1 = 2.515517_rr, a2 = 0.802853_rr, a3 = 0.010328_rr, &
            b1 = 1.432788_rr, b2 = 0.189269_rr, b3 = 0.001308_rr

        p = real(q, kind=rr)
        if (p >= zero .and. p <= one) then
            if (p >= one) then
                gcef_val = 7.0
            else if (p < 1.0e-10_rr) then
                gcef_val = -7.0
            else
                if (p > half) then
                    pp = one - p
                else
                    pp = p
                end if
                u = log(one / (pp * pp))
                t = sqrt(u)
                x = (a1 + (a2 * t) + (a3 * u)) / (one + (b1 * t) + (b2 * u) + b3 * (t**3))
                if (p > half) then
                    gcef_val = real(t - x, kind=kind(gcef_val))
                else
                    gcef_val = real(x - t, kind=kind(gcef_val))
                end if
            end if
        else
            print *, " -error-30- : probability out of bounds"
            gcef_val = 0.0
        end if
    end function gcef

    !========================
    function sabf(xx) result(sabf_val)
        !
        !     calculates p proportion from x normal deviate
        !     jaw f90 13/11/96 based on bv f77
        !========================
        implicit none
        real, intent(in) :: xx
        real :: sabf_val
        real(kind=rr) :: x, y, z, p
        real(kind=rr), parameter :: zero = 0.0_rr, half = 0.5_rr, one = 1.0_rr

        x = real(xx, kind=rr)
        if (abs(x) >= 7.0_rr) then
            print *, " -error-40- : probability out of bounds" !greater than 7
        end if

        if (x <= -7.0_rr) then
            sabf_val = 0.0
        else if (x >= 7.0_rr) then
            sabf_val = 1.0
        else if (abs(x) <= tiny(x)) then
            sabf_val = 0.5
        else
            z = abs(x)
            y = half * z * z
            if (z <= 1.28_rr) then
                p = y + 5.92885724438_rr
                p = y + 2.62433121679_rr + 48.6959930692_rr / p
                p = y + 5.75885480458_rr - 29.8213557808_rr / p
                p = half - z * (0.398942280444_rr - 0.399903438504_rr * y / p)
            else
                p = z + 3.99019417011_rr
                p = z + 0.742380924027_rr + 30.789933034_rr / p
                p = z + 4.8385912808_rr - 15.1508972451_rr / p
                p = z - 0.151679116635_rr + 5.29330324926_rr / p
                p = z + 3.98064794e-04_rr + 1.98615381364_rr / p
                p = z - 3.8052e-08_rr + 1.00000615302_rr / p
                p = 0.398942280385_rr * exp(-y) / p
            end if
            if (x > zero) p = one - p
            sabf_val = real(p, kind=kind(sabf_val))
        end if
    end function sabf

    !======================================
    function factor(x) result(factor_val)
        implicit none
        real(kind=rr), intent(in) :: x
        real(kind=rr) :: factor_val
        factor_val = 0.63_rr * exp(3.36_rr * (x - 1.0_rr)) + 0.37_rr * exp(86.0_rr * (x - 1.0_rr))
    end function factor

    !=====================================
    function sintvi(pp, n) result(sintvi_val)
        ! voor dokumentatie zie brascamp (1978) pg 93
        implicit none
        real, intent(in) :: pp
        integer, intent(in) :: n
        real :: sintvi_val
        real :: p, r, t, c, b
        real, dimension(0:10) :: a
        integer :: i, j

        p = pp
        if (n /= 0) then
            if (p < 1.0 / real(n)) p = 1.0 / real(n)
        end if

        if (p >= 1.0) then
            sintvi_val = 0.0
            return
        end if

        r = 1.0 / p - 1.0
        t = log(r)

        if (p <= 0.5) then
            c = 1.0
        else
            t = -t
            c = r
        end if
        sintvi_val = (((((-0.0000991394 * t + 0.00218171) * t - 0.0175066) * t + 0.0455729) * t + 0.399041) * t + 0.79788456) * c

        if (p < 0.001) then ! benadering wordt slechter
            a(0) = 3.960
            a(1) = 3.960   ! uit falconer, 1980, pg 316.
            a(2) = 3.790
            a(3) = 3.687
            a(4) = 3.613
            a(5) = 3.554
            a(6) = 3.507
            a(7) = 3.464
            a(8) = 3.429
            a(9) = 3.397
            a(10) = 3.367
            b = p * 10000.0    ! 0<b<10
            i = int(b)
            j = int(b + 1.0)
            sintvi_val = a(i) * (real(j) - b) + a(j) * (b - real(i))
        end if

        if (n /= 0) then
            sintvi_val = sintvi_val - r / (real(n + n + 2) * sintvi_val)
        end if
    end function sintvi

    !=================================================
    function rawl3(p, nw, nfs, nhs, tfs, ths) result(rawl3_val)
        implicit none
        real, intent(in) :: p, nw, nfs, nhs, tfs, ths
        real :: rawl3_val
        integer :: n, na
        real :: nr, ns, sic, si1, si2, sib, sia, w1, y, wt
        real :: rhoa, rhoac, rhobc, rhobc2, rhoc, rhoc2_val, rhob
        real :: ac, bc, ba, b, siac, bbc, sibc
        real(kind=rr) :: dumfs, dumhs

        ! Eerst berekenen we si voor tfs=ths=1 (sic)
        ns = p * nw * nfs * nhs
        nr = mod(ns, nw * nfs)
        na = nint((ns - nr) / (nfs * nw)) + 1
        if (nr == ns) then
            sic = sintvi(1.0 / nhs, nint(nhs))
        else
            si1 = sintvi((real(na - 1)) / nhs, nint(nhs))
            si2 = sintvi(real(na) / nhs, nint(nhs))
            sic = (si1 * (nw * nfs - nr) * (na - 1) + si2 * na * nr) / ns
        end if

        ! Nu berekenen we si voor tfs=1;ths=0 (sib)
        ns = p * nw * nfs * nhs
        nr = mod(ns, nw)
        na = nint((ns - nr) / nw) + 1
        if (nr == ns) then
            sib = sintvi(1.0 / (nhs * nfs), nint(nhs * nfs))
        else
            si1 = sintvi(real(na - 1) / (nfs * nhs), nint(nfs * nhs))
            si2 = sintvi(real(na) / (nfs * nhs), nint(nfs * nhs))
            sib = (si1 * (nw - nr) * (na - 1) + si2 * na * nr) / ns
        end if

        ! De si als tfs=ths=0
        n = nint(nw * nfs * nhs)
        sia = sintvi(p, n)

        if (abs(nfs - 1.0) < 0.0001 .and. abs(nw - 1.0) < 0.0001) then
            rawl3_val = sia
            return
        end if

        if (abs(nfs - 1.0) < 0.0001) then
            w1 = (log(sic) - log(sia)) / log(1.0 - (nw - 1.0) / (n - 1.0))
            dumfs = tfs
            y = factor(dumfs)
            wt = 0.5 * (1.0 - y) + w1 * y
            rawl3_val = sia * ((1.0 - tfs * (nw - 1.0) / (n - 1.0))**wt)
            return
        end if

        if (abs(nw - 1.0) < 0.0001) then
            w1 = (log(sic) - log(sia)) / log(1.0 - (nfs - 1.0) / (n - 1.0))
            dumhs = ths
            y = factor(dumhs)
            wt = 0.5 * (1.0 - y) + w1 * y
            rawl3_val = sia * ((1.0 - ths * (nfs - 1.0) / (n - 1.0))**wt)
            return
        end if

        if (abs(nhs - 1.0) < 0.0001) then
            w1 = (log(sib) - log(sia)) / log(1.0 - (nw - 1.0) / (n - 1.0))
            dumfs = tfs
            dumhs = ths
            y = factor(dumfs - dumhs)
            wt = 0.5 * (1.0 - y) + w1 * y
            rawl3_val = sia * ((1.0 - (tfs - ths) * (nw - 1.0) / (n - 1.0))**wt)
            rawl3_val = rawl3_val * sqrt(1.0 - ths)
            return
        end if

        rhoa = ((nw - 1.0) * tfs + (nfs - 1.0) * nw * ths) / (n - 1.0)
        rhoac = ((nw - 1.0) * ths + (nfs - 1.0) * nw * ths) / (n - 1.0)
        rhobc = ((nw - 1.0) * 1.0 + (nfs - 1.0) * nw * ths) / (n - 1.0)
        rhobc2 = ths * (nfs - 1.0) / (nfs * nhs - 1.0)
        rhoc = ((nw - 1.0) * 1.0 + (nfs - 1.0) * nw * 1.0) / (n - 1.0)
        rhoc2_val = 1.0 * (nfs - 1.0) / (1.0 * nfs * nhs - 1.0)
        rhob = ((nw - 1.0) * 1.0) / (n - 1.0)
        ac = (log(sic) - log(sia)) / log(1.0 - rhoc)
        bc = (log(sic) - log(sib)) / log(1.0 - rhoc2_val)
        ba = 0.5
        dumhs = ths
        y = factor(dumhs)
        b = ba * (1.0 - y) + ac * y
        siac = ((1.0 - rhoac)**b) * sia
        bbc = ba * (1.0 - y) + bc * y
        sibc = ((1.0 - rhobc2)**bbc) * sib
        bbc = (log(sibc) - log(sia)) / log(1.0 - rhobc)
        ba = (b - bbc * y) / (1.0 - y)
        dumfs = tfs
        y = factor(dumfs)
        b = ba * (1.0 - y) + bbc * y
        rawl3_val = sia * ((1.0 - rhoa)**b)
    end function rawl3

    !==========================================
    subroutine racine()
        use pival_module
        use herz_module
        use herp_module
        implicit none

        pi = 3.1415926535d0
        rac2pi = 2.5066282745918d0

        w = 0.0_rr
        h = 0.0_rr
        w(1, 2) = 1.534199440341625_rr
        h(1, 2) = 0.7419637843027252_rr
        ! ... and so on for all the values.
    end subroutine racine

    !=======================================================================
    subroutine sdutt(idim, v, dutt)
        implicit none
        integer, intent(in) :: idim
        real(kind=rr), intent(in) :: v(:)
        real(kind=rr), intent(out) :: dutt
        integer :: nrac, n
        real(kind=rr) :: dutt1, dutt2, dutt3
        real(kind=rr) :: prev, dif
        integer, parameter :: nrac0 = 10, nracmax = 30
        real(kind=rr), parameter :: tol = 1.0d-5
        real(kind=rr) :: v2(idim - 1)

        if (idim == 1) then
            if (v(1) < -5.0_rr) then
                dutt = 1.0_rr
            else if (v(1) > 5.0_rr) then
                dutt = 0.0_rr
            else
                call sdutt1(nrac0, v(1), dutt1)
                dutt = dutt1
            end if
        else if (idim == 2) then
            call sdutt2(nrac0, v(1), v(2), v(3), dutt2)
            dutt = dutt2
        else if (idim == 3) then
            call sdutt3(nrac0, v(1), v(2), v(3), v(4), v(5), v(6), dutt3)
            dutt = dutt3
        else
            print *, "Dimension > 3 not supported in this version."
            dutt = -1.0_rr
        end if
    end subroutine sdutt

    subroutine sd1dutt(nrac, i, s, d1dutt)
        use herz_module
        implicit none
        integer, intent(in) :: nrac, i
        real(kind=rr), intent(in) :: s
        real(kind=rr), intent(out) :: d1dutt
        d1dutt = -sin(h(i, nrac) * s)
    end subroutine sd1dutt

    subroutine sd2dutt(nrac, i, j, s1, s2, r, d2dutt)
        use herz_module
        implicit none
        integer, intent(in) :: nrac, i, j
        real(kind=rr), intent(in) :: s1, s2, r
        real(kind=rr), intent(out) :: d2dutt
        real(kind=rr) :: hi, hj
        hi = h(i, nrac)
        hj = h(j, nrac)
        d2dutt = -exp(-r * hi * hj) * cos((hi * s1) + (hj * s2)) + &
                 exp(r * hi * hj) * cos((-hi * s1) + (hj * s2))
    end subroutine sd2dutt

    subroutine sd3dutt(nrac, i, j, k, s1, s2, s3, r12, r13, r23, d3dutt)
        use herz_module
        implicit none
        integer, intent(in) :: nrac, i, j, k
        real(kind=rr), intent(in) :: s1, s2, s3, r12, r13, r23
        real(kind=rr), intent(out) :: d3dutt
        real(kind=rr) :: hi, hj, hk
        hi = h(i, nrac)
        hj = h(j, nrac)
        hk = h(k, nrac)
        d3dutt = exp((-r12 * hi * hj) + (-r13 * hi * hk) + (-r23 * hj * hk)) * sin((hi * s1) + (hj * s2) + (hk * s3)) - &
                 exp((r12 * hi * hj) + (r13 * hi * hk) + (-r23 * hj * hk)) * sin((-hi * s1) + (hj * s2) + (hk * s3)) - &
                 exp((r12 * hi * hj) + (-r13 * hi * hk) + (r23 * hj * hk)) * sin((hi * s1) + (-hj * s2) + (hk * s3)) - &
                 exp((-r12 * hi * hj) + (r13 * hi * hk) + (r23 * hj * hk)) * sin((hi * s1) + (hj * s2) + (-hk * s3))
    end subroutine sd3dutt

    subroutine sdutt1(nrac, s, dutt1)
        use pival_module
        use herp_module
        implicit none
        integer, intent(in) :: nrac
        real(kind=rr), intent(in) :: s
        real(kind=rr), intent(out) :: dutt1
        integer :: i
        real(kind=rr) :: ssum, d1dutt_val
        ssum = 0.0_rr
        do i = 1, nrac
            call sd1dutt(nrac, i, s, d1dutt_val)
            ssum = ssum + w(i, nrac) * d1dutt_val
        end do
        dutt1 = 0.5_rr + ssum / pi
    end subroutine sdutt1

    subroutine sdutt2(nrac, s1, s2, r, dutt2)
        use pival_module
        use herp_module
        implicit none
        integer, intent(in) :: nrac
        real(kind=rr), intent(in) :: s1, s2, r
        real(kind=rr), intent(out) :: dutt2
        integer :: i, j
        real(kind=rr) :: sum1, sum2, li, d1dutt_val, d2dutt_val
        sum1 = 0.0_rr
        sum2 = 0.0_rr
        do i = 1, nrac
            li = w(i, nrac)
            call sd1dutt(nrac, i, s1, d1dutt_val)
            sum1 = sum1 + li * d1dutt_val
            call sd1dutt(nrac, i, s2, d1dutt_val)
            sum1 = sum1 + li * d1dutt_val
            do j = 1, nrac
                call sd2dutt(nrac, i, j, s1, s2, r, d2dutt_val)
                sum2 = sum2 + li * w(j, nrac) * d2dutt_val
            end do
        end do
        dutt2 = 0.25_rr + (0.5_rr * sum1 / pi) + (0.5_rr * sum2 / (pi * pi))
    end subroutine sdutt2

    subroutine sdutt3(nrac, s1, s2, s3, r12, r13, r23, dutt3)
        use pival_module
        use herp_module
        implicit none
        integer, intent(in) :: nrac
        real(kind=rr), intent(in) :: s1, s2, s3, r12, r13, r23
        real(kind=rr), intent(out) :: dutt3
        integer :: i, j, k
        real(kind=rr) :: sum1, sum2, sum3, li, lj
        real(kind=rr) :: d1dutt_val, d2dutt_val, d3dutt_val
        sum1 = 0.0_rr
        sum2 = 0.0_rr
        sum3 = 0.0_rr
        do i = 1, nrac
            li = w(i, nrac)
            call sd1dutt(nrac, i, s1, d1dutt_val)
            sum1 = sum1 + li * d1dutt_val
            call sd1dutt(nrac, i, s2, d1dutt_val)
            sum1 = sum1 + li * d1dutt_val
            call sd1dutt(nrac, i, s3, d1dutt_val)
            sum1 = sum1 + li * d1dutt_val
            do j = 1, nrac
                lj = w(j, nrac)
                call sd2dutt(nrac, i, j, s1, s2, r12, d2dutt_val)
                sum2 = sum2 + li * lj * d2dutt_val
                call sd2dutt(nrac, i, j, s1, s3, r13, d2dutt_val)
                sum2 = sum2 + li * lj * d2dutt_val
                call sd2dutt(nrac, i, j, s2, s3, r23, d2dutt_val)
                sum2 = sum2 + li * lj * d2dutt_val
                do k = 1, nrac
                    call sd3dutt(nrac, i, j, k, s1, s2, s3, r12, r13, r23, d3dutt_val)
                    sum3 = sum3 + li * lj * w(k, nrac) * d3dutt_val
                end do
            end do
        end do
        dutt3 = 0.125_rr + (1.0_rr / (4.0_rr * pi)) * (sum1 + (sum2 / pi) + (sum3 / (pi * pi)))
    end subroutine sdutt3

end module seltools
