# Progress log

Where we are in [`implementation-sequence.md`](implementation-sequence.md).
**A short summary is added here after every step (or sub-step) is
finished, newest first.** Read the top entry to see where things stand.

## Current position

- **Last finished:** review of steps 1–4a (2026-10-09), see the log.
- **Open, before step 4b:** the intermittent `ovlp2` failure on Linux
  (below). Needs Docker Desktop running on Austin's Mac to debug.
- **Next:** step 4b, T2b: new discrete-generation test inputs.
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
