# SelAction (development version)

## Build

* 2026-10-05: **build with `make`; output goes to `build/`.** A top-level
  `Makefile` builds `fortran/` into `build/selaction` (with the `.mod`
  files and macOS `.dSYM` there too), so `fortran/` holds only source.
  `build/` is gitignored and made on each machine.
  * `make` builds, `make test` builds and runs the regression tests, and
    `make clean` removes `build/`. `FC`, `FFLAGS` and `BUILD` can be
    overridden.
  * `tests/run_tests.sh` now takes a binary directory, defaulting to
    `build`, and also finds `selaction.exe` on Windows.
  * `README.md`, `CLAUDE.md`, `tests/README.md`, `README_Inputs.md` and
    the plans use the new commands and paths. The explicit gfortran
    command is still documented for building without `make`.
  * Same flags (`-g -O2 -Wall`), so no result changes: all 7 fixtures pass
    byte-for-byte.
* Added `plans/releases.md` (not started): tested prebuilt binaries on
  GitHub Releases, so SelAction can be run without compiling.

## Layout

* 2026-10-05: **one source tree, `fortran/`.** `fortran_mac/` was renamed
  `fortran/` (git history kept), and `fortran_linux/` was removed. The code
  never had anything OS-specific; `fortran_linux/` was an older copy that
  lacked every fix below, including the overlapping-generation errors. It
  remains in the git history (last present in commit `4c3b29b`). The same
  `fortran/` source is built on every platform; other platforms are to be
  checked in CI (test-hardening T6).
  * `tests/run_tests.sh` now defaults to `fortran`, and
    `tests/fixtures/manifest.txt` lists only `selaction` for every fixture.
  * `README.md`, `CLAUDE.md`, `tests/README.md`, `README_Inputs.md`, the
    technical report and the active plans now refer to `fortran/`.
    `AGENTS.md` (new) and `GEMINI.md` point to `CLAUDE.md`.
  * No source or result changes: all 7 fixtures pass byte-for-byte.
* Entries below this point use the directory names of the time:
  `fortran_mac/` is today's `fortran/`.

## Documentation

* 2026-10-05: brought `README.md`, `CLAUDE.md`, `GEMINI.md`,
  `tests/README.md` and `README_Inputs.md` up to date with `fortran_mac/`
  and version 1.2. Highlights:
  * `README.md` now has a project-status section and a roadmap, and
    recommends `fortran_mac/selaction`.
  * Information-source codes, trait-use codes, input rules, error messages
    and the accuracy formula are corrected. The sample output is now a
    real excerpt from `test1.out`.
  * `fortran_orig/` is documented as not building with gfortran 14.2.
    None of its three programs builds, not even `msselo`, which the README
    used to say built fine.
* Added `plans/test-hardening.md`, which comes first, and
  `plans/modernize-inputs-and-outputs.md`, now revision 9. Neither is
  started.

## macOS

* New `fortran_mac/` directory: a fresh copy of `fortran_linux/`, verified to
  build with GNU Fortran 14.2.0 on macOS (Homebrew `gcc`, x86_64) and pass all
  regression fixtures (`tests/run_tests.sh fortran_mac`). No macOS-specific
  source changes were needed. `fortran_mac/` is now the active development
  directory; every change below is *fortran_mac only* and has not been
  applied to `fortran_linux/`.

* **One program: `selaction`.** `fortran_mac/` now builds a single binary,
  `selaction`, instead of `mssel`/`msseld`/`msselo`.
  * `mssel.f90` was renamed to `selaction.f90` (`program selaction`); no
    other change. It accepts every mode: 1, 2 or 3 stages, or `o`.
  * `msseld.f90` and `msselo.f90` were removed. They were cut-down copies
    of `mssel.f90` that refused some modes, and all three called the same
    routines. The originals remain in `fortran_orig/`.
  * Output is byte-identical. All 7 fixtures, including `ovlp2`/`ovlpgrp`,
    which previously ran only through `msselo`, pass through `selaction`.
    `tests/fixtures/manifest.txt` lists `selaction` for every fixture and
    keeps the old names for `fortran_linux/`.
  * The macOS build command is now
    `gfortran -g -O2 -Wall -o selaction ... selaction.f90`. The flags
    matter: without them, `blup1` shows `-0.000` instead of `0.000` for one
    near-zero index weight. The same happens when the old `mssel.f90` is
    built without flags, so this is a floating-point/compiler effect, not
    a change in the code.
  * The banner was left unchanged in this step and updated in the next
    entry.
  * `fortran_linux/` is unchanged and still builds the three old programs.

