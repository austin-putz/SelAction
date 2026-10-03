# Regression tests

Canonical, platform-agnostic input/output fixtures for validating every
implementation of SelAction against each other: `fortran_linux` today, and a
future `fortran_mac`, `fortran_windows`, and an eventual C++ port. Fixtures live here, not
inside a platform directory, so there is exactly one source of truth for
"what should this input produce" - every platform's runner points back at
this same directory instead of carrying its own copy that can drift out of
sync.

This is also the intended validation reference for `SelActionR` (a separate
repository) - its test suite should assert against the same `.in`/`.out`
pairs.

## Layout

```
tests/
  fixtures/
    manifest.txt   maps each fixture to the binaries it's valid input for
    <name>.in       input fed to the program via stdin redirection
    <name>.out      expected output, byte-for-byte
  run_tests.sh
```

## Running

```bash
tests/run_tests.sh                # against fortran_linux (default)
tests/run_tests.sh fortran_mac    # once that directory exists, run against it instead
```

Binaries listed in `manifest.txt` that aren't built in the target platform
directory are skipped (not failed), so the suite can run against a
partially-built platform (useful once `fortran_mac/` exists and is being
brought up incrementally).

## How a fixture is invoked

`selaction` (`fortran_mac/`) and `mssel`/`msseld`/`msselo` (`fortran_linux/`)
are interactive programs: they read prompts from
stdin, and separately re-open a file by name (derived from the "filenames"
prompt answer) to read the bulk of the input and to write output. So a
fixture named `test1` is run as:

```bash
cp tests/fixtures/test1.in ./          # must be present under this exact name
./selaction < test1.in                  # produces ./test1.out (./mssel for fortran_linux)
```

`run_tests.sh` does this in a scratch temp dir per run and diffs the result
against `tests/fixtures/test1.out`.

## Filename length constraint

**Fixture base names must be 8 characters or fewer.** The "filenames" field
inside a `.in` file is read into `fnam`, declared `character (len=8)` in
`selparameters.f90`. A longer name is silently truncated by the Fortran
list-directed read, so the program ends up trying to open a file that
doesn't match the fixture's actual filename - the run fails to find its own
input. Keep both the fixture's file stem and the "filenames" line *inside*
the `.in` file itself under 8 characters and identical to each other.

## manifest.txt

Each fixture must declare which binaries it's valid for.

`fortran_mac/` builds **one binary, `selaction`** (the former `mssel`,
renamed). It accepts every mode, so it is listed for **every** fixture.
`fortran_linux/` still builds the original three programs, and their
entries stay until that directory is updated. `run_tests.sh` skips any
listed binary that isn't built, so each platform runs only its own. The
three legacy programs have different interactive prompt sequences:

- `selaction` (`fortran_mac/`) — identical to `mssel`; accepts `1/2/3/o`
- `mssel` — asks `1/2/3 stage selection, or overlapping generations? (1/2/3/o)`
- `msseld` — asks the same `1/2/3` question but rejects `o`
- `msselo` — only accepts `o`; feeding it a `1/2/3` fixture makes it
  re-prompt against an exhausted stdin stream rather than failing cleanly

Running a fixture against a binary it wasn't written for doesn't error
usefully - confirm the fixture's stage-selection answer matches the binary
before adding a manifest entry.

## Numerical precision and the reference toolchain

**Banner regeneration (2026-10-02).** All 7 `.out` files were regenerated
when the banner changed to "SelAction … version 1.2" (see `NEWS.md`).
Before they were replaced, each new report was checked to be byte-identical
to the old one everywhere below the banner. Only the banner lines changed,
so no result values moved.

These fixtures are captured by actually running a real binary and diffing
byte-for-byte, so they're sensitive to the exact `gfortran` build that
produced them. The canonical reference toolchain used to capture the
current fixtures is:

```
GNU Fortran (Ubuntu 15.2.0-16ubuntu1) 15.2.0
```

