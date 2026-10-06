# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SelAction is a Fortran-based animal breeding selection index program that calculates genetic responses and inbreeding effects for various selection schemes. This repository holds the original reference code from Piter Bijma (`fortran_orig/`) plus one lightly-modified copy, `fortran/`, that compiles with a modern gfortran and carries every fix in `NEWS.md`. The source has nothing OS-specific: one tree builds on every platform.

History: `fortran/` was called `fortran_mac/` until 2026-10-05. It started on 2026-10-01 as a copy of `fortran_linux/`, an older compile-only fork that lacked the fixes; `fortran_linux/` was removed on 2026-10-05 (it is in git history). Older `NEWS.md` entries, implemented plans and `correspondence/` still use those names.

`fortran/` is **not** a "modernized 2.0" rewrite. Earlier drafts of this file described one (a `fortran/` with `seltools2.f90` etc.) that was never started; don't recreate that from memory. If a rewritten/modular version is wanted, it should be scoped as new work.

## Build Commands

### Build (`fortran/`)

`fortran/` builds **one binary, `selaction`** (since 2026-10-02: `mssel.f90` was renamed `selaction.f90`, and `msseld.f90`/`msselo.f90` were deleted as cut-down copies; originals remain in `fortran_orig/`). Build from the repository root with the top-level `Makefile`:

```bash
make          # -> build/selaction (plus build/*.mod, and build/selaction.dSYM on macOS)
make test     # build if needed, then golden fixtures + error cases (no R needed)
make check    # every test layer, one summary (needs R)
make strict   # strict debug build in build/strict + all tests (needs R)
make coverage # coverage build in build/coverage, line/branch table
make clean    # rm -rf build
```