* **Banner: SelAction version 1.2.** The banner printed on screen and at
  the top of every `.out` report (`intro` in `selroutines.f90`) used to read
  "Multi-Trait Index Selection Software MSSEL … version 1.1".
  * It now reads **SelAction, Multi-Trait Index Selection Software,
    version 1.2**.
  * It keeps the original credit: "developed by Marc J.M. Rutten and Piter
    Bijma, Animal Breeding and Genetics Group, Wageningen University, 2000".
  * It adds "updated by Austin Putz and Jack Dekkers, Iowa State
    University, 2026".
  * This is a text change only. All 7 fixture `.out` files were
    regenerated because each starts with the banner. Before they were
    replaced, each new report was checked to be byte-identical to the old
    one everywhere below the banner. The only difference is the banner,
    which is 4 lines longer.

* Removed `fortran_mac/input.txt` and `fortran_mac/input.out`. They were a
  leftover sample run from the Linux fork, not part of the original
  distribution, and they no longer matched each other: re-running
  `input.txt` gives a half-sib group of 10 animals instead of the 190 in
  `input.out`. Nothing referenced them. The `test1` fixture covers the same
  3-trait example. The copies in `fortran_linux/` stay until that directory
  is updated.

* `tests/run_tests.sh` no longer passes when nothing ran. Before, a
  platform with no binaries built reported "0 passed, 0 failed" and exited
  successfully. Now these count as FAIL and the script exits non-zero:
  * a fixture with **none** of its listed binaries built
  * a fixture whose `.in`/`.out` is missing

  A single listed binary that isn't built is still a SKIP, as long as
  another one ran.

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

### 2. Exact normal tail probabilities; ±3 SD clamp removed (commit 29d251d)

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

### 3. Generation interval computed correctly

The generation interval L = (L_s + L_d)/2, with L_g = sum over age classes
of c * (selected from class c) / (total selected), divides every annual
response. In `ovlp` the loops meant to accumulate it assigned instead
(`genints_local=genints+tempresponse`), so only the highest-numbered active
class was added - on top of the full value `trunc_delta` had left in
`genints` in threshold mode (double-counting that class), and on top of an
unassigned (in practice zero) value in specified-count mode. Fixed in all
four places (`genints_local=genints_local+tempresponse`, and the same for
dams). This error was introduced by variable renaming in the modernized
fork; `fortran_orig/selovlp.f90` correctly accumulates both paths. Checked
against the class counts in the new output:

| | L before | L after | L by hand | total response before | after |
|---|---|---|---|---|---|
| `ovlp2` (threshold) | 1.14 | 1.04 | 1.040 | 16.637 | 18.173 |
| `ovlpgrp` (threshold) | 1.05 | 1.01 | 1.014 | 28.748 | 29.626 |
| specified count (sires 6.5/3.5, dams 35/15) | 0.65 | 1.32 | 1.325 | 49.965 | 16.662 |

In threshold mode the annual response rises by about the ratio of the old to
the new L. In specified-count mode it falls by a factor of 3, more than the
factor 2 in L: the too-small L inflated the annual response, which also
feeds the between-age-class lag term of the covariance mixture, so the old
run's genetic variances were inflated too (breeding goal variance 962 vs
612; phenotypic variance of `wt` 112 vs 97, base 100). The new values
behave as selection should. `ovlp2`/`ovlpgrp` regenerated; all discrete
fixtures byte-identical.

## Bug fixes