For most fixtures this doesn't matter - the underlying computation is well
away from any rounding boundary. But a fixture can legitimately contain a
coefficient that's genuinely close to zero (e.g. `blup1`'s BLUP index weight
for a non-breeding-goal trait, after 25 rounds of `sel1s`'s iterative
BLUP-equilibrium loop) - right at the display precision limit. For values
like that, ordinary compiler-version-level floating-point differences
(instruction scheduling, FMA contraction, vectorization, libm rounding) can
flip the last displayed digit or the sign of a near-zero value with no bug
involved at all. If `run_tests.sh` fails with a diff isolated to a single
near-zero or last-digit value, don't assume it's either "definitely a
regression" or "definitely safe to regenerate" - check whether the affected
value is genuinely near a rounding boundary (as `blup1`'s was) before doing
either.

## Resolved: unconfigured group-type matrix blocks

`selroutines.f90`'s `selection_index` and `intra_sd` build their
`matp`/`matrhs`/`matrfs` "maximum matrix" blocks by looping `i=1,20`/
`j=1,20` for full-sib, half-sib, and progeny groups. A prior fix
zero-initialized the six group arrays (`fsgroupsoff`/`hsgroupsoff`/
`hsgroupsdams`/`proggroupsdams`/`proggroupsoffs`/`proggroupsoffd`, fixed
`real, dimension(20)` in `selparameters.f90`), closing an
uninitialized-read bug for indices beyond a *partially* configured group
count. That still left every division by those arrays running
unconditionally even when a group *type* wasn't configured at all (or an
index exceeded its actual count within a configured type), which is
mathematically undefined (`x/0.0` or `0.0/0.0`) and traps under
`-ffpe-trap=invalid,zero,overflow`.

Both subroutines now take `fsgroups`/`hsgroups`/`proggroups` as arguments
(matching the pattern `info_sources` already used) and guard every
division statement so it only executes when the specific group index is
actually configured (`i.le.locfsgroups` etc., not just "some groups of
this type exist" - a partially-configured count needs the same guard as a
fully-unconfigured one). Verified via a `-finit-real=snan
-finit-integer=-999999999 -ffpe-trap=invalid,zero,overflow -fbacktrace`
debug build: `test1`/`test2s`/`test3s` now run without a single trap
(previously traps at `selroutines.f90:1539` and `:1571`). See `advgrp` in
`manifest.txt` for a fixture built specifically to exercise the
previously-never-tested "progeny groups configured and selected" path
alongside a fully-unconfigured full-sib type.

`blup1` traps under the strict FPE build at an unrelated line
(`selroutines.f90:1800`, `sqrt` of a negative `sigmai` variance component)
that this fix does not touch - see "Resolved: negative `sigmai`" below.

## Resolved: negative `sigmai` under strict FPE traps (two sites)

`selection_index` computes `sigmai` fresh on every call
(`selroutines.f90:1787`) as the selection index's own variance. For
`blup1`/`advgrp`'s info-source pattern (BLUP breeding values + half-sib
group, no own performance), `sigmai` comes out **transiently negative on
round 1** of `sel1s`'s 25-round BLUP-equilibrium loop (confirmed via
debugger: `sigmai=-84.9`, `sigmah=782.8` for `blup1`) - a numerical
artifact of the naive round-1 starting weights, not a legitimate variance.
`test1`'s richer info-source list (which includes own performance) never
hits this; `sqrt` of the negative ratio traps under `-ffpe-trap=invalid`
at two sites: `locrih=(sqrt(sigmai/sigmah))` (`:1800`) and
`locresponse`/`loctotalresponse=...sqrt(sigmai)` (`:2190`/`:2195`).

Both are guarded (`if (sigmai.ge.0.0) ... else ... = 0.0`), verified safe
because neither value survives past round 1: `covariance_update`
*overwrites* (not accumulates) `response`/`totalresponse`/`srih`/`drih`
every round, so only round 25's (already-positive, converged) value ever
reaches display or feeds the next round. Confirmed via a full regression
run: all 5 fixtures byte-identical before and after the guard. A **third**
fix - clamping `sigmai` itself to `0.0` at the source - was tried and
rejected: `corrfs`/`corrhs` (`selroutines.f90:~1969`/`~2144`) also divide
by `sigmai` directly, and flooring it to exactly `0.0` turns that into an
`x/0.0` that trips a real downstream P-value bounds check
(`-error-20- : P-value out of bounds`) even in the *normal*, non-trapping
build - confirmed by testing, not assumed. Division by the negative-but-
nonzero `sigmai` is fine (finite, self-corrects by round 2); only the two
`sqrt` sites needed guarding.

With both sites guarded, `test1`/`test2s`/`test3s` are fully trap-clean.
`blup1`/`advgrp` then trapped one level deeper, inside `rawl3`
(`seltools.f90`) - see "Resolved: `rawl3` division-by-zero under strict
FPE traps" below.

## Resolved: `rawl3` division-by-zero under strict FPE traps

