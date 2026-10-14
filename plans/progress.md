# Progress log

Where we are in [`implementation-sequence.md`](implementation-sequence.md).
**A short summary is added here after every step (or sub-step) is
finished, newest first.** Read the top entry to see where things stand.

## Current position

- **Last finished:** step 4c, T2c: 18 more test inputs, 45 in all;
  every input question reached, 95.1% of lines (2026-10-14), see the log.
  Test-hardening T2 is complete.
- **Next:** step 5a, I/O Phase 1a: `driver/spec.yaml`, the translator and
  importer for 1-stage discrete selection.
- **Review later (Austin asked to be reminded):**
  - **When Q6 is answered:** review `matrat1`, `matrat1y`, `matrat2`,
    `matrat3` with Austin. They record today's rule: with sires = dams,
    half-sib information is removed in the last stage only, and where it
    stays alongside BLUP the sources are exactly collinear (step 4c
    findings). Regenerate them, with before/after results, if the model
    changes.
  - When Q7 is answered: `sires19`, `sires20`. When Q2/Q4 are answered:
    `ovlp3ac`.
- **Waiting on others:** answers from Piter Bijma and Jack Dekkers to the
  open modelling questions (Q1–Q7, **sent 2026-10-05**), and any worked
  examples (`correspondence/2026-10-bijma-dekkers/`).
- **To send:** the two-page addendum
  (`correspondence/2026-10-bijma-dekkers-addendum/`): Question 8 and an
  addition to Question 6. Austin decides when to send it.

## Entry template

```markdown
### Step <#>: <name> (done YYYY-MM-DD, commit <hash>)

- **What changed:** files and behaviour, in plain words.
- **Tests:** what was run and the result (e.g. `make test`: 7/7 golden,
  6/6 error cases; strict build clean).
- **Results changed?** No / Yes: which outputs, and why.
- **Findings:** anything surprising, or anything that needs Austin, Jack
  or Piter.
- **Next:** the next step number and name.
```

---

## Log

### Step 4c: T2c, overlapping-generation inputs and 95% coverage (done 2026-10-14, commits `28f1fe0`, `fff9bf2`, `1640e0c`, `360e1d5` + docs)

- **What changed:**
  - 18 new test inputs with stored reports, 45 in all. Overlapping
    generations: fixed numbers per age class with one class left out
    (`ovlpfix`), 3 age classes (`ovlp3ac`), BLUP with a half-sib group
    (`ovlpblup`), the no-phenotypic-information warning (`ovlpwarn`),
    one trait (`ovlp1t`). Discrete: sires = dams with separate indices
    and in 2-/3-stage selection (`matrat1y`, `matrat2`, `matrat3`), every
    source type in the printed indices (`sxdsrc1`–`sxdsrc3`, `sxdsrc2b`,
    `sxdsrc3b`), `noce2s`, `onetrt3s`, and the remaining answers to the
    warning (`nophen1d`, `nophen2s`, `nophen3d`).
  - **Two program fixes** (approved by Austin, each in its own commit):
    `28f1fe0`, an age class with 0 selected divided 0 by 0 when the
    covariances were set up (never used, so no result changed, but the
    strict build stopped there); and `fff9bf2`, BLUP under overlapping
    generations read a value before it was set (see Findings). Both in
    `selovlp.f90`, both inherited from the original code.
- **Tests:** `make check` passes: 45/45 golden, 8/8 error cases, strict
  build clean. Every new input was rerun from the program's own echo and
  gave the identical report, and was checked on the strict build. Linux
  (Docker, gfortran 14): 45/45 byte-identical, valgrind clean on all 53
  runs (after the second fix below). CI green on all four jobs; on Apple
  Silicon 14 of 45 reports differ in a last digit (9 of them new) and
  pass the tolerant check required there.
- **Coverage:** lines 90.0% → **95.1%** (target met), branches 60.6% →
  63.2%. The input map shows all 162 input questions reached. The
  test-hardening plan's coverage gate (step 14, T7) is set to 95%. What
  still never runs: "wrong input, ask again" paths (step 6 tests them as
  errors), error stops, and corners of the normal-integral maths (step 9).
- **Results changed?** No: the 27 existing reports are byte-identical,
  with and without the fix.
