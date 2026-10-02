# SelAction (development version)

## macOS

* New `fortran_mac/` directory: a fresh copy of `fortran_linux/`, verified to
  build with GNU Fortran 14.2.0 on macOS (Homebrew `gcc`, x86_64) and pass all
  regression fixtures (`tests/run_tests.sh fortran_mac`). No macOS-specific
  source changes were needed. `fortran_mac/` is now the active development
  directory; every change below is *fortran_mac only* and has not been
  applied to `fortran_linux/`.

## Changes to results (overlapping generations, `msselo`)

These change `msselo` output. Discrete-generation output (`mssel`/`msseld`
on `test1`, `test2s`, `test3s`, `blup1`, `advgrp`) is byte-identical after
every change in this file. Only the two overlapping-generation fixtures were
regenerated, and only for the reasons given below.

### 1. Truncation threshold search fixed (commit 071256b)

Each of `ovlp`'s 25 equilibrium rounds, `riddr_root` (Ridders' method)
solves for the truncation threshold at which the number selected across age
classes equals `nsires` (or `ndams`). Two bugs in the original code
(present in `fortran_orig/` too):

* *Search bracket too narrow.* It searched only within ±1.5 index SD of each
  age-class mean, so at least P(Z > 1.5) = 6.7% of the youngest class was
  always selected. When the target needed more intense selection the root
  was not bracketed and `riddr_root` gave up silently, leaving the
  proportions at the bracket edge. The `ovlpgrp` fixture asked for 10 sires
  from 1000 + 500 candidates and selected 67.5 (its output said "number of
  selected sires: 10.000" while the age-class lines summed to 67.5); runs
  with 5, 10, 20 or 40 sires all gave identical output.
* *Proportions taken from the wrong point.* `trunc_delta` writes
  `pvalcl`/`nselec` (per-age-class selected proportions) on every call, and
  one `riddr_root` exit leaves them at the bracket midpoint rather than the
  root. After convergence this knocked the loop off its fixed point every
  ~9-11 rounds, so round-25 output depended on where a kick landed and
  differed by ~1% between `-O0` and `-O2` builds. `trunc_delta` is now
  re-evaluated at the returned root.

The bracket was first widened to ±3 SD (the clamp then in `trunc_delta`);
change 2 below widens it to ±8 SD.

### 2. Exact normal tail probabilities; ±3 SD clamp removed (this commit)

`sdutt1` (`seltools.f90`) returns the upper normal tail P(Z > s). It used a
Gauss-Hermite quadrature (`racine` nodes, 10 or 20 points). Compared against
a quad-precision (~33-digit) `erfc` reference for s in [-8, 8]:

| \|s\| (SD) | sdutt1, 10 points | sdutt1, 20 points | `erfc` |
|---|---|---|---|
| 0-3 | rel. error <= 1.3e-5 | <= 4.6e-6 | abs. error ~1e-16 |
| 3-4 | 2.9e-4 | 2.0e-4 | ~1e-16 |
| 4-5 | up to ~15x too large | 2% | ~1e-16 |
| 5-8 | meaningless (~0.15 instead of ~1e-15) | up to 3e8x wrong | ~1e-16 |

Beyond 4 SD the quadrature is also non-monotonic (the 10-point version
increases at ~32,000 of 40,000 grid points per side). This is presumably why
`trunc_delta` clamped its argument to ±3 SD - but that clamp had a side
effect: every age class always contributed at least P(Z > 3) = 0.135% of its
animals to the selected group, however far the threshold was above it. In
both `ovlp` fixtures the older sire class sat exactly on that floor (`ovlp2`:
0.108 of 80; `ovlpgrp`: 0.675 of 500).

Changes:

* `sdutt1` now computes `0.5*erfc(s/sqrt(2))` (Fortran 2008 intrinsic; any
  modern gfortran/ifort/flang). Its `nrac` argument is unused but kept, so
  no caller changed. Callers: `trunc_delta` (ovlp truncation), 8 calls in
  `sel2s`/`sel3s` (multi-stage response), and the 1-D branch of the
  multivariate helper in `seltools.f90`. The bivariate/trivariate integrals
  (`sdutt2`/`sdutt3`) still use the quadrature and are untouched.
* The ±3 SD clamp on `dumt` in `trunc_delta` is removed, and the threshold
  bracket in `selovlp.f90` is widened from ±3 to ±8 SD (essentially no
  animals selected at 8 SD, so any feasible target is bracketed).

Verification, done in two separately checked steps:

* *Swap alone* (clamp kept): 11 of 12 fixture checks byte-identical; the only
  difference was `ovlpgrp`'s breeding goal variance, 526.938 -> 526.937.
  Logging every `sdutt1` call during the fixtures showed arguments always
  within ±3.5 SD, where the two methods agree to ~1e-8.
* *Clamp removed:* all 10 discrete-generation checks byte-identical; `ovlp2`
  and `ovlpgrp` change as below, byte-identical to an independently built
  prototype. Across the 74-input `ovlp` sweep every run hits its sire/dam
  targets, `-O0` and `-O2` agree, the strict SNaN/FPE/`-fcheck=all` build is
  trap-free, and the warning never fires. Run time unchanged.

Effect on the regenerated fixtures:

| | before | after |
|---|---|---|
| `ovlpgrp` sires selected, young / old class | 9.325 / 0.675 | 10.000 / 0.000 |
| `ovlpgrp` generation interval | 1.16 | 1.05 |
| `ovlpgrp` breeding goal variance | 526.938 | 512.125 |
| `ovlpgrp` accuracy, sire age class 1 | 0.713 | 0.705 |
| `ovlpgrp` total response, wt | 5.577 | 5.908 |
| `ovlp2` sires selected, young / old class | 9.892 / 0.108 | 9.947 / 0.053 |
| `ovlp2` total response, wt | 3.441 | 3.460 |

Effect when varying the number of sires on `ovlpgrp` (1000 + 500 sire
candidates):

| sires | before: young / old selected | before: BG var, acc., wt total | after: young / old | after: BG var, acc., wt total |
|---|---|---|---|---|
| 1 | 1.350 / 0.675 (warning) | 595.7, 0.746, 5.183 | 1.000 / 0.000 | 510.2, 0.704, 6.979 |
| 5 | 4.325 / 0.675 | 549.3, 0.725, 5.641 | 5.000 / 0.000 | 511.4, 0.705, 6.253 |
| 10 | 9.325 / 0.675 | 526.9, 0.713, 5.577 | 10.000 / 0.000 | 512.1, 0.705, 5.908 |
| 40 | 39.325 / 0.675 | 515.2, 0.707, 5.047 | 39.965 / 0.035 | 514.3, 0.706, 5.130 |
| 100 | 99.224 / 0.776 | 516.9, 0.708, 4.501 | identical | identical |
| 150 | 147.080 / 2.920 | 518.7, 0.709, 4.159 | identical | identical |

Where the clamp never bound (>= 100 sires) results are identical to every
digit. Below that, the old results had a U-shaped breeding goal variance and
an index accuracy that *rose* with more intense selection. Both came from the
forced 0.675 old sires - most likely through the between-age-class term of
the variance update, since an older cohort lags a generation behind (a
plausible mechanism, not traced in the code). After the change, variance and accuracy
fall steadily as selection intensifies, as the Bulmer effect predicts, and
response rises steadily.

## Bug fixes

* `msselo` prints a WARNING (output file and screen) if the requested number
  of sires or dams cannot be selected, instead of failing silently. With the
  ±8 SD bracket this should only happen for impossible targets; the input
  routine already refuses more sires/dams than candidates, so in practice it
  is a safety net. (Before the clamp was removed it fired for very intense
  selection, e.g. 1 sire from 1500.) No numbers change.
* "% of total response" prints `n/a` when the total response rounds to
  0.000, instead of dividing by a near-zero total (e.g. it printed 10.198 /
  54.813 with BLUP as the only info source under `ovlp`). Applies to `ovlp`
  and `sel1s`/`sel2s`/`sel3s`. All fixtures byte-identical.
* `covai_update()` (`selroutines.f90`) no longer takes the unused `realp`
  argument. Its four callers in `sel2s`/`sel3s` passed `srealp`/`drealp`,
  which are never allocated - invalid Fortran, caught by `-fcheck=all` on
  `test2s`/`test3s`. No effect on output; all fixtures byte-identical.

## Verification

* All 7 fixtures run without a trap under the strict debug build
  (`-finit-real=snan -finit-integer=-999999999
  -ffpe-trap=invalid,zero,overflow -fcheck=all`), confirming the earlier
  negative-`sigmai` and `rawl3` fixes hold on macOS. (`blup1` prints `0.000`
  instead of `-0.000` for one near-zero weight in that unoptimized build -
  the known display-rounding sensitivity, see `tests/README.md`.)

## Known issues

* The previously documented "BLUP + group under `ovlp` gives an all-zero
  response / `NaN`" could not be reproduced, before or after the changes
  above, in a 72-input sweep of BLUP combined with full-sib, half-sib and
  progeny groups. The triggering input was not recorded. It may have been the
  silent root-finder failure fixed above; not confirmed.
* BLUP (code 2) as the *only* info source under `ovlp` runs to an all-zero
  response (correct: parental EBVs carry no information without phenotypes;
  percentages show `n/a`). Discrete generations refuse this input with a "no
  phenotypic information sources" message; `ovlp` lacks that check.
* **Generation interval under overlapping generations is wrong** (found
  while reviewing the technical report; not yet fixed). In `selovlp.f90` the
  loops that should sum the interval over age classes overwrite instead
  (`genints_local=genints+tempresponse`), so only the oldest active class is
  added on top of the value left by `trunc_delta`. `ovlpgrp` uses L = 1.046
  instead of 1.015 (annual response ~3% too low); in specified-count mode,
  where `trunc_delta` never runs, an example gave L = 0.65 instead of 1.325
  (annual response ~2x too high). Fixing it changes overlapping-generation
  output, so it is held for review.
* **Gauss-Hermite tables stop at 20 points, adaptive loop runs to 30**
  (found while reviewing the technical report; not yet fixed). `racine`
  (`seltools.f90`) fills nodes/weights for 2-20 points, but `sdutt`'s
  adaptive loop goes `nrac=10..30`. If it hasn't converged by 20, the zero
  tables return exactly 0.25 (2-D) / 0.125 (3-D), two equal values count as
  convergence, and that is returned silently: P(Z1>2.5, Z2>2.8; r=0.93) comes
  back as 0.25 instead of 0.0021. Multistage `sseuil2`/`sseuil3` can hit this
  (stage correlations are capped at 0.93) with small fractions.
* `sel2s` with `nsires == ndams` removes half-sib sources 24-43 but not the
  dam-EBV sources 44-63 that BLUP adds; `sel1s`/`sel3s` remove 24-63.
* Uninitialised reads in `seldiscrete.f90`: `ccprog` is read only when
  progeny groups and common environment are both requested but used
  unconditionally (the `selovlp.f90` copy was fixed earlier), and `dsigmai`
  is accumulated without being reset when `indexdiff='y'` (starting `D`
  only). Same pattern as the earlier `initblup`/`ccprog` fixes.
* `fortran_linux/` (and `fortran_orig/`) still have every bug fixed above.

## Questions for Peter Bijma / Jack Dekkers

1. Was the ±1.5 SD search bracket in `selovlp.f90` deliberate, or just a
   starting range? It is now ±8 SD.
2. Was the ±3 SD clamp in `trunc_delta` there because of `sdutt1`'s
   accuracy in the far tail, or for another reason? It is now removed and
   `sdutt1` computes the exact tail with `erfc` (see change 2). Please
   confirm this matches the intended model.
3. Removing the clamp removed a U-shaped breeding goal variance and an index
   accuracy that rose with selection intensity (table above); results now
   follow the expected Bulmer pattern. Does that agree with your
   expectations for overlapping generations?
4. Do you recall an input where BLUP + groups under overlapping generations
   gave an all-zero response?

# Earlier history (before NEWS.md, summarised from git log)

* 2026-08-28: Added `ovlpgrp` fixture (groups under overlapping generations);
  fixed uninitialized `initblup` in four `info_sources*` subroutines;
  documented the BLUP + group bug under `ovlp`.
* 2026-08-18: Added `ovlp2`, the first overlapping-generations fixture; fixed
  uninitialized `ccprog` read in `selovlp.f90`; guarded `rawl3`'s division by
  zero at an exact-1.0 correlation; guarded `sqrt` of a transiently negative
  `sigmai` in `selection_index`; added OCR'd manual.
* 2026-08-10: Fixed segfault in overlapping-generations selection (unallocated
  `pheninfo`/`posgcorr`); fixed uninitialized group-array reads and guarded
  unconfigured group-type matrix blocks; added the regression-test harness;
  added license, logo and README badges.
* 2026-07-21: Initial import (orig/linux layout); fixed the `fortran_linux`
  build (compile order, `dFmtblup` name clash).