With the `sigmai` guards above in place, `blup1`/`advgrp` under the strict
FPE build trapped one level deeper, inside `rawl3`
(`seltools.f90:167-339`, a general selection-differential utility called
from **10 sites** across `selroutines.f90`/`seldiscrete.f90` - not
specific to this path). This was initially suspected to be a
`log(1.-rho...)` domain trap, but direct reproduction (gdb on the actual
crash, plus an instrumented scratch build logging every call) showed
that guess was wrong on two counts:

- **It's an exact division by zero**, not a log-domain issue:
  `ba=(b-bbc*y)/(1.-y)` at `seltools.f90:325`, where `y=factor(ths)` and
  `factor(x)=.63*exp(3.36*(x-1))+.37*exp(86*(x-1))` evaluates to
  **exactly** `1.0` when `x=1`. Whenever `ths` (mapped from `corrhs`) is
  clamped to exactly `1.0` at the call site (`selroutines.f90:2174`),
  `(1.-y)` is an exact zero. Confirmed via gdb at the crash: `tfs=1,
  ths=1` exactly, `sigmai=99.4` (positive, well past the negative-`sigmai`
  round). The `rhoc`/`rhoc2`/`rhobc`/`rhobc2` terms were all comfortably
  `<1` and were never the problem.
- **It's not round-1-only.** Logging every `rawl3` call for `blup1`/
  `advgrp` showed `corrhs` hits exactly `1.0` only on round 2 of the
  25-round loop (round 1's `corrhs` is negative; from round 3 onward it
  settles below `1.0` and never returns to exactly `1.0`, including at
  round 25, the round that reaches display) - still self-correcting for
  these two fixtures today, but a different fixture's convergence
  trajectory could in principle hit this on the final round.

Fixed by guarding the division at `seltools.f90:325`
(`if (abs(1.-y).lt.1.0e-6) then ba=bbc else ...`) - `bbc` is the fallback
because at `y=1` exactly, `ba`'s weight in the original combination is
zero anyway, making it mathematically indeterminate to solve for; `bbc`
is the nearest already-finite quantity and keeps the downstream
recombination continuous. The fix lives inside `rawl3` itself rather than
at a call site, because 8 of its 10 call sites (all in `seldiscrete.f90`)
pass `tfs`/`ths` with no pre-clamp to `[-1,1]` at all - a call-site fix
would have missed most of the call surface. It is scoped narrowly to this
one reproduced division-by-zero; `rawl3`'s other domain assumptions
(e.g. `log(1.-rhoc)` for those 8 unclamped callers) are not
speculatively hardened, since no current fixture reproduces a problem
there. See `plans/investigate-rawl3-log-domain-trap.md` for the full
reproduction detail.

All 5 fixtures now run completely trap-clean under the strict SNaN/FPE
build for both `mssel` and `msseld`.

## Resolved: `ccprog` uninitialized-read in overlapping generations (`selovlp.f90`)

Building the first overlapping-generations fixture (`ovlp2`, below) surfaced
a genuine uninitialized-read bug distinct from the ones already documented
above, and specific to `ovlp` - none of the discrete-generation fixtures
exercise this code path. `ccprog(ntraits)` (the progeny-test common-
environmental effect, "c-square") is `allocate`d but only ever `read` into
when `initprog.eq."y" .and. initc.eq."y"` (`selovlp.f90:599`, progeny groups
*and* common environment both enabled). But `progsigmac(p)=ccprog(p)*
sigmap(p)` (`:623`) and `ocovcprog(o,p,q)=ccorr(p,q)*(sqrt(progsigmac(p))*
sqrt(progsigmac(q)))` (`:661`) read every element of `ccprog` unconditionally,
regardless of whether progeny groups or common environment were configured
at all.

