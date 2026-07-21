!     Last change:  MR   14 Sep 2000    2:37 pm
!     Modernized:   AI   28 Jun 2025
module selparameters
    implicit none

    integer :: ssumits3, dsumits3, nclass
    integer :: ntraits, fsgroups, hsgroups, proggroups, dum3, tempsits
    integer :: i, j, k, l, m, n, o, p, q, r, ni, sdimp, ddimp, dimp, selrounds, nstag
    integer :: counti, counth, countb, totalh, ssumits, dsumits, ssumits2, dsumits2, dum5
    integer, allocatable, dimension(:, :) :: stempsource, dtempsource, stempsource4, dtempsource4
    integer, allocatable, dimension(:, :) :: stempsource2, dtempsource2, stempsource3, dtempsource3
    integer, allocatable, dimension(:, :) :: stempsourcet, dtempsourcet
    integer, allocatable, dimension(:, :) :: dum4, its, proginfo
    integer, allocatable, dimension(:, :, :) :: tempsource
    integer, allocatable, dimension(:) :: sits, dits, sits2, dits2, sits3, dits3, sitst, ditst
    integer, allocatable, dimension(:) :: sproginfo, dproginfo, sumits

    real, dimension(20) :: fsgroupsoff, hsgroupsoff, proggroupsoffs, proggroupsoffd
    real, dimension(20) :: hsgroupsdams, proggroupsdams
    real :: neffdams, dum1, dum2, is, id, ks, kd, sumresponse, factorr
    real :: nsires, ndams, noffs, noffd, progoff, progeffdams, sexerat, pi, srih3, drih3
    real :: ssigmai, dsigmai, factorrs, factorrd, trunc3s, trunc3d, is3, id3, is3c, id3c
    real :: temp3sigmai, srih, drih, sigmah, errpart, comenvpart, genpart
    real :: tempsresponse1, tempsresponse2, tempsresponse3, tempsresponse4, t1s, t2s
    real :: tempdresponse1, tempdresponse2, tempdresponse3, tempdresponse4, t1d, t2d
    real :: tempsresponse5, tempsresponse6, tempdresponse5, tempdresponse6, tempg3
    real :: pvals2, pvald2, pvalse, pvalde, ssigmai2, dsigmai2, srih2, drih2, trunc2d
    real :: tempg1, tempg2, scorrfs, scorrhs, dcorrfs, dcorrhs, trunc2s, pvals3, pvald3
    real :: scorrfs2, scorrhs2, dcorrfs2, dcorrhs2, is2, is2c, ise, isec, id2, id2c, ide, idec
    real :: pvals, pvald, trunc1s, trunc1d, corrsrih, corrdrih, isc, idc
    real :: ssigmai3, dsigmai3, corrsrih12, corrdrih12, scorrfs3, scorrhs3, dcorrfs3, dcorrhs3
    real :: corrsrih13, corrdrih13, corrdrih23, corrsrih23, dF, sdcorrfs, sdcorrhs
    real :: stotalresponse, dtotalresponse, stotalresponsec, dtotalresponsec
    real :: totalresponse, totalresponsec, ototalresponse
    real :: stotalresponse2, dtotalresponse2, stotalresponse2c, dtotalresponse2c
    real :: totalresponse2, totalresponse2c, sumsresponse2, sumdresponse2, sumresponse2
    real :: stotalresponse3, dtotalresponse3, stotalresponse3c, dtotalresponse3c
    real :: totalresponse3, totalresponse3c, sumresponse3, prst

    real :: msstotalresponse, msdtotalresponse, mstotalresponse
    real :: msstotalresponse2, msdtotalresponse2, mstotalresponse2
    real :: msstotalresponse2c, msdtotalresponse2c, mstotalresponse2c
    real :: msstotalresponse3, msdtotalresponse3, mstotalresponse3
    real :: msstotalresponse3c, msdtotalresponse3c, mstotalresponse3c

    real(kind=selected_real_kind(p=14)) :: seuil1, seuil2, seuil3, dumpvald3, dumpvals3, dutt2
    real(kind=selected_real_kind(p=14)) :: dumpvals, dumpvald, dumtrunc1s, dumtrunc1d, dumcorrsrih, dumcorrdrih
    real(kind=selected_real_kind(p=14)) :: dumtrunc2s, dumtrunc2d, dumpvals2, dumpvald2, dumtrunc3s, dumtrunc3d
    real(kind=selected_real_kind(p=14)) :: dumcorrsrih12, dumcorrsrih13, dumcorrsrih23, dumcorrsrih123, dumcorrsrih231
    real(kind=selected_real_kind(p=14)) :: dumcorrsrih132, dumcorrsrih213, dumcorrsrih312, dumcorrsrih321
    real(kind=selected_real_kind(p=14)) :: dumcorrdrih12, dumcorrdrih13, dumcorrdrih23, dumcorrdrih123, dumcorrdrih231
    real(kind=selected_real_kind(p=14)) :: dumcorrdrih132, dumcorrdrih213, dumcorrdrih312, dumcorrdrih321
    real(kind=selected_real_kind(p=14)) :: t12d, t21d, t13d, t31d, t23d, t32d, t12s, t21s, t13s, t31s, t23s, t32s
    real, dimension(1, 1) :: tempcov3, tempcov4, g1, g2, g3
    real, allocatable, dimension(:, :) :: v
    real(kind=selected_real_kind(p=14)), allocatable, dimension(:, :) :: dumv
    real, allocatable, dimension(:, :) :: g, beta
    real, allocatable, dimension(:) :: sigmaa, sigmap, sigmaas, sigmac, progsigmac
    real, allocatable, dimension(:) :: sigmaad, sigmaaw, sigmae, ccprog, msresponsec
    real, allocatable, dimension(:) :: scovapi, dcovapi, scovipi, dcovipi, pvalcl
    real, allocatable, dimension(:) :: covipi, hh, cc, prs, prd, osigmai, oi, ok
    real, allocatable, dimension(:) :: sresponse, dresponse, response, rih, oresponse
    real, allocatable, dimension(:) :: sresponsec, dresponsec, responsec, corrfs
    real, allocatable, dimension(:) :: sresponse2, dresponse2, response2, corrhs
    real, allocatable, dimension(:) :: sresponse2c, dresponse2c, response2c
    real, allocatable, dimension(:) :: sresponse3, dresponse3, response3
    real, allocatable, dimension(:) :: sresponse3c, dresponse3c, response3c
    real, allocatable, dimension(:) :: mssresponse2, msdresponse2, msresponse2
    real, allocatable, dimension(:) :: mssresponse2c, msdresponse2c, msresponse2c
    real, allocatable, dimension(:) :: mssresponse3, msdresponse3, msresponse3
    real, allocatable, dimension(:) :: mssresponse3c, msdresponse3c, msresponse3c

    real, allocatable, dimension(:, :) :: sinvp, dinvp, invp, sb, db, fs, hs, s, d, sb2, db2
    real, allocatable, dimension(:, :) :: scovapiq, dcovapiq, covapiq, scovapaq, dcovapaq
    real, allocatable, dimension(:, :) :: phcorr, gcorr, ccorr, ecorr, drealp, covcprog
    real, allocatable, dimension(:, :) :: tempb, drealg, covapaq, dtempcov1, dtempcov2
    real, allocatable, dimension(:, :) :: spartrealg, dpartrealg, partrealg, tempcov5
    real, allocatable, dimension(:, :) :: stempcov1, stempcov2, ev, tempev, srealp, sb3, db3
    real, allocatable, dimension(:, :) :: scove, dcove, cove, scovp, dcovp, covp, srealg
    real, allocatable, dimension(:, :) :: scovas, dcovas, covas, scovad, dcovad, covad
    real, allocatable, dimension(:, :) :: scovaw, dcovaw, covaw, scovc, dcovc, covc
    real, allocatable, dimension(:, :) :: temp1sigmah, temp2sigmah, sinvp3, dinvp3
    real, allocatable, dimension(:, :) :: sinvp2, dinvp2, stempcov12, stempcov22, dgcol2
    real, allocatable, dimension(:, :) :: dtempcov12, dtempcov22, srealg2, drealg2
    real, allocatable, dimension(:, :) :: spartrealg2, dpartrealg2, sgcol, sgcol2, dgcol
    real, allocatable, dimension(:, :) :: srealg3, drealg3, sgcol3, dgcol3
    real, allocatable, dimension(:) :: jacvec

    character(len=1) :: initc, pheninfoinit, sinitmatrat2, sinitmatrat3, sinitmatrat
    character(len=1) :: dinitmatrat2, dinitmatrat3, dinitmatrat, sourcesd, stages
    character(len=1) :: sinitmatrat6, sinitmatrat5, progtest, indexdiff, posdefph, posdefg
    character(len=1) :: dinitmatrat6, dinitmatrat5, initindsel, initcorrsrih
    character(len=1) :: initfs, iniths, initprog, initnotematrat, initcorrdrih
    character(len=33), dimension(83) :: xsource
    character(len=8) :: fnam
    character(len=12) :: fnamein, fnameout
    character(len=8), allocatable, dimension(:) :: xtraits
    character(len=1), allocatable, dimension(:) :: sdesttraits, spheninfo, posgcorr
    character(len=1), allocatable, dimension(:) :: sdesttraits2, ddesttraits2
    character(len=1), allocatable, dimension(:) :: sdesttraits3, ddesttraits3
    character(len=1), allocatable, dimension(:) :: ddesttraits, dpheninfo, desttraits
    character(len=1), allocatable, dimension(:, :) :: pheninfo

    real, allocatable, dimension(:, :) :: osigmaa, osigmap, osigmaas, osigmac, oprogsigmac
    real, allocatable, dimension(:, :) :: osigmaad, osigmaaw, osigmae, occprog
    real, allocatable, dimension(:, :) :: ocovapi, ocovipi
    real, allocatable, dimension(:, :) :: ohh, occ

    integer :: oldo
    real :: sumpvals, sumpvald, tempresponse, tempresponse1, tempresponse2, sselec, dselec
    real :: pval, genints, genintd, sums, sumd, xl, xh, xlo, xho, xln, xhn, zriddr, tol
    real, allocatable, dimension(:, :, :) :: ocovp, ocovas, ocovad, ocovaw, ocovc, ocove
    real, allocatable, dimension(:, :, :) :: ocovapaq, ofs, ohs, os, od, ocovcprog, ocovapiq
    real, allocatable, dimension(:, :, :) :: orealg, oinvp, ob
    real, allocatable, dimension(:, :) :: oscovapi, odcovapi, tempresponse4, mean, omatc, osigmah
    real, allocatable, dimension(:) :: smean, dmean, nanim, nselec
    character(len=1) :: initsk

end module selparameters