All build output goes to `build/` (gitignored); `fortran/` stays source-only. Variables can be overridden: `FC` (default `gfortran`), `FFLAGS` (default `-g -O2 -Wall`), `BUILD` (default `build`), e.g. `make BUILD=build/strict FFLAGS="..."` for a side-by-side debug build. On Windows (`OS=Windows_NT`) the binary is `selaction.exe`. **When adding a module, add it to `SOURCES` in the Makefile in dependency order** (and to the fallback command in `README.md`). The Makefile must stay compatible with GNU Make 3.81 (macOS's version). Equivalent command without make, from the root:

```bash
mkdir -p build
gfortran -g -O2 -Wall -J build -o build/selaction fortran/seltools.f90 fortran/selparameters.f90 fortran/selroutines.f90 fortran/selovlp.f90 fortran/seldiscrete.f90 fortran/selaction.f90
```

The flags matter: without them, `blup1` flips `-0.000` to `0.000` for one near-zero weight (a floating-point effect, not a code change). `-Wall` prints ~1400 legacy warnings; they are expected. The banner (`intro` in `selroutines.f90`; printed on screen and at the top of every `.out`) reads "SelAction … version 1.2", with the original Rutten & Bijma (Wageningen, 2000) credit plus "updated by Austin Putz and Jack Dekkers, Iowa State University, 2026". Changing banner text changes every fixture `.out`. When regenerating them, first verify each new report is byte-identical below the banner. Verified with GNU Fortran 14.2.0 (the standalone installer in `/usr/local/gfortran/`, macOS x86_64; Homebrew's gfortran 16.2 also passes byte for byte): builds clean, passes all fixtures via `make test`. CI (`.github/workflows/tests.yml`, every push to `main` and every PR) also builds and tests on Linux (gfortran 14.3, byte-identical), macOS Apple Silicon (gfortran 14.2, and Homebrew's current gfortran as the README tells Mac users; both: `test1` and `blup1` differ in one last digit, so byte-exact is advisory there and the tolerant check is required) and Windows MSYS2 UCRT64 (gfortran 16.2, byte-identical apart from CRLF line endings). WSL is not tested. New fixes land here and are recorded in `NEWS.md`. Prebuilt downloads (GitHub Releases) are planned in `plans/releases.md`, not started.

### Original version (reference only, never modify)

```bash
cd fortran_orig/
# Original three programs, e.g.
#   gfortran -o mssel  seltools.f90 selparameters.f90 selroutines.f90 selinbreeding.f90 selovlp.f90 seldiscrete.f90 mssel.f90
#   (msseld: drop selovlp.f90; msselo: drop selinbreeding.f90 and seldiscrete.f90)
# None of the three programs builds
# with gfortran 14.2 (checked 2026-10-05 in a scratch copy): mssel/msseld hit
# the dFmtblup name clash, and all three fail on the undeclared `genint` in
# selovlp.f90. This directory is a byte-for-byte copy of Piter Bijma's
# original code and exists for comparison only.
```

The top-level `Makefile` is the only build system (no CMake/fpm). `fortran_orig/` is not covered by it.

**File order in these commands is not cosmetic.** `gfortran` compiles the files it's given left to right and needs each module's `.mod` file to already exist before compiling something that `USE`s it — so the main program (`selaction.f90`) must always be *last*, after every module it depends on, in the Module Dependencies order below. Earlier drafts of this file listed the main program first, which fails outright; the order above has been verified to build cleanly.

## Code Architecture

### Directory Structure

| Directory | Description | Status |
|-----------|-------------|--------|
| `fortran_orig/` | Original Fortran code from Piter Bijma | **Never modify — treat as read-only reference** |
| `fortran/` | The working code (version 1.2), one source tree for all platforms (formerly `fortran_mac/`) | Working — active development directory and the only build, see "Build" above |
| `build/` | Build output from `make` (binary, `.mod` files, `.dSYM`) | Gitignored, per machine; never commit binaries |
| `manual_orig/` | Original user manual and program description: the PDFs are the originals; the `.md`/`.html` files are transcriptions of them | **Never modify the PDFs.** The transcriptions are edited only by Austin |
| `docs/` | LaTeX technical reports on the underlying methods | Reference documentation |
| `examples/` | Sample input files and a worked GUI example | Reference/test fixtures |
| `tests/` | Canonical `.in`/`.out` regression fixtures + `run_tests.sh`, shared across all platform builds and the R port | Working |
| `plans/` | Design plans for major changes, each with a Status section | See "Plans and current status" below |
| `correspondence/` | Write-ups sent to collaborators; `2026-10-bijma-dekkers/` holds the open modelling questions sent to Piter Bijma and Jack Dekkers on 2026-10-05 | Reference |

### Module Dependencies (same in fortran_orig/ and fortran/)

```
seltools.f90 (base statistical functions)
    ↓
selparameters.f90 (global parameters, depends on seltools.f90)
    ↓
selroutines.f90 (mathematical routines, depends on both above)
    ↓
seldiscrete.f90, selovlp.f90 (depend on all above; fortran_orig/ also has selinbreeding.f90 here)
    ↓
Main programs (fortran: selaction.f90; fortran_orig: mssel.f90, msseld.f90, msselo.f90)
```

### Key Components

- `selaction.f90` (`fortran/` only) — the single main program; the former `mssel.f90`, all selection types
- `mssel.f90` (`fortran_orig/` only) — full version supporting all selection types
- `msseld.f90` (`fortran_orig/` only) — discrete generations only
- `msselo.f90` (`fortran_orig/` only) — overlapping generations only
- `seldiscrete.f90` — core discrete-generation selection calculations (`sel1s`, `sel2s`, `sel3s`)
- `selovlp.f90` — overlapping generation calculations
- `selinbreeding.f90` (`fortran_orig/` only) — `MODULE Inbreeding`, an unused duplicate of `dFmtblup` (never `USE`d; the live rate-of-inbreeding code is in `selroutines.f90`). Removed from `fortran/` on 2026-10-05 (test-hardening T0); don't bring it back
- `selparameters.f90` — global parameters and shared variables
- `selroutines.f90` — selection index, information-source input, covariance updates, matrix utilities (e.g. `invrt`, `trunc`), and the live `dFmtblup` (rate of inbreeding)
- `seltools.f90` — statistical/distribution functions (`gcef`, `sabf`, `sintvi`, `rawl3`, `dutt*`)

## Development Guidelines

### Working with Fortran Code

- Use gfortran with `-g -O2 -Wall` flags.
- Maintain module dependency order during compilation (see above).
- `fortran/` is **not** an independent rewrite of `fortran_orig/` — it's the same code with the minimum edits needed to satisfy a modern compiler, plus only the fixes recorded in `NEWS.md`.
- Keep one source tree. Don't create per-platform copies (`fortran_linux/`, `fortran_windows/`, ...); platform differences belong in build commands or CI, not in forked sources.
- **Never modify the original PDFs in `manual_orig/`** (`SelAction_Manual.pdf`, `SelAction_Program_Description.pdf`). The Markdown/HTML transcriptions next to them (`*.md`, `*_OCR.*`, `.css`, `build_html.sh`) are Austin's modern versions of those PDFs; leave them to him unless asked.
- **Never edit anything under `fortran_orig/`.** If a fix is needed, make it in `fortran/` and record it in `NEWS.md`.
- `fortran_orig/selinbreeding.f90` holds a second, dead copy of `dFmtblup` and its helpers (`create_C`, `Poissoncorr`, `hyper_correct`), with its own defects (see the technical report's known issues). **The live copy is the one in `selroutines.f90`**: `sel1s` gets it via `use selroutines`. Its unrestricted `USE selroutines` imports a second `dFmtblup`, which is why the original `mssel`/`msseld` don't build. `fortran/` worked around that with `USE selroutines, ONLY: trunc` until the file was deleted from `fortran/` (2026-10-05, test-hardening T0).

### Testing

- Canonical regression fixtures live in `tests/fixtures/` (not inside any platform directory), so `fortran/` and any eventual port (the R package, a C++ build) validate against the same `.in`/`.out` pairs instead of drifting copies. Run `make test`, or `tests/run_tests.sh [bin_dir]` (defaults to `build`; relative to the repository root or absolute); see `tests/README.md` for the fixture format, the manifest that maps fixtures to valid binaries, and — important if adding fixtures — the 8-character filename constraint imposed by `character (len=8) :: fnam` in `selparameters.f90`.
- Fixtures: `test1` (3-trait discrete 1-stage, ported from the original distribution's smoke test), `test2s` (discrete 2-stage, `sel2s`), `test3s` (discrete 3-stage, `sel3s`), `blup1` (discrete 1-stage isolating the BLUP-specific branch of the inbreeding calculation), `advgrp` (discrete 1-stage isolating the unconfigured/partially-configured group-type matrix-block guards, including a progeny-groups path no other fixture exercises), `ovlp2` (overlapping generations, 2-trait, 2-age-class-per-sex, own performance as the only info source), and `ovlpgrp` (overlapping generations, all three group types — full-sib/half-sib/progeny — configured and selected as info sources alongside own performance). Every fixture lists only `selaction` in the manifest. Overlapping generations (`ovlp` in `selovlp.f90`) previously had no fixture; the crash that made it unusable is fixed: `pheninfo` and `posgcorr` (both `allocatable` in `selparameters.f90`) were assigned to before being allocated — `pheninfo` was allocated ~150 lines later than its first use, and `posgcorr` wasn't allocated anywhere in this file at all (unlike its correctly-allocated counterpart in `seldiscrete.f90`). Both allocations were moved to immediately before first use, right after `ntraits`/`nclass` are read. This bug was inherited unchanged from `fortran_orig/selovlp.f90` (confirmed present there too, untouched, since `fortran_orig/` is never modified) and predates the Linux fork. Building the `ovlp2` fixture then surfaced a second, distinct bug in the same file: `ccprog` (progeny-test common-environmental effect) is only conditionally read (`initprog.eq."y" .and. initc.eq."y"`) but used unconditionally a few hundred lines later — same uninitialized-read shape as the group-array bug below, just in `selovlp.f90`. Fixed by zero-initializing `ccprog` alongside the group arrays. Building `ovlpgrp` then surfaced a third, unrelated uninitialized-read bug present in **four** subroutines (`info_sources`/`info_sourcesovlp`/`info_sources2`/`info_sources3`, all in `selroutines.f90`, so it affected discrete generations too, not just `ovlp`): a local `initblup` flag was read in a comparison on the very first call to each subroutine within a program run before ever being assigned, its value undefined until a BLUP (code 2) info source was actually seen. Fixed by explicitly initializing `initblup="n"` in all four. See `tests/README.md` for all three in full detail. `ovlpgrp` deliberately does **not** combine BLUP breeding values with a group as an info source — see the coverage-gap note below for why.
- `fsgroupsoff`/`hsgroupsoff`/`hsgroupsdams`/`proggroupsdams`/`proggroupsoffs`/`proggroupsoffd` (fixed `real, dimension(20)` in `selparameters.f90`) are only populated for the actually-configured number of groups, but `selection_index`/`intra_sd` in `selroutines.f90` unconditionally summed/indexed all 20 slots — a real uninitialized-read bug (confirmed via a `-finit-real=snan -ffpe-trap=...` debug build that segfaulted at `selroutines.f90:1539`), first fixed by zero-initializing all six arrays in `sel1s`/`sel2s`/`sel3s` (`seldiscrete.f90`) and `ovlp` (`selovlp.f90`) before use. That closed the uninitialized-read but left every division by those arrays running unconditionally even for unconfigured/partially-configured group types — mathematically undefined (`x/0.0` or `0.0/0.0`) and still trapped under strict FPE flags. Both subroutines now take `fsgroups`/`hsgroups`/`proggroups` as arguments (matching the existing `info_sources` pattern) and guard each division to only run when that specific group index is actually configured. See `tests/README.md` ("Resolved: unconfigured group-type matrix blocks") for the full detail, and its "Resolved: negative `sigmai`" section for a separate trap (`sqrt` of a negative `sigmai`) this fix exposed, since fixed.
- **`ovlp` truncation threshold search (fixed in `fortran/`)**: `riddr_root`'s bracket in `selovlp.f90` was ±1.5 SD (so ≥6.7% of young sires were always selected; `ovlpgrp` selected 67.5 sires instead of 10), and `trunc_delta`'s side-effect writes to `pvalcl`/`nselec` were left at the bracket midpoint on one exit path. Fixed with a wider bracket (now ±8 SD) and a re-evaluation at the root; later `sdutt1` was switched to the exact `erfc` tail and `trunc_delta`'s ±3 SD clamp (which forced ≥0.135% of every age class to be selected) removed; `ovlp2`/`ovlpgrp` expected outputs regenerated (and again after the generation-interval accumulation fix in `ovlp`). The earlier-reported "BLUP + group under `ovlp` collapses to zero" could not be reproduced before or after this fix. See `tests/README.md` and the open questions for the original authors in `NEWS.md`.
- **Triage rule for `ovlp`-specific findings in general**: a crash/FPE-trap/bounds-violation traceable to an uninitialized variable, a missing zero-init, or a division unguarded for an unconfigured case is a plain programming bug — fix it directly, same pattern as `ccprog`/`initblup`/the group-array guards below, no equation review needed. Numerically *plausible-but-wrong* output (a response, accuracy, or covariance term whose value looks off but doesn't crash) is different — treat it like the BLUP+group issue above: don't guess, document precisely what looks wrong and where, and get the original theory (Bijma/Dekkers, or the original manual/technical report) before touching the equations.
- **Test tools** (test-hardening T1): `make check` (`tests/run_all.sh`) runs build, tool self-test, golden, error cases and the strict build with one summary; `make strict` (`tests/tools/strict.sh`, build in `build/strict`) and `make coverage` (`tests/tools/coverage.sh [--min-lines N]`, needs GCC's `gcov`, not Apple's) run alone. `tests/tools/compare_out.R` (base R) compares `.out` files within one unit in the last printed digit; `tests/run_tests.sh --tolerant` uses it. `run_tests.sh` also fails any run that exits non-zero. `make test` needs no R; the R layers fail (not skip) without it.
- **Input map:** `tests/input_map/README.md` lists every input question, its condition, and which fixture reaches it (raw table `reads.csv`, regenerate with `tests/tools/read_map.sh`). It is the spec for the I/O plan's translator; update it when adding fixtures or changing input code.
- **Error cases** live in `tests/errors/` (manifest: name, exit code, `none`/`report` files, expected message) and run with `tests/run_error_tests.sh [bin_dir]`, also part of `make test`. File and trait names go through `read_name` in `selroutines.f90`, which stops with `-error-30-` and `error stop 2` on names longer than 8 characters, empty, or with a space or comma; `check_trait_unique` stops on duplicate trait names (ignoring case). Don't reintroduce plain `read *` for names: list-directed reads silently cut them.
- `tests/README.md` also documents why `blup1.out` was regenerated: its BLUP index weight for a non-breeding-goal trait is genuinely near zero after 25 rounds of iterative equilibrium, right at the display-rounding boundary — sensitive to compiler-version-level floating-point differences, not a functional bug. The reference toolchain is recorded there.
- `make`, `make test`, `make check`, `make strict`, `make coverage`, `make clean` and `make help` exist (top-level `Makefile`). `make docs` does not; the LaTeX reports are built with `latexmk` directly.
- **CI** (`.github/workflows/tests.yml`, test-hardening T6): Linux and macOS run build, self-test, golden (byte-exact and tolerant), error cases, strict; Linux also prints coverage; Windows (MSYS2) runs build, golden, error cases. The README's tests badge reflects it. Keep CI green: a change that turns it red isn't done. Never regenerate a stored `.out` to suit a CI platform.
- The reference toolchain for byte-exact fixtures is macOS x86_64, GNU Fortran 14.2.0, `-g -O2 -Wall` via `make` (all `.out` files were regenerated there for the version 1.2 banner; building into `build/` from the root gives byte-identical output).

## Plans and current status

- **Order (agreed 2026-10-05):** `plans/implementation-sequence.md` is the single numbered list of steps from both plans below, with dependencies and status; update its status column when a step is done, and add a summary of the finished step to `plans/progress.md` (template inside; also update its "Current position" section). `plans/progress.md` is where Austin checks where things stand. In short: test-hardening T0–T2 (+ T6 CI if wanted) → I/O Phases 1–3 → test-hardening T3–T5, T7 (alongside I/O Phases 4–5) → model changes from Jack/Piter's answers → R port.
- `plans/test-hardening.md` — **approved (rev 3), in progress.** T0 delete `selinbreeding.f90` from `fortran/` (done 2026-10-05); T1 tooling (done 2026-10-05: `make check`/`strict`/`coverage`); T2 coverage fixtures; T3 unit tests; T4/T5 correctness and property tests (drafted by Claude, *provisional* until verified by Austin/Jack/Piter); T6/T7 CI and coverage gate.
- `plans/modernize-inputs-and-outputs.md` — **approved (rev 12), starts after test-hardening T0–T2.** Long trait names are handled by driver-generated short labels, not by widening the Fortran. R driver reading YAML scenario folders → legacy answer stream → `selaction --batch`; Fortran writes `results.csv`; no equation changes.
- `plans/releases.md` — **not started; after test-hardening T6.** Tested prebuilt binaries (macOS Intel/Apple Silicon, Linux, Windows) on GitHub Releases, so non-programmers (e.g. Jack) can run SelAction without compiling.
- `plans/document.md` — docs-site idea, not started; written before the code was consolidated into `fortran/`, so its "current state" is out of date.
- The other files in `plans/` are implemented fixes kept for their reasoning.
- Open modelling questions (genetic lag between age classes, family-structure correction under `ovlp`, the 0.93 stage-correlation cap and r13|2, half-sib sources when `nsires == ndams`, the 20-sire inbreeding switch) were sent to Piter Bijma and Jack Dekkers on 2026-10-05 (`correspondence/2026-10-bijma-dekkers/`). Don't change the model on these points until they answer.

## Common Issues

- **Module not found errors**: build with `make`; by hand, keep the compilation order (see Module Dependencies above).
- **Long line errors**: add `-ffixed-line-length-none` when compiling `fortran_orig/` directly.
- **Singular matrix errors**: check genetic parameter consistency in input data (correlation matrices must be positive definite).

## Related Project

A separate R package, `SelActionR`, reimplements this program's selection index theory for a modern scriptable interface (targeting CRAN). It lives in its own repository, not this one. This repository is its validation reference — R outputs should be checked against the fixtures in `tests/fixtures/` (see `tests/README.md`) and the `examples/` outputs.

## Documentation Resources

- `manual_orig/SelAction_Manual.pdf` (transcribed in `SelAction_Manual.md`) — a step-by-step guide to the original **Windows GUI** version of SelAction (click-through windows for traits, population, groups, index and correlations). That GUI was written in Borland Delphi for Windows 95/98/NT (stated in the Program Description). It is **not** in this repository and the manual does **not** describe how to run the Fortran code here; use it for what the inputs mean, not for how to enter them.
- `manual_orig/SelAction_Program_Description.pdf` (transcribed in `SelAction_Program_Description.md`) — a short description of what SelAction does and how it works: the selection-index, Bulmer-effect, multistage and inbreeding methods behind the predictions. It applies to this Fortran code as well, but `docs/SelAction_Technical_Report.pdf` is the reference for the equations as actually implemented.
- `docs/SelAction_Technical_Report.pdf` and the per-module reports in `docs/` — detailed derivations
- `README_Inputs.md` — field-by-field input file mapping guide