Under a normal build this silently read whatever garbage happened to be in
the freshly `allocate`d memory - for the `ovlp2` fixture's specific
allocation pattern that garbage happened to be zero-ish and didn't visibly
affect output, which is exactly why this class of bug is dangerous to leave
unfixed rather than proof it's harmless. Under `-finit-real=snan
-ffpe-trap=invalid,zero,overflow`, `ccprog` is poisoned with a signalling
NaN, so `sqrt(progsigmac(p))` at `:661` traps immediately (confirmed via
`gdb`/backtrace pointing directly at that line). This is the same
uninitialized-read *shape* as the `fsgroupsoff`/`hsgroupsoff`/etc. bug fixed
above, just in `selovlp.f90` instead of `selroutines.f90`, and inherited
unchanged from `fortran_orig/selovlp.f90` (confirmed present there too).

Fixed the same way: `ccprog=0.0` added to the existing block of
zero-initializations at the top of `ovlp` (`selovlp.f90:~176-187`, alongside
`fsgroupsoff`/`hsgroupsoff`/etc.), so the unconditional reads downstream are
deterministic zero instead of uninitialized memory when progeny groups or
common environment aren't both configured. Verified: `ovlp2`'s output is
byte-identical before and after the fix (this fixture's uninitialized memory
happened to be already zero-ish), and the strict SNaN/FPE build now runs
`ovlp2` to `end of output` with no trap. A fixture that actually configures
progeny groups + common environment together (exercising `ccprog` with a
real nonzero value) is a good candidate for a future `ovlp` fixture, since
`ovlp2` deliberately doesn't configure progeny groups at all.

## Overlapping generations (`ovlp2`) fixture

`ovlp` (`selovlp.f90`) previously had no regression fixture at all - see the
"Resolved: ..." sections above in this file and in `CLAUDE.md` for the
allocation-order segfault that made it unusable in the first place. It's
also structurally different enough from the discrete-generation fixtures
(`test1`/`test2s`/`test3s`/`blup1`/`advgrp`) that a passing discrete suite
gives zero confidence about `ovlp`'s correctness: `msselo` (built from
`selovlp.f90`, not `seldiscrete.f90`) has its own interactive prompt
sequence - per-sex age classes, propagating info sources forward across
age classes via a `next age-class / -1 to end` loop, and its own generation-
interval computation - none of which is reachable through `mssel`/`msseld`.

`ovlp2` is a 2-trait scenario (`wt`, `gr`) with `nclass=2` (2 age classes
per sex, 4 effective classes internally: sire classes 1-2, dam classes
3-4), truncation selection (`t`), own performance as the only info source
in every age class (entered per-class rather than propagated forward, to
exercise both the explicit-entry and the `next age-class` prompt path), no
full-sib/half-sib/progeny groups, and common environment disabled. It's
deliberately not exhaustive - no groups, no BLUP breeding values, no
info-source propagation across a gap of more than one age class - but it's
enough to run `ovlp`'s core control flow (multi-age-class input, the
generation-interval calculation, the 25-round covariance-update loop) for
the first time under regression testing, and it's what surfaced the
`ccprog` bug above. Verified reproducible (re-running `msselo` against its
own generated `ovlp2.in` reproduces `ovlp2.out` byte-for-byte) and trap-clean
under the strict `-finit-real=snan -ffpe-trap=invalid,zero,overflow` build.

## Resolved: `initblup` uninitialized read (`info_sources`/`info_sourcesovlp`/`info_sources2`/`info_sources3`)

Building `ovlpgrp` (below) surfaced a genuine uninitialized-read bug distinct
from every other one documented in this file, and present in **four**
subroutines in `selroutines.f90`, not just the `ovlp`-specific one:
`info_sources` (discrete 1-stage), `info_sourcesovlp` (`ovlp`),
`info_sources2` (discrete 2-stage), and `info_sources3` (discrete 3-stage).
Each declares a local `character(len=1) :: initblup` that is set to `"y"`
only when info source code 2 (BLUP breeding values) is read, checked in the
condition `... .and. initblup.eq."y"` that decides whether a half-sib-group
code (24-43) should trigger the auto-generated "mean EBV of the dams of the
half-sib group" code (44-63), and explicitly reset to `"n"` at the end of
the subroutine before every return - **except** on the very first call to
that subroutine within an entire program run, where nothing has assigned it
yet and its value is undefined (ordinary Fortran local-variable semantics:
undefined until first assigned, not zero-initialized).

For `ovlpgrp`'s scenario (own performance + full-sib + half-sib + progeny
groups, no BLUP source at all - see below), this should never trigger the
44-63 branch, since no call in the entire run ever reads source code 2. A
`-O2 -Wall` build happened to produce the correct output regardless (the
undefined value on the first-ever call happened not to equal `"y"` for that
particular compile), but a separate `-O0 -fcheck=bounds` build of the exact
same source, run against the exact same input, printed extra "mean ebv of
the dams of hs-group" lines that should not have been possible given the
info-source list actually entered - proof that `initblup`'s value on that
first call was compiler/build-dependent garbage, not a deterministic result
of the input. This is not a hypothetical: it actually flipped the printed
group-covariance information on a build/optimization-level basis, which is
exactly the kind of value-dependent, hard-to-notice bug this file's
FPE-trap/SNaN builds exist to catch - it just happened to need a *different*
build variant (`-fcheck=bounds`, not `-ffpe-trap`) to surface, since reading
one uninitialized character doesn't trip a floating-point trap.

Fixed by explicitly initializing `initblup="n"` at the top of all four
subroutines, alongside each one's existing `locpheninfo="n"`/`presone="n"`-
style initialization block. Verified: after the fix, `-O2 -Wall`,
`-O0 -fcheck=bounds,do,mem,pointer`, and the strict `-finit-real=snan
-ffpe-trap=invalid,zero,overflow` build all produce byte-identical output
for `ovlpgrp.in`, and the full pre-existing 11-fixture suite still passes
unchanged (this fix touches code shared by `mssel`/`msseld`/`msselo` alike).

## Resolved: truncation threshold search under overlapping generations (`ovlp2`/`ovlpgrp` regenerated)

Each round of `ovlp`'s 25-round equilibrium loop, `riddr_root`
(`selroutines.f90`, Ridders' method from Numerical Recipes) solves
`trunc_delta(x)=0` for the truncation threshold `x` at which the number
selected across age classes equals `nsires` (or `ndams`). Two bugs, both
inherited from `fortran_orig/`:

1. **Bracket too narrow.** `selovlp.f90` searched only within ±1.5 index SD
   of each age-class mean, so the threshold could never exceed +1.5 SD over
   the youngest class: at least P(Z>1.5)=0.0668 of it was always selected.
   When the target required more intense selection, `fa*fb>0`, the root was
   not bracketed and `riddr_root` returned silently with `pvalcl` left at
   the bracket edge. `ovlpgrp` (10 sires from 1000+500 candidates) actually
   selected 67.5 sires, and its old expected output reported "number of
   selected sires : 10.000" alongside age-class lines summing to 67.5.
   `ovlp2` looked right only because 0.0668 x 150 is about 10. First widened
   to ±3 SD to match the clamp then in `trunc_delta`; now ±8 SD (see the
   next section).
2. **Side effect taken at the wrong point.** `trunc_delta` writes
   `pvalcl`/`nselec`/`genints`/`genintd` on every call, and `riddr_root`'s
   `ABS(d-zriddr)<tol` exit fires right after evaluating the bracket
   midpoint `c`, not the root. After convergence that exit is the usual
   one, so the loop was periodically kicked off its fixed point (every
   ~9-11 rounds) and round 25's reported values depended on where a kick
   landed - roughly 1% differences between `-O0` and `-O2`. `selovlp.f90`
   now calls `trunc_delta(zriddr)` once more after each `riddr_root`.

Verification: a 72-input sweep (BLUP code 2 alone and with each group type,
with/without own performance and common environment, two population sizes)
plus both fixtures - every run hits its sire/dam targets, `-O0`/`-O2` agree,
and the strict SNaN/FPE/`-fcheck=all` build is trap-free. Varying `nsires`
on `ovlpgrp` shows old and new code agree wherever the old bracket contained
the root (>= 67.5 sires); below that, the old code returned identical output
for 5/10/20/40 sires. `ovlp2.out`/`ovlpgrp.out` were regenerated with GNU
Fortran 14.2.0 on macOS x86_64 (`fortran_mac/msselo`). Open questions for the
original authors are listed in `NEWS.md`.

## Changed: exact normal tail in `sdutt1`; `trunc_delta` clamp removed (`ovlp2`/`ovlpgrp` regenerated again)

`sdutt1` (`seltools.f90`, upper normal tail P(Z>s)) used a 10/20-point
Gauss-Hermite quadrature that is accurate to ~1e-5 within 3 SD but
non-monotonic and wrong by orders of magnitude beyond ~4 SD. `trunc_delta`
clamped its argument to ±3 SD, which made every age class contribute at
least P(Z>3) = 0.135% of its animals - in both `ovlp` fixtures the older
sire class sat exactly on that floor. `sdutt1` now returns
`0.5*erfc(s/sqrt(2))` (exact to ~1e-16), the clamp is gone, and the
`selovlp.f90` threshold bracket is ±8 SD.

Verified in two steps: the swap alone (clamp kept) left 11/12 fixture
checks byte-identical (`ovlpgrp` breeding goal variance 526.938 -> 526.937);
removing the clamp left all 10 discrete-generation checks byte-identical and
changed only `ovlp2`/`ovlpgrp`, which were regenerated (identical to an
independently built prototype). All `sdutt1` arguments seen during the
fixtures are within ±3.5 SD. Full accuracy table, before/after numbers and
the 74-input sweep results are in `NEWS.md`.

## Changed: generation interval under overlapping generations (`ovlp2`/`ovlpgrp` regenerated a third time)

The loops in `selovlp.f90` that sum the generation interval over age classes
assigned instead of accumulating, so the interval that divides every annual
response was wrong (`ovlp2` 1.14 instead of 1.04, `ovlpgrp` 1.05 instead of
1.01). Fixed; both expected outputs regenerated. Total annual response
(economic units): `ovlp2` 16.637 -> 18.173, `ovlpgrp` 28.748 -> 29.626.
The new intervals were checked by hand against the printed class counts.
All discrete-generation fixtures byte-identical. Details in `NEWS.md`.
This error came in with the `fortran_linux` fork (a rename to `genints_local`
when making the code compile); `fortran_orig/selovlp.f90` accumulates
correctly. `fortran_linux/` still has it.

## Previously reported: BLUP breeding values + groups under overlapping generations

Earlier notes recorded that combining BLUP (code 2) with a group under `ovlp`
drove `pvalcl` to 0 in every age class (all-zero response / `NaN`, or
`-error-10-: matrix is singular`). This could **not** be reproduced, before
or after the fix above, in the 72-input sweep; the triggering input was not
saved. It may have been the silent root-finder failure above, but that is
not confirmed. BLUP as the *only* source gives a zero response, which is
correct (no phenotypic information); its "% of total response" lines now
print `n/a` instead of dividing by a near-zero total. If the collapse is seen again, save the `.in` file as a
fixture candidate.

## Overlapping generations with groups (`ovlpgrp`) fixture

`ovlp2` (above) only ever selects "own performance" as an info source, so
two `ovlp`-specific code paths had never executed under any fixture:
`info_sourcesovlp`'s group-code branches (full-sib/half-sib/progeny, codes
4-83) and `ovlp_cov_update`'s handling of the `fs`/`hs` covariance terms
`selection_index` passes back for them - `ovlp_cov_update` has no discrete-
generation counterpart (discrete generations use a different routine,
`covai_update`), so nothing else in this suite exercises it.

`ovlpgrp` is a 2-trait scenario (`wt`, `gr`), `nclass=2`, truncation
selection, common environment **enabled** (unlike `ovlp2`), with all three
group types configured (1 full-sib, 1 half-sib, 1 progeny group, sized like
the already-vetted `test1`/`advgrp` values) and selected as info sources -
paired with own performance - in every
one of the 4 effective age classes. Output is plausible: response direction
matches each trait's economic-value sign, percentages of total response sum
close to 100%, and index variance/accuracy differ sensibly between the sire
and dam age classes given the population's `nsires < ndams` asymmetry.
Verified reproducible, and trap-clean under both the strict SNaN/FPE build
and a full `-fcheck=bounds,do,mem,pointer` build (the latter added
specifically because of what building this fixture found - see the
`initblup` section above).

`ovlpgrp.out` was regenerated after the threshold-search fix above (it
previously selected 67.5 sires instead of 10). `ovlpgrp` doesn't cover BLUP
breeding values under overlapping generations, nor does it cover a partially-
/unconfigured group type the way `advgrp` does for discrete generations -
both remain good follow-up work.

## Adding a new fixture

There are currently 7 fixtures: `test1` (3-trait discrete 1-stage),
`test2s` (discrete 2-stage), `test3s` (discrete 3-stage), `blup1`
(discrete 1-stage isolating the BLUP-only inbreeding path), `advgrp`
(discrete 1-stage isolating the unconfigured/partially-configured
group-type matrix-block guards, including progeny groups), `ovlp2`
(overlapping generations, 2-trait, 2-age-class-per-sex), and `ovlpgrp`
(overlapping generations with all three group types - see above). New
fixtures must come from actually running a real binary with a valid,
non-singular parameter set - do not hand-write expected output.

1. Build the binaries in `fortran_linux/` (see root `README.md`).
2. Prepare a `.in` file (an existing one is the easiest starting template),
   keeping the base name ≤ 8 characters and matching the "filenames" line
   inside it.
3. Run it for real: `cd` into a scratch dir, `./mssel < name.in`, confirm it
   completes without error (a singular/non-positive-definite correlation
   matrix will fail here - that's expected feedback, not a bug).
4. Copy the resulting `name.in`/`name.out` pair into `tests/fixtures/`.
5. Add a line to `manifest.txt` naming which binaries it's valid for and
   what it exercises.
6. Run `tests/run_tests.sh` and confirm it passes.
