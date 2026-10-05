# Plan: test hardening before further changes to `fortran/`

## Status

**Approved, revision 2 (2026-10-05).** Austin's answers to the four
questions are recorded under "Decisions" below. Nothing is implemented yet. Directory names updated 2026-10-05:
`fortran_mac/` is now `fortran/`, and `fortran_linux/` was removed, so
there is one source tree to test on every platform.

This plan comes **before** `plans/modernize-inputs-and-outputs.md`. Austin's
rule is that SelAction must be "bullet proof" in accuracy and quality
before bigger changes, and before the later port to R. The measurements
below show that today's tests can't support that yet.

All numbers in this report were measured on 2026-10-02 against commit
`006d3ac`: GNU Fortran 14.2.0, macOS x86_64, R 4.5.3. The commands to
reproduce them are in the appendix.

## Decisions (2026-10-05)

| # | Question | Decision |
|---|---|---|
| 1 | Byte-exact or tolerant golden comparison | **Both, by role.** The golden fixtures stay **byte-exact** on the reference toolchain (macOS, gfortran 14.2, `-g -O2 -Wall`), so any change, including layout, is caught. The tolerant comparator (`compare_out.R`: `-0.000` = `0.000`, last-digit numeric tolerance, all text exact) is used only where floating-point details legitimately differ: the strict `-O0` build, other platforms/compilers (Linux and other CI runners), and the R port. Correctness and property tests always use explicit numeric tolerances. |
| 2 | Dead `selinbreeding.f90` | **Delete it from `fortran/`** (new step T0). Verified: `MODULE Inbreeding` is never `USE`d. The live ΔF calculation is `dFmtblup` in `selroutines.f90`, called from `seldiscrete.f90:746`, so **inbreeding is still calculated exactly as before**. Users who want ΔF for a scheme still get it in the normal output; dummy traits can be added if needed. The original stays in `fortran_orig/`. |
| 3 | Sources of independently known answers | None in hand. **Ask Jack Dekkers and Piter Bijma** whether they have, or can generate, worked examples with known answers. Austin can help produce them. Until then, T4 uses cases derived from published theory. |
| 4 | Who writes and checks correctness cases and properties | **Claude drafts** each case and property, with its derivation, expected values and the R code that computes them. **Austin, Jack and Piter verify them later.** Until then, each case is marked *provisional* (see "Review status" in T4). |

---

## Part 1: Report on the current tests

### 1.1 What exists today

- **7 regression ("golden") fixtures** in `tests/fixtures/`, run by
  `tests/run_tests.sh`:

  | Fixture | What it exercises |
  |---|---|
  | `test1` | 3-trait 1-stage |
  | `test2s` | 2-stage |
  | `test3s` | 3-stage |
  | `blup1` | BLUP-only 1-stage |
  | `advgrp` | unconfigured / partially configured group types |
  | `ovlp2` | overlapping generations, own performance |
  | `ovlpgrp` | overlapping generations with all group types |

- Each fixture runs the program on a fixed input and compares the `.out`
  report **byte for byte** with a saved copy.
- Since commit `8453140`, the runner fails (rather than silently passing)
  when no binary is built or a fixture file is missing.
- `tests/README.md` documents each fixture and the bugs they uncovered.
  The documentation is good.

### 1.2 Code coverage