- **Findings:**
  - **For the Q6 review (on the "Review later" list above).** With
    sires = dams, half-sib sources are removed only in the last stage, so
    `matrat2` (stage 1) and `matrat3` (stage 2) keep them. In a stage that
    keeps them together with BLUP, each "mean EBV of the half-sib dams"
    weight was exactly −½ times the half-sib weight: the two sources are
    collinear, the matrix being inverted is singular or nearly so, and
    the weights differed between builds (−15.505 vs −15.508). The stored
    `matrat3` keeps BLUP out of that stage so the test is stable; the
    collinear version is described here for Jack and Piter. It supports
    the letter's proposal to apply the rule at every stage.
  - **Fail loudly (for step 6).** Asking for more animals than there are
    candidates under overlapping generations stops with `-error-20-` and
    **exit code 0**; the "requested number cannot be met" warning written
    for that case is never reached. A stage that adds no information to
    an index stops with `-error-10-` (singular matrix), also exit 0. Step
    6 should reject the first up front and give both a non-zero exit code.
  - **Echo bug (for step 5).** With one trait and separate indices, the
    echo `.in` contains a "use for dams" answer the program never asked;
    replaying it works only because the next question asks again. The
    translator must not produce that line.
  - **A second bug, found by CI (fixed with Austin's approval, commit
    `fff9bf2`).** On Linux and Windows `ovlpblup` selected 0 sires and 0
    dams; valgrind flagged it and `ovlpwarn`. With BLUP as a source under
    overlapping generations, a value (`ocovipi`) was read before it was
    set, because it was filled inside the loop that reads it. On a Mac
    the memory happened to be 0, which gives the right answer, so it never
    showed there. **This was the old "BLUP + groups collapses to zero"
    report.** Inherited from the original code. Fixed by filling the
    value first (no equation change): every report is byte-identical on
    the Mac, Linux now matches, and valgrind is clean. I ran CI on a side
    branch first, so `main` never went red.
  - My coverage estimate was a little high: the planned 12 inputs reached
    94.93%; with your approval, 6 more small inputs brought it to 95.06%.
  - Nothing new for Jack or Piter beyond the Q6 point above.
- **Next:** step 5a, I/O Phase 1a.

### Step 4b: T2b, new discrete-generation test inputs (done 2026-10-09, commits `5d65e12`, `0966058`, `393377c`, `5517a5e` + docs)

- **What changed:** 20 new test inputs with stored reports, 27 in all.
  No program changes.
  - 1-stage variants: no common environment (`noce1`), a goal-only trait
    (`goalonly`), one trait (`onetrait`), five traits (`fivetr`), two
    groups of each type (`multigrp`), sires = dams (`matrat1`), and 19
    vs 20 sires (`sires19`, `sires20`)
  - separate indices for sires and dams in 1, 2 and 3 stages (`sxd1`–`sxd3`)
  - groups and progeny in 2- and 3-stage selection (`prog2s`, `prog3s`),
    one trait in 2-stage selection (`onetrt2s`)
  - the "no phenotypic information" warning, answered every possible way,
    in each stage (`nophen1`–`nophen3`, `nophen1n`–`nophen3n`)
- **Tests:** `make check` passes: 27/27 golden, 8/8 error cases, strict
  build clean. Linux (Docker, gfortran 14): 27/27 byte-identical, valgrind
  clean on all 35 runs. Every new input was run a second time from the
  program's own echo of the answers and gave the identical report. CI
  green on all four jobs; on Apple Silicon 3 new reports (`noce1`,
  `nophen2n`, `nophen3n`) differ in a last digit, like `test1`/`blup1`,
  and pass the tolerant check that is required there.
- **Coverage:** lines 79.0% → 90.0%, branches 55.7% → 60.6%. The input map
  now shows 159 of 162 questions reached; the 3 left are the
  overlapping-generation questions for step 4c. Every routine runs except
  `srec_dutt`, a corner of the normal-integral maths (a stage that selects
  almost everyone); that belongs in the unit tests (step 9), not an input.
