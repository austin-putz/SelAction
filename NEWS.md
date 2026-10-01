# SelAction (development version)

## macOS

* New `fortran_mac/` directory: a fresh copy of `fortran_linux/`, verified to
  build with GNU Fortran 14.2.0 on macOS (Homebrew `gcc`, x86_64) and pass all
  regression fixtures (`tests/run_tests.sh fortran_mac`). No macOS-specific
  source changes were needed. `fortran_mac/` is now the active development
  directory; fixes below marked *(fortran_mac only)* have not been applied to
  `fortran_linux/`.

## Changes to results (overlapping generations)

* **Truncation selection under overlapping generations (`ovlp`) now selects
  the requested number of sires and dams.** Two bugs in the original
  threshold search (`selovlp.f90`, present in `fortran_orig/` too) are fixed.
  This changes `msselo` output for many inputs. *(fortran_mac only)*

  1. *Search bracket too narrow.* Each round, `riddr_root` looks for the
     truncation threshold at which the selected number equals `nsires`/`ndams`,
     but searched only within ±1.5 index SD of each age-class mean. The
     threshold could therefore never be more than 1.5 SD above the youngest
     class, so at least P(Z > 1.5) = 6.7% of that class was always selected.
     When the target needed more intense selection, the root was not
     bracketed and `riddr_root` gave up silently, leaving the proportions at
     the bracket edge. Example: the `ovlpgrp` fixture asks for 10 sires from
     1500 candidates but selected 67.5 (output reported "number of selected
     sires: 10.000" while the age-class lines summed to 67.5); runs with 5,
     10, 20 or 40 sires all gave identical results. The bracket is now ±3 SD,
     matching the ±3 SD clamp already applied inside `trunc_delta`.
  2. *Proportions taken from the wrong point.* `trunc_delta` updates
     `pvalcl`/`nselec` (the per-age-class selected proportions) as a side
     effect of every evaluation, and `riddr_root` can exit right after
     evaluating its bracket midpoint rather than the root. The proportions used
     in the next round then did not match the threshold found. After
     convergence this periodically knocked the equilibrium loop off its fixed
     point (every ~9-11 rounds), so the reported round-25 values depended on
     where a kick happened to land - and differed by ~1% between `-O0` and
     `-O2` builds. `trunc_delta` is now re-evaluated at the returned root.

  Verified: in a sweep of 72 overlapping-generation inputs (BLUP, groups,
  common environment on/off, two population sizes) plus both fixtures, every
  run now hits its sire and dam targets, `-O0` and `-O2` agree, and the strict
  debug build runs trap-free. Old and new code agree (to within the ~1%
  kick effect) wherever the old bracket happened to contain the root (>= 6.7%
  of young sires selected). Regenerated fixtures: `ovlpgrp` (total response
  for wt 4.755 -> 5.577; sires 67.5 -> 10 selected) and `ovlp2` (3.435 ->
  3.441; it was already near its target by coincidence).

## Bug fixes

* Overlapping generations (`msselo`) now prints a WARNING in the output file
  and on screen when the requested number of sires or dams cannot be
  selected. Previously this failed silently. It happens when selection is
  more intense than `trunc_delta` can represent: its ±3 SD clamp means at
  least P(Z > 3) = 0.135% of *every* age class is always selected, so e.g.
  1 sire from 1000 + 500 candidates gives about 2 sires. Checked: no false
  warnings across the 74 inputs used for the fix above. No change to any
  numbers. *(fortran_mac only)*
* "% of total response" now prints `n/a` when the total response rounds to
  0.000. Previously it divided by a near-zero total and printed meaningless
  values (e.g. 10.198 / 54.813 with BLUP as the only info source under
  `ovlp`). Applies to `ovlp` and to `sel1s`/`sel2s`/`sel3s`. All fixtures
  byte-identical. *(fortran_mac only)*
* `covai_update()` (`selroutines.f90`) no longer takes the unused `realp`
  argument. Its four callers in `sel2s`/`sel3s` (`seldiscrete.f90`) passed
  `srealp`/`drealp`, which are never allocated - invalid Fortran, caught by
  `-fcheck=all` as "Allocatable actual argument 'srealp' is not allocated" on
  `test2s`/`test3s`. No effect on output (the argument was never read); all
  fixtures byte-identical. *(fortran_mac only)*

## Verification

* All 7 fixtures now run without a trap under the strict debug build
  (`-finit-real=snan -finit-integer=-999999999
  -ffpe-trap=invalid,zero,overflow -fcheck=all`), confirming the earlier
  negative-`sigmai` and `rawl3` fixes hold on macOS.

## Known issues

* The previously documented "BLUP + group under `ovlp` gives an all-zero
  response / `NaN`" could not be reproduced, before or after the fix above,
  in a 72-input sweep of BLUP combined with full-sib, half-sib and progeny
  groups. The input that originally triggered it was not recorded. It may
  have been the silent root-finder failure fixed above, but that is not
  confirmed. Kept open until a reproducing input turns up.
* BLUP (code 2) as the *only* info source under `ovlp` runs to an all-zero
  response (correct: parental EBVs carry no information without phenotypes;
  percentages now show `n/a`). Discrete generations instead refuse this input
  with a "no phenotypic information sources" message; `ovlp` lacks that check
  and should probably get it.
* The ±3 SD clamp in `trunc_delta` also acts as a floor: every age class
  contributes at least 0.135% of its animals, even when the threshold is far
  above it. In both `ovlp` fixtures the older sire class sits exactly on this
  floor (`ovlp2`: 0.108 of 80; `ovlpgrp`: 0.675 of 500). `sdutt1` (10-point
  Gauss quadrature) is accurate to ~0.03% out to 4 SD but fails beyond ~4.5 SD
  (off by 14x at 5 SD), which may be why the clamp exists. Replacing `sdutt1`
  in `trunc_delta` with the exact tail (Fortran's `erfc`) would remove the
  clamp and the floor, but changes results (`ovlpgrp` total for wt about
  5.58 -> 5.9), so it waits on question 2 below.

## Questions for Peter Bijma / Jack Dekkers

1. Was the ±1.5 SD search bracket in `selovlp.f90` deliberate, or just a
   starting range? Is ±3 SD (matching the clamp in `trunc_delta`) acceptable?
2. Is the ±3 SD clamp in `trunc_delta` there because of the accuracy of
   `sdutt1` in the far tail, or for another reason? It forces at least
   0.135% of every age class to be selected (see Known issues). Would
   computing the tail exactly (`erfc`) and dropping the clamp be acceptable?
3. With the fix, the equilibrium breeding-goal variance in `ovlpgrp` is
   U-shaped in the number of sires (549 at 5 sires, 515 at 40, 519 at 150)
   and index accuracy *rises* as sire selection gets more intense (0.707 ->
   0.725). The old code shows the same upward trend for 100-150 sires, so
   this is model behaviour, not the fix. Is that expected (e.g. from the
   between-age-class term in the covariance update), or worth a look?
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