* `msselo` now warns (output file and screen) when, in some age class, a
  trait used in the index or breeding goal has no phenotypic information
  source and no genetic correlation with a trait that has one - e.g. BLUP
  (code 2) as the only source. Its genetic variance then goes to zero and
  the response is not meaningful; before, `ovlp` ran on silently to an
  all-zero response. The rule is the discrete drivers' check
  (`note_pheninfo`), but as a warning: the discrete drivers stop and ask for
  new sources or correlations, which would change `ovlp`'s input sequence.
  Checked: BLUP-only input warns for both traits in all four classes; one
  trait BLUP-only and uncorrelated warns for that trait only; the same with
  a genetic correlation of 0.3 gives no warning. Numbers unchanged in every
  case; all fixtures byte-identical (normal and strict builds).
* The multistage threshold search (`sseuil1/2/3`, `seltools.f90`) now
  prints a WARNING (screen, and the output file when open) if Newton's
  method has not reached its tolerance after its 20 steps. The original
  failure test checked for 50 iterations and so never fired; non-convergence
  was silent. The routines still return the last threshold, so no numbers
  change. Checked with a driver against the previous code on 72 one-, two-
  and three-stage cases: identical thresholds, and no warning for any
  feasible target; an infeasible three-stage target (joint pass rate of the
  first two stages below the requested fraction) is now reported instead of
  passing silently. A copy limited to one Newton step prints the warning as
  intended. All fixtures byte-identical, no warning printed.
* `sel1s`/`sel2s`/`sel3s` zero `ccprog` before use and reset `dsigmai`
  before accumulating it. `ccprog` (progeny-test c-square) is only read when
  both progeny groups and common environment are requested, but feeds the
  progeny-group covariance blocks whenever progeny groups are used - the
  same bug fixed earlier in `selovlp.f90`. Shown with a scratch build that
  writes garbage (`ccprog=0.5`, `dsigmai=1000`) into both right after
  allocation: on an input with progeny groups and no common environment the
  index weights changed (progeny-group weight -0.479 -> -0.412); with the fix
  the poisoned and clean runs are identical. The `dsigmai` reset (only used
  for the starting dam EBV covariance when `indexdiff='y'`) had no visible
  effect - the 25 rounds wash it out - but the read was undefined. All
  fixtures byte-identical (normal and strict builds).
* `sel2s` with `nsires == ndams` now removes half-sib sources 24-63 from
  the stage-2 lists, as `sel1s`/`sel3s` do; it removed only 24-43, leaving
  the "mean ebv of the dams of hs-group" sources that BLUP adds. Those got
  weight 0 (they are uncorrelated with everything left), so no response
  changed - the stage-2 index just listed spurious zero-weight sources.
  Checked with a two-stage input with BLUP + one half-sib group at
  `nsires = ndams = 50`: it now matches the same input without the
  half-sib group except for the echoed group description, exactly as
  one-stage does. All fixtures byte-identical (normal and strict builds).
* **Multistage joint normal tails were silently wrong for small fractions
  and high stage correlations** (`seltools.f90`, `racine`). `sdutt`'s
  adaptive Gauss-Hermite loop runs `nrac=10..30`, but the node/weight tables
  were only filled for 2-20 points. Past 20 points the empty tables gave
  exactly 0.25 (2-D) / 0.125 (3-D), two equal values counted as converged,
  and that was returned without warning. Added the 22-30 point tables,
  generated with the rule the existing tables follow exactly
  (`h(i,n)=sqrt(2)*x_i`, `w(i,n)=W_i/x_i` over the positive roots of the
  2n-point Gauss-Hermite rule; reproduces the 2-20 tables to 2e-13). Written
  as double-precision literals because the smallest weights (~1e-46)
  underflow a default real. The 2-20 point lines are unchanged.
  - On a 686-case grid (thresholds -1..3.5, correlations up to 0.93, 2-D and
    3-D) checked against scipy: 108 cases previously came back as 0.25/0.125
    (e.g. P(Z1>-1, Z2>2.5; r=0.93) = 0.0062 returned as 0.25); now every case
    is within 8.5e-6 of exact.
  - End to end, `test2s` with the sire fractions changed to 0.005 / 0.4
    (total 0.002): total sire response after stage 2 was 0.615 economic
    units, *below* the 18.254 after stage 1 alone; it is now 19.906.
    Same for 0.003 / 0.5: 0.470 -> 20.140. At total fraction 0.005 nothing
    changes (18.348 and 18.601, identical before and after).
  - All 7 fixtures byte-identical (normal and strict debug builds); none
    reaches more than 20 quadrature points.

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
* With `nsires == ndams` (mating ratio 1, no paternal half sibs), the
  earlier-stage source lists of `sel2s`/`sel3s` are not filtered for
  half-sib sources; only the final-stage list is. Unchanged from the
  original; raised as Question 6 in the open-questions report.