- **Results changed?** No: the 7 existing reports are byte-identical.
- **Findings:**
  - **Question 7 example confirmed.** `sires19`/`sires20` reproduce the
    letter's 4.590% and 4.682% exactly, but only with the half-sib
    group left at 200 dams (as in `test1`) while the population has 50
    dams. That is how the letter's figure was made; the fixtures pin it.
    Worth knowing when Jack and Piter answer.
  - **A check of the 2- and 3-stage code.** `prog2s` and `prog3s` select
    the same overall proportions with the same final index, and give the
    same final results; `prog3s` after stage 2 matches `prog2s` after
    stage 1 to within 0.002. That's what the theory predicts, so it is a
    good sign for the multistage code.
  - **Input check (no code changed):** the stage-2/3 trait questions don't
    ask again on an invalid answer; they skip the trait silently. Noted in
    the input map for the batch-mode input checks (step 6).
  - **Name too long:** the planned `onetrait2` is 9 characters, and the
    program stopped with `-error-30-` as it should. It is `onetrt2s`.
  - **Step 4c's 95% target:** the discrete code is at 89% of lines after
    this step, and two overlapping-generation inputs won't lift it. At
    step 4c I will list what is still not run and propose how to reach
    95% (or a realistic target) before building anything.
  - Nothing new for Jack or Piter.
- **Next:** step 4c, T2c: `ovlpfix`, `ovlp3ac`, coverage check.

### Fix: the intermittent Linux `ovlp2` failure (done 2026-10-09)

- **What was wrong:** with common environmental effects switched off,
  the program never set the correlations between traits for the common
  environment, but still used them (multiplied by zero). Usually 0 × junk
  = 0, but if the junk left in memory is "not a number", the result is
  "not a number" too. On Linux that once made `ovlp2` select 0 sires
  instead of 10. Same pattern in 1-, 2- and 3-stage selection; inherited
  from the original code.
