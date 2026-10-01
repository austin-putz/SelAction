# SelAction (development version)

## macOS

* New `fortran_mac/` directory: a fresh copy of `fortran_linux/`, verified to
  build with GNU Fortran 14.2.0 on macOS (Homebrew `gcc`, x86_64) and pass all
  regression fixtures (`tests/run_tests.sh fortran_mac`). No macOS-specific
  source changes were needed. `fortran_mac/` is now the active development
  directory; fixes below marked *(fortran_mac only)* have not been applied to
  `fortran_linux/`.

## Bug fixes

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

* BLUP breeding values combined with a full-sib/half-sib/progeny group under
  overlapping generations (`ovlp`) still give an all-zero response / `NaN`.
  See `tests/README.md`.

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