* `fortran_linux/` still has every bug fixed above. `fortran_orig/` has all
  of them except the generation-interval error (change 3), which was
  introduced in the Linux fork.

## Questions for Piter Bijma / Jack Dekkers

The consolidated write-up, with equations, evidence and recommendations,
was sent on 2026-10-05:
`correspondence/2026-10-bijma-dekkers/SelAction_open_questions.pdf`. It
also asks for worked examples with known answers, for the test suite. The
list below is the working list it was built from.

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
5. Generation interval (overlapping generations, change 3): we now compute
   L_g = sum_c c * n_g,c / sum_c n_g,c, with the youngest class at age 1 and
   classes weighted by the numbers selected, and L = (L_s + L_d)/2, which
   divides both paths' responses. `fortran_orig/` already computes this;
   the error fixed in change 3 was introduced in the Linux fork. Please
   confirm the age-class interpretation (e.g. not weighting by long-term
   genetic contributions, and youngest class = 1 rather than 0 or a
   separate age at first offspring).
6. `Poissoncorr` (`selroutines.f90`, finite-family inbreeding correction):
   when M_s < 20 both sexes use the published adjustment
   (1-rho)p + rho*max(p, 1/M_s), representing the move towards selection
   between sire families (Bijma and Woolliams 2000, Genetics 156:361, Eq. 13;
   checked against the paper - the paper applied it for 5 and 10 sires and
   in one extreme 20-sire scheme). At M_s = 20 this adjustment is switched
   off while the beta terms in `hyper_correct` are switched on, so dF jumps
   (4.590% at 19 sires to 4.682% at 20 in one test1 variant). What
   motivated this cutoff? Same code in `fortran_orig/`.
7. Three-stage selection (`sel3s`): the conditional correlation r_13|2 is
   set to 0 instead of (r13 - r12 r23)/sqrt((1-r12^2)(1-r23^2)), and stage
   index correlations are ratios of accuracies capped at 0.93. For nested
   optimal indices the ratio is exact and r_13|2 = 0 follows from it, but
   not once the cap binds. Was the cap introduced for the numerical
   integration, and should r_13|2 be computed so it stays correct when the
   cap binds?
8. With M_s = M_d (no paternal half sibs) half-sib sources are removed
   only from the final-stage source list; earlier-stage indices of two- and
   three-stage selection keep them if entered. Should they be removed there
   too?
9. `selection_index` fills the lower triangle of the source covariance
   table by copying blocks without transposing trait indices, and the EBV
   covariance matrices S, D are not exactly symmetric after the Bulmer
   update (the code evaluates G'P^-1G v separately from G'b). Should S and D
   be symmetrised (and the blocks transposed)? In our tests the asymmetry
   decays to rounding level by about round 13 of 25 and symmetrising
   changes no printed output, so the briefing lists this for information
   only.
10. Overlapping generations: the original program description says
    intensities are adjusted for family structure (Meuwissen 1991) in each
    sex-age class, but `ovlp` computes `rawl3` and discards it (same in
    `fortran_orig/`). Was the correction meant to enter the response, and
    how with a common truncation point across classes?
11. Overlapping generations: the lag between age classes (class means in
    the threshold search, lags in the covariance mixture) uses each sex's
    own path response per year (`stotalresponse`/`dtotalresponse`, the
    "let op" lines). Should it be the population gain for both sexes?
    Effect <1% of response in our examples.


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