- **How it was found:** valgrind in an Ubuntu container (Docker on
  Austin's Mac), which reports every use of a value that was never set.
- **Fix:** set those correlations to 0 right after the array is created,
  in all four routines (the same kind of fix as `ccprog` earlier). A
  plain programming bug, no equation involved.
- **Tests:** all 7 stored outputs byte-identical; every fixture and error
  case clean under valgrind (before: 38,883 reports for `ovlp2`, 20,266
  for a 1-stage run with common environment off). New `make memcheck`
  runs every test under valgrind; CI now runs it on Linux, and it fails
  on the old code.
- **Results changed?** No (the stored outputs were made where the junk
  happened to be harmless).
- **Findings:** nothing for Jack or Piter.
- **Next:** step 4b, T2b.

### Review of steps 1–4a (2026-10-09, commits `72b91d1`, `4739da0`, `3f066f2`)

Three read-only reviews (Fortran input checks; test scripts and CI; dead
files and docs), then fixes approved by Austin.

- **Found and still open: an intermittent wrong result on Linux.** CI on
  `main` went red at `7dc28f5` (a docs-only commit): one Linux run of
  `ovlp2` selected 0 sires instead of 10, and still exited 0; a second
  run of the same binary in the same job was correct. Never seen on a
  Mac. Most likely a value read before it is set, which the strict
  build can't see for allocated arrays. Next: run it under valgrind in a
  Linux container (Docker) and fix it as a plain programming bug. I
  missed the red run at the time because I didn't watch CI after that
  push; I now watch every run.
- **Fixed in the name checks:** blank lines before a name are skipped
  again; leftover quotes and `/` or `\` in file names stop the run; long
  lines are reported correctly. Two new error cases (8 in all).
- **Fixed in the test tools** (none of these had let a real failure
  through yet, but each could have):
  - a numbers comparison that let `12.345` vs `12.3` pass
  - test inputs not listed in a manifest were ignored; an empty
    manifest "passed"; a missing last newline skipped a test
  - a non-executable test script showed as "not yet present"
  - strict and coverage runs could test a stale normal build
  - on macOS, failed test folders weren't kept where CI uploads them
  - the program was fed the very file it overwrites with its answer
    echo (`<filename>.in`); now it reads a copy
- **CI:** pushes to `main` are never cancelled (so every commit gets a
  result), 30-minute limit, read-only token, failure folders uploaded on
  every platform.
- **Deleted (approved):** the Gemini review and three one-page module
  reports in `docs/` (stale, one wrong), `examples/input_selaction.txt`
  (not a valid input), the unused ChatGPT logo, `plans/document.md`. The
  multi-binary logic in `run_tests.sh` is gone; the fixture manifest is
  `name:description`.
- **Docs corrected:** README, CLAUDE.md, tests/README, NEWS, the plans,
  and `README_Inputs.md` (its line mapping of the GUI file was wrong).
  The program **writes** `<filename>.in` (an echo of the answers); the
  docs said it read it.
- **Tests:** `make check` passes; all 7 fixtures byte-identical; 8/8
  error cases; tolerant self-test 12/12; CI green on all four jobs after
  the fixes (the Linux bug is intermittent, so green doesn't clear it).
- **Results changed?** No.
- **Next:** debug the Linux failure, then step 4b.

### Step 4a: T2a, the input map (done 2026-10-06, commit `740a02e`)

- **What changed:** new `tests/input_map/README.md`: every question
  SelAction asks (162 input statements), in the order it asks them, when
  each is asked, what answers it accepts, and which test input reaches
  it. `reads.csv` is the raw table, made by the new
  `tests/tools/read_map.sh`. This is also the specification for the
  YAML translator in step 5. No program changes.
- **Tests:** `read_map.sh` gives an identical table on a second run;
  every input line appears in the README; spot-checks agree with the
  test inputs. `make check` passes.
- **Coverage of questions:** 124 of 162 are reached today. The 38 that
  aren't: separate sire/dam indices (none of the tests use them),
  goal-only traits, groups in 2-stage and progeny groups in 2-/3-stage
  selection, fixed numbers per age class, and the warning for a trait
  with no phenotypic information (with its corrections).
- **Results changed?** No.
- **Changes to the planned test inputs (step 4b/4c):**
  - `nophen` becomes six small inputs (`nophen1`–`3`, `nophen1n`–`3n`):
    each stage has its own copy of the correction code, with five
    different questions.
  - new `onetrait2`: one trait skips the trait-use questions in every
    stage, a separate input path in 2-stage selection.
  - `prog2s` also uses full-sib and half-sib groups; `prog2s`/`prog3s`
    and `sxd2`/`sxd3` add a trait in a later stage; `ovlpfix` includes a
    goal-only trait.
- **Findings** (written up in the map, nothing changed):
  - **For Jack/Piter (an input check, not an equation):** the progeny-test
    c² must be above 0, while the ordinary c² may be 0. So a user can't
    say "no common environment in the progeny test". Is 0 meant to be
    allowed?
  - The correction "new genetic correlation" only offers one pair and
    doesn't recheck the value; the I/O plan's validator will check this
    before running. Not a question for Jack/Piter (no theory involved).
  - Overlapping generations skip the half-sib question when sires >=
    dams; discrete generations ask it. The translator must copy that.
  - The first and last are written up for Jack and Piter as Question 8
    and an addition to Question 6 in
    `correspondence/2026-10-bijma-dekkers-addendum/` (not yet sent).
- **Next:** step 4b, T2b: new discrete-generation test inputs.

### Step 3: T6, automated tests on GitHub Actions (done 2026-10-06, commits `5065ecf`–`1283119`)

- **What changed:** new `.github/workflows/tests.yml`. Every push to
  `main` and every pull request is built and tested on Linux, macOS
  Apple Silicon (Jack's kind of Mac) and Windows. Results:
  [Actions tab](https://github.com/austin-putz/SelAction/actions/workflows/tests.yml);
  a tests badge is at the top of the README. No program changes.
- **Tests:** green on all three. Linux and Mac run every layer of
  `make check` plus (Linux) the coverage table; Windows runs build,
  golden and error cases (no R there). A throwaway branch with one digit
  changed in a stored report turned all three red; the branch was
  deleted.
- **Results changed?** No stored output changed.
- **Findings:**
  - **First results on other computers.** Linux (gfortran 14.3) and
    Windows (gfortran 16.2) give exactly the same reports as your Mac.
    Apple Silicon gives the same numbers except the last printed digit
    in two places (`33.378` vs `33.379` in `test1`; `57.377` vs `57.376`
    and `-0.000` vs `0.000` in `blup1`). That's rounding, not a
    difference in results; the tolerant check is the required one there.
  - The README's Windows instructions (MSYS2) work as written.
  - Added afterwards: a second Apple Silicon job that installs gfortran
    the README way (`brew install gcc`, gfortran 16.2). Same result as
    gfortran 14 there, so the README route for Mac users, including
    Jack's M-series MacBook, is tested on every push.
  - Three small fixes were needed to get CI green: Ubuntu's `gcov` name,
    `diff` missing in MSYS2, and Windows CRLF line endings.
  - Nothing for Jack or Piter.
- **Next:** step 4a, T2a: the input map.

### Step 2: T1, test tooling (done 2026-10-05, commits `9bf98e0`, `60326e7`)

- **What changed:** new test scripts, no program changes.
  - `make check` runs every test layer and prints one summary.
  - `make strict` runs all tests on the strict debug build (it was only
    ever run by hand before).
  - `make coverage` shows which share of the code the tests reach.
  - `compare_out.R` compares reports allowing a last-digit difference,
    for the strict build, other computers and later the R version.
  - `run_tests.sh` now also fails a run that crashes or exits with an
    error after writing a full report.
- **Tests:** `make check` passes: build, tool self-test (9/9), golden
  7/7, error cases 6/6, strict 7/7 + 6/6. Breakage is caught: one changed
  digit in a stored report fails the golden layer and the tolerant
  comparison; a divide-by-zero slipped into the code fails the strict
  layer (exit 136 on every fixture); a syntax error fails the build
  layer. All test edits were reverted.
- **Coverage today:** 79.0% of lines, 55.7% of branches (table in
  `tests/README.md`). Same as the hand measurement in the plan; step 4
  (T2) adds test inputs to close the gaps.
- **Results changed?** No.
- **Findings:**
  - The notes said the reference compiler was Homebrew's. It is actually
    the standalone GNU Fortran 14.2.0 in `/usr/local/gfortran`. Corrected.
  - Good news for users: Homebrew's current gfortran (16.2.0, what
    `brew install gcc` gives today) produces byte-identical results on
    all 7 fixtures.
  - Nothing for Jack or Piter.
- **Next:** step 3 (T6, CI) if wanted now, otherwise step 4a (T2a).

### Step 1: T0, delete the dead `selinbreeding.f90` (done 2026-10-05, commit `c5ddae1`)

- **What changed:** `fortran/selinbreeding.f90` (an unused older copy of
  the inbreeding routine) is deleted and no longer compiled. The live
  inbreeding code in `selroutines.f90` is untouched. `Makefile`, README,
  CLAUDE.md, the technical report (PDF rebuilt), the test-hardening plan
  and `NEWS.md` updated. The original stays in `fortran_orig/`.
- **Tests:** `make test`: 7/7 golden byte-identical, 6/6 error cases.
  Strict debug build: 6/7 identical, `blup1` differs only by the known
  `-0.000`; 6/6 error cases. The build-by-hand command without `make`
  also passes 7/7.
- **Results changed?** No.
- **Findings:** the `blup1` fixture description said it tested the
  inbreeding code in `selinbreeding.f90`; it actually tests the live
  copy in `selroutines.f90`. Description corrected. Nothing for Jack or
  Piter.
- **Next:** step 2, T1: test tooling.

### Groundwork before step 1 (done 2026-10-05)

- **What changed:**
  - **One source tree** (`1df843a`): `fortran_mac/` was renamed
    `fortran/`, and the old, unfixed `fortran_linux/` was removed.
  - **Build with `make`** (`49e01e4`): output goes to `build/`, and
    `make test` runs the tests.
  - **Bad names stop the run** (`5e98c91`): a file or trait name over 8
    characters, with a space, or (for traits) a duplicate now stops with
    `-error-30-` and exit code 2, instead of being silently cut.
  - **Planning:**
    - the two plans were reordered (`f4fe0ef`)
    - this sequence was written (`e4fa6a0`)
    - long trait names will be handled by the R driver's short labels
      (I/O plan revision 12, `adfdf1a`)
- **Tests:** `make test` passes 7/7 golden fixtures byte-identical and
  6/6 error cases. The strict debug build is clean, apart from the known
  `blup1` `-0.000`.
- **Results changed?** No.
- **Findings:**
  - The 8-character name cut could silently overwrite another run's
    output. It is now fixed.
  - Widening trait names in the Fortran would touch about 340 report
    lines, which is why the driver will handle long names instead.
- **Next:** step 1, T0.
