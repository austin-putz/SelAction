# Progress log

Where we are in [`implementation-sequence.md`](implementation-sequence.md).
**A short summary is added here after every step (or sub-step) is
finished, newest first.** Read the top entry to see where things stand.

## Current position

- **Last finished:** step 3, T6: automated tests on GitHub Actions.
- **Next:** step 4a, T2a: the branch map (every place the program reads
  input, and which test covers it).
- **Waiting on others:** answers from Piter Bijma and Jack Dekkers to the
  open modelling questions, and any worked examples
  (`correspondence/2026-10-bijma-dekkers/`).

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

### Step 3: T6, automated tests on GitHub Actions (done 2026-10-06)

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
  - Three small fixes were needed to get CI green: Ubuntu's `gcov` name,
    `diff` missing in MSYS2, and Windows CRLF line endings.
  - Nothing for Jack or Piter.
- **Next:** step 4a, T2a: the branch map.

### Step 2: T1, test tooling (done 2026-10-05, commit "Step 2 (T1): test tooling")

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

### Step 1: T0, delete the dead `selinbreeding.f90` (done 2026-10-05, commit "Step 1 (T0): remove dead selinbreeding.f90 from fortran/")

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