Coverage measures which lines of code actually run during the tests. It
was measured with an instrumented build (`gfortran --coverage -O0`, read
with GCC's `gcov`) running all 7 fixtures.

| File | Lines executed | Branches taken at least once |
|---|---|---|
| `seldiscrete.f90` (1/2/3-stage drivers) | 73.3% of 3,200 | 49.9% of 7,722 |
| `selovlp.f90` (overlapping generations) | 85.7% of 934 | 57.1% of 2,144 |
| `selroutines.f90` (index, matrix, I/O helpers) | 80.5% of 1,873 | 81.4% of 1,560 |
| `seltools.f90` (normal-distribution maths) | 88.1% of 915 | 66.5% of 158 |
| `selaction.f90` (main program) | 90.5% of 21 | — |
| **All live code** (excluding `selinbreeding.f90`) | **≈79%** | **≈55%** |
| `selinbreeding.f90` | 0% of 195 | — |

`selinbreeding.f90` is expected to show 0%. It holds `MODULE Inbreeding`,
a dead duplicate of the live `dFmtblup` in `selroutines.f90`: it is
compiled but never `USE`d (see `CLAUDE.md`).

**Branches matter more than lines here.** About half of the if/else paths
in the two main driver files have never been taken by any test.

### 1.3 What is never tested

**Routines that never run at all:**

| Routine (file) | What it handles |
|---|---|
| `traitinfo2`, `traitinfo4`, `traitinfo6` (`selroutines.f90`) | Trait/info-source input for **dams when sires and dams have separate indices** (`different indices for sires and dams = y`), in 1-, 2- and 3-stage selection |
| `traitinfo3`, `traitinfo5` (`selroutines.f90`) | Same, stages 2/3; only 19% of lines run |
| `note_matrat` (`selroutines.f90`) | **Mating ratio 1** (`nsires = ndams`), which has special information-source rules |
| `note_pheninfo` (`selroutines.f90`) | A **trait with no phenotypic information** that is correlated with traits that have it. This triggers an interactive correction prompt |
| `srec_dutt` (`seltools.f90`) | A branch of the multivariate normal integral used in multistage selection; `sdutt` and `sintvi` run only about half their lines |

**Largest blocks of code that never run**, e.g. `seldiscrete.f90`
388–455, 466–577, 1590–1788, 3275–3487:

- the mating-ratio-1 checks
- the sire/dam phenotypic-information checks with separate indices
- printing of the **dam index** ("INDEX INFORMATION FOR DAMS")
- in `selovlp.f90` 127–147: **fixed numbers selected per age class**
  (only truncation selection is tested)

**Input features no fixture uses:**

| Feature | Current fixtures |
|---|---|
| Separate indices for sires and dams | all 7 use `n` |
| Equal numbers of sires and dams | never |
| Common environment **off** in discrete generations | only off in `ovlp2` |
| Goal-only traits (`use = h`) | never; traits are only `b` or `i` |
| A single trait | never; only 2 or 3 traits |
| More than 3 traits | never |
| More than one group of the same type | never |
| Groups / progeny in 2- and 3-stage selection | partly (`test3s` has FS+HS in stage 3; no progeny) |
| Overlapping generations: fixed numbers, more than 2 age classes | never |
| Any invalid input or error path | never |

### 1.4 Strict debug build

All 7 fixtures were run through a build with the following flags:

```
-O0 -g -fcheck=all -finit-real=snan -finit-integer=-999999999
-ffpe-trap=invalid,zero,overflow -fbacktrace
```

- `-fcheck=all` checks every array index and pointer.
- `-finit-real=snan` makes any use of an unset real value trap.
- `-ffpe-trap=invalid,zero,overflow` stops on invalid floating-point
  operations.

**Result: no traps or runtime errors in any fixture.** This confirms the
earlier fixes (`ccprog`, `initblup`, group guards, `sigmai`). Six outputs
are identical to the golden files. `blup1` differs only by `-0.000` vs
`0.000` for one near-zero weight. That is the known display-rounding
sensitivity documented in `tests/README.md`.

The caveat is that the strict build only checks code that runs. It is
blind to the ~21% of lines and ~45% of branches above. **It is also not
scripted**: so far it has only been run by hand while fixing bugs.

### 1.5 Grades

| Kind of test | What it answers | Status | Grade |
|---|---|---|---|
| Regression (golden) | "Did the output change?" | 7 cases, byte-exact, well documented; ≈79% lines / ≈55% branches | **B−** |
| Correctness (validation against independent answers) | "Is the output *right*?" | none | **F** |
| Unit tests of maths routines | "Does each routine work on its own?" | none | **F** |
| Property (metamorphic) tests | "Do results change the way theory says they must?" | none | **F** |
| Error / invalid-input tests | "Does bad input fail cleanly?" | none (planned in the I/O plan, Phase 2) | **F** |
| Strict-build checks | "Any hidden memory or uninitialised-value bugs?" | clean, but manual and only on covered code | **C** |
| Coverage measurement | "What do the tests miss?" | measured once, for this report | **D** |
| Automation (CI) | "Do the tests run on every change?" | none | **F** |
| **Overall** | | | **D+** |

### 1.6 The most important finding

**Golden tests prove the output didn't change. They don't prove it is
correct.** Every `.out` file was captured by running SelAction itself. If
SelAction was wrong at that moment, the fixture now *protects the wrong
answer*.

This has already happened once. The overlapping-generation fixture was
first captured while `ovlp` was selecting 67.5 sires instead of the
requested 10. Only reading the output closely revealed it.

For accuracy, and to serve as the reference for the R port, the test
suite needs checks against answers **not produced by SelAction**.

---

## Part 2: Kinds of tests (short guide)

- **Regression / golden test:** run a fixed input and compare the output
  with a saved copy. This catches *unintended changes*. It is cheap and
  broad, but it cannot tell right from wrong.
- **Correctness / validation test:** compare the program with an answer
  worked out independently, for example:
  - a textbook formula
  - a hand calculation
  - a separate implementation in R
  - a published worked example

  This catches *wrong answers*. It is the core of "bullet proof".
- **Unit test:** call one routine directly with known inputs, for example
  "truncation at p = 0.1 gives intensity 1.7550". It pinpoints *which*
  routine is wrong.
- **Property (metamorphic) test:** run the program twice with inputs
  related in a known way, and check that the outputs are related as theory
  says. For example, doubling all economic values must double economic
  response and leave index accuracy unchanged. It is powerful when the
  exact answer is unknown.
- **Error test:** feed invalid input and check that the program stops with
  the right message and exit code, rather than hanging or giving
  plausible-looking numbers.
- **Strict build / sanitizer run:** run the tests with the compiler's
  memory and floating-point checks on. It catches out-of-bounds writes and
  uninitialised values that silently corrupt results.
- **Coverage:** measures which code the tests run. It finds blind spots.
  High coverage is necessary, not sufficient.
- **Continuous integration (CI):** runs everything automatically (GitHub
  Actions) on every push, on Linux and macOS.

---

## Part 3: Plan

General rules for every phase:

- Work in `fortran/` and `tests/` only.
- **No equation changes.** If a test exposes a suspected numerical error,
  stop. Document it, report it with evidence, and decide with Austin
  (Piter Bijma / Jack Dekkers if needed) before touching code.
- New fixture names are ≤ 8 characters (the `fnam` limit). New manifest
  entries list `selaction` only.
- Every phase gets a `NEWS.md` entry. The test layout and how to run it go
  in `tests/README.md`.
- **Fail loudly:** every new check exits non-zero on failure.

### Target layout

```
tests/
  run_tests.sh            # golden fixtures (existing)
  run_all.sh              # NEW: runs every layer below, one summary, non-zero on any failure
  fixtures/               # golden .in/.out + manifest.txt (existing, extended in T2)
  unit/                   # NEW (T3): small Fortran driver programs that call one routine each
  validation/             # NEW (T4): cases with independently computed expected values
  properties/             # NEW (T5): input pairs/groups + the relation their outputs must satisfy
  reference/              # NEW: R scripts that compute expected values, plus their committed output
  tools/
    compare_out.R         # NEW (T1): numeric-tolerant .out comparison
    coverage.sh           # NEW (T1): instrumented build + gcov summary
    strict.sh             # NEW (T1): strict debug build + all fixtures
```

**R is the tooling language for tests**, as decided for the driver. R
computes reference values independently of Fortran and does the tolerant
comparisons.

Reference values are **committed** (CSV) along with the R script that
produced them. Tests then don't recompute them at run time, and the CI
doesn't need extra R packages beyond what generating the references used.

### T0: Remove dead code (`selinbreeding.f90`)

- Run `git rm fortran/selinbreeding.f90`.
- Drop it from `SOURCES` in the top-level `Makefile`, and from the
  "without make" fallback command in `README.md` and `CLAUDE.md`.
- Update the module notes in `README.md`, `CLAUDE.md`
  and `tests/README.md`. The `USE selroutines, ONLY: trunc` note in
  `CLAUDE.md` then applies only to `fortran_orig/`.
- **Acceptance:**
  - all 7 fixtures stay byte-identical
  - the strict build stays clean
  - a `grep` confirms no remaining reference to `Inbreeding` or
    `selinbreeding` in `fortran/`
  - `NEWS.md` entry

### T1: Test tooling

- **Builds go through the `Makefile`.** Each tool builds its own copy
  side by side with `make BUILD=build/<name> FFLAGS="…"` (e.g.
  `build/strict`, `build/coverage`) instead of its own gfortran command,
  so the source list and order live in one place.
- **`tests/tools/strict.sh`:** builds `selaction` with the strict flags
  from 1.4 into `build/strict` and runs every fixture. It fails on
  any trap, runtime error or crash. Output is compared with
  `compare_out.R` (below), not byte for byte, because `-O0` may flip the
  sign of a near-zero value (`blup1`).
- **`tests/tools/coverage.sh`:** builds with `--coverage`, runs every
  fixture (and later the validation and property inputs), and prints the
  line and branch table from 1.2.
  - It locates GCC's `gcov` next to `gfortran`. Apple's `/usr/bin/gcov` is
    LLVM's and can't read GCC's coverage data files.
  - It excludes `selinbreeding.f90`.
  - With `--min-lines N`, it fails below a threshold.
- **`tests/tools/compare_out.R`:** compares two `.out` files. Non-numeric
  text must match exactly. Numbers must agree within an absolute/relative
  tolerance, and `-0.000` equals `0.000`. It is used by the strict build,
  the validation tests, and later for comparing platforms (Linux vs macOS,
  and the R port).
- **`tests/run_all.sh`:** runs `make`, then golden + strict + unit +
  validation + properties (whichever exist) and prints one summary.
  A `make check` target can call it.
- **Acceptance:**
  - `run_all.sh` passes on the current code.
  - Deliberately breaking a fixture, the build, or a number makes the
    matching layer fail.

### T2: Close the coverage gaps with new golden fixtures

New inputs for every untested feature in 1.3. Each new fixture is a
golden test, so it **also gets a sanity review**: read the output and
check that the numbers are plausible (sires selected = sires requested,
accuracies between 0 and 1, and so on) before its `.out` is accepted. The
property tests in T5 then cross-check several of them.

| Proposed fixture | Covers |
|---|---|
| `sxd1` | 1-stage, separate sire/dam indices, **different** sources per sex (`traitinfo2`, dam-index output) |
| `sxd2`, `sxd3` | the same for 2- and 3-stage (`traitinfo4`/`6`, rest of `traitinfo3`/`5`) |
| `matrat1` | `nsires = ndams` (`note_matrat`) |
| `nophen` | a trait with no phenotypic source, correlated with one that has one. Covers `note_pheninfo` and the correction-prompt path, with the answers scripted in the `.in` |
| `noce1` | discrete 1-stage, common environment off |
| `goalonly` | a goal-only trait (`use = h`) |
| `onetrait` | a single trait |
| `fivetr` | 5 traits (larger matrices, more correlations) |
| `multigrp` | 2+ groups of the same type (e.g. 2 FS groups, 2 HS groups recorded for different traits) |
| `prog2s`, `prog3s` | progeny groups in 2- and 3-stage selection |
| `ovlpfix` | overlapping generations, **fixed numbers** selected per age class |
| `ovlp3ac` | overlapping generations, 3 age classes per sex, with an age class excluded from selection if the input supports it |

- Before writing fixtures, walk every conditional `read *` and list which
  fixture covers it. This is the same map Phase 1 of the I/O plan needs
  for its translator.
- **Acceptance:**
  - every live subroutine runs at least once
  - **≥ 95% of live lines** run
  - branch coverage is reported, aiming for **≥ 75%** taken. The
    remaining branches are mostly interactive "wrong input, re-prompt"
    paths, which the error tests in the I/O plan's Phase 2 will cover.
  - all new fixtures pass the strict build

### T3: Unit tests for the maths routines

Small Fortran programs in `tests/unit/` call one routine directly. Their
results are compared with values computed independently in R
(`tests/reference/unit_reference.R`, output committed as CSV).

| Routine | Reference |
|---|---|
| `trunc` (threshold, intensity, variance reduction k) | R `qnorm`/`dnorm`. Table below |
| `gcef` (normal quantile) | R `qnorm`, including extreme tails |
| `sdutt1` and the other univariate normal tails | R `pnorm(lower.tail = FALSE)` |
| `sabf`, `sintvi`, `sdutt`/`srec_dutt` (bi-/multivariate normal integrals) | R package `mvtnorm` (`pmvnorm`) |
| `invrt` (matrix inverse) | R `solve()`, including near-singular and singular cases |
| `jacobi` (eigenvalues) | R `eigen()` |
| `rawl3` (finite-population correction of intensity) | the formulas in Meuwissen (1991) / Rawlings (1976), coded independently in R. If the published tables are available, also compare with them |

Reference intensities (R 4.5.3, `i = dnorm(qnorm(1-p))/p`):

| p | threshold | intensity i | k = i(i − x) |
|---|---|---|---|
| 0.50 | 0.0000 | 0.7979 | 0.6366 |
| 0.20 | 0.8416 | 1.3998 | 0.7814 |
| 0.10 | 1.2816 | 1.7550 | 0.8309 |
| 0.05 | 1.6449 | 2.0627 | 0.8619 |
| 0.01 | 2.3263 | 2.6652 | 0.9032 |

- **Tolerances** reflect single precision (`real`): about 1e-5 relative
  for most routines. Any routine that misses its tolerance is a finding to
  report, not to "fix the test".
- **Acceptance:** every listed routine has a unit test that passes, or a
  documented, explained deviation.

### T4: Correctness (validation) tests

These are scenarios whose results are known independently of SelAction.
Each case has three parts:

1. an input file
2. `expected.csv`: quantity, value, tolerance and source
3. a short derivation (`README.md` in the case folder), citing the formula
   or paper

The expected values come from **separate R code written from the
published theory and the technical report, not translated from the
Fortran**.

Candidate cases. Each one encodes theory, so it starts as *provisional*
until Austin, Jack or Piter verifies it (Decision 4 and the no-guessing
rule). If a provisional case fails, that is reported as a finding; the
Fortran is never changed to make it pass without that review.

1. **Single-trait mass selection, internal consistency.** With own
   performance only:
   - the index accuracy must equal √(equilibrium h²)
   - the index variance must equal the equilibrium phenotypic variance
     times the squared index weight

   These relations hold whatever the Bulmer and finite-population
   corrections do.
2. **Single-trait Bulmer equilibrium.** Iterate the textbook Bulmer
   recursion (Bulmer 1971; Falconer & Mackay ch. 11) independently in R
   for the same h², p and family structure. Compare:
   - equilibrium h² and phenotypic variance
   - response = i·h·σ_A (equilibrium values)

   This uses the intensity *after* SelAction's finite-population
   correction, which must therefore be computed independently too (T3,
   `rawl3`).
3. **Two-trait selection index by hand.** Compute b = P⁻¹Gv for a small
   base-population case in R and compare SelAction's index weights.
   SelAction iterates to equilibrium, so either compare the first round
   (if that can be exposed) or compute the equilibrium P and G in R using
   the reported equilibrium parameters. Which of these is used gets
   decided in T4 design.
4. **Published examples.**
   - Re-run the worked examples in Rutten et al. (2002) and in the original
     manual (`manual/`, `examples/output_discrete_1_stage/`) and compare
     the printed results.
   - For ΔF, compare the Bijma & Woolliams (2000) predictions for cases
     they tabulate.
   - Any differences are reported and explained, not hidden.
5. **Two-stage selection with no new information.** If stage 2 adds no
   information, selecting p₁ then p₂ on the same index must equal 1-stage
   selection with p = p₁·p₂ (property of truncated multivariate normal
   selection, Tallis 1961). This checks the multistage integration code.

- **Review status.** Every case (and every T5 property) records a
  `status` field in its `README.md`/`expected.csv`:
  - `provisional`: drafted by Claude from published theory
  - `verified`, with who verified it and when: checked by Austin, Jack
    Dekkers or Piter Bijma

  Provisional cases still run and still fail loudly. The `run_all.sh`
  summary reports how many cases are provisional and how many verified,
  so it is always visible how much of the correctness suite has been
  independently checked. This plan is complete with every case drafted;
  verification happens later, in batches, on Austin's schedule.
- **Request to the original authors.** Add to the next message to Jack and
  Piter (see `correspondence/`) a request for worked examples with known
  answers. Even a few hand-checked cases (index weights, equilibrium
  parameters, response, ΔF) would be the strongest tests in this suite.
  Austin can help generate them.
- **Out of scope here:** the open questions already sent to Piter Bijma
  and Jack Dekkers (`correspondence/2026-10-bijma-dekkers/`). Tests aren't
  written for behaviour still under question; they are added once the
  authors answer.
- **Acceptance:**
  - every approved case passes within its documented tolerance, or
  - its deviation is written up as a finding for Austin.

### T5: Property (metamorphic) tests

Each property runs SelAction on two or more related inputs and checks the
relation between outputs, using `compare_out.R`. As with T4, each property
is drafted by Claude and stays **provisional** until Austin, Jack or Piter
verifies it.

| Property | Change to the input | Required relation in the output |
|---|---|---|
| Economic-value scaling | multiply every economic value by c > 0 | index weights × c; responses in trait units, accuracies, index-variance ratios, % contributions, ΔF unchanged; economic-unit responses × c |
| Trait-unit scaling | multiply trait k's phenotypic SD by c, divide its economic value by c | trait-unit response of k × c; everything in economic units unchanged |
| Trait order | permute the traits, and the matrices with them | identical results per trait name |
| Identical sire/dam indices | `different indices = y`, with dam sources identical to sire sources | identical to `different indices = n`. Cross-checks the new `sxd*` code paths against the well-tested ones |
| Uninformative extra trait | add an index-only trait with zero phenotypic, genetic and c² correlation to all others | its index weight is 0; all other results unchanged |
| Selection intensity | lower p (fewer selected) | higher response *(direction to confirm under Bulmer and finite-population effects)* |
| Number of sires | more sires, same everything else | lower ΔF *(to confirm)* |
| Two-stage reduction | case 5 in T4 | same as 1-stage with p₁·p₂ |

Acceptance: every drafted property holds on the base cases and on several
T2 fixtures. Each property carries the same `provisional`/`verified`
status as the T4 cases.

### T6: Continuous integration (GitHub Actions)

- **Trigger:** every push and pull request.
- **Platforms:** `ubuntu-latest` and `macos-latest`.
- **Steps:** install gfortran and R, run `make test` (the same source
  tree and Makefile on every platform; there are no per-platform copies),
  then run `tests/run_all.sh`.
- A Windows runner (gfortran via MSYS2) can be added once Linux and macOS
  are green.
- **Golden outputs are compared byte for byte on macOS,** the reference
  toolchain. On Linux they use `compare_out.R` with tight tolerance, if
  the byte comparison differs only in last digits or `-0.000`; this
  difference is documented.
- Once CI is green, add the real build/test badge to `README.md`. That
  closes the TODO in `CLAUDE.md`.
- **Acceptance:** CI runs green on both platforms, and a deliberately
  broken commit turns it red.
- **Next:** prebuilt downloads on GitHub Releases build on this workflow;
  see `plans/releases.md`.

### T7: Coverage gate

- `coverage.sh` runs in CI and prints the table in the job log.
- CI fails if live-line coverage drops below the level reached in T2
  (target ≥ 95%), so new code can't land untested.

### Order and hand-off to the I/O plan

1. T0 (remove dead code), then T1 (tooling), then T2 (coverage
   fixtures), with T3 (unit tests) alongside.
2. T4 and T5 (correctness and properties): Claude drafts all cases;
   Austin, Jack and Piter verify them later.
3. T6 and T7 (CI and coverage gate).
4. **Then** start the I/O plan at Phase 1. Its round-trip acceptance test
   then runs over every T2 fixture, not just the original 7. Error tests
   come with I/O Phase 2.

The two plans meet in one place: I/O Phase 3 adds the full-precision
`results.csv`. Once that exists, T4/T5 comparisons switch from parsing
3-decimal `.out` text to the CSV, and their tolerances tighten.

---

## Part 4: Open items

- **Austin, Jack and Piter** verify the provisional T4/T5 cases, in
  batches, when convenient.
- **Jack and Piter** are asked for worked examples with known answers.

No questions block T0–T3.
