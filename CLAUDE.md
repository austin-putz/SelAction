# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SelAction is a Fortran-based animal breeding selection index program that calculates genetic responses and inbreeding effects for various selection schemes. This repository holds the original reference code from Peter Bijma plus a lightly-modified fork that makes it compile with a modern gfortran on Linux. A macOS fork (`fortran_mac/`) was started fresh from `fortran_linux/` on 2026-10-01; see "macOS" below.

There is no "modernized 2.0" codebase in this repository — earlier drafts of this file described one (`fortran/` with `seltools2.f90` etc.), but that work was never started and the placeholder directory has been dropped. Don't recreate that section from memory; if a rewritten/modular version is wanted, it should be scoped as new work, not assumed to exist.

## Build Commands

### Linux (recommended, known working)

```bash
cd fortran_linux/

# Full version
gfortran -o mssel seltools.f90 selparameters.f90 selroutines.f90 selinbreeding.f90 selovlp.f90 seldiscrete.f90 mssel.f90

# Discrete generations only
gfortran -o msseld seltools.f90 selparameters.f90 selroutines.f90 selinbreeding.f90 seldiscrete.f90 msseld.f90

# Overlapping generations only
gfortran -o msselo seltools.f90 selparameters.f90 selroutines.f90 selovlp.f90 msselo.f90
```

### macOS

`fortran_mac/` is a copy of `fortran_linux/` (taken 2026-10-01) and builds with the same three commands and file order, from inside `fortran_mac/`. Verified with GNU Fortran 14.2.0 (Homebrew `gcc`, x86_64): builds clean, passes all fixtures via `tests/run_tests.sh fortran_mac`. No macOS-specific source edits were needed. It is now the active development directory: new fixes land here first and are recorded in `NEWS.md`; `fortran_linux/` is not automatically kept in sync, so check `NEWS.md` for fixes it is missing. macOS builds also emit `*.dSYM` debug-symbol bundles (gitignored).

### Original version (reference only, never modify)

```bash
cd fortran_orig/
# Same compilation commands as Linux, but may need -ffixed-line-length-none
# or fail outright on modern gfortran. This directory is a byte-for-byte
# copy of Peter Bijma's original code and exists for comparison only.
```

There is no top-level Makefile in this repository. Each platform directory is compiled directly with the `gfortran` invocations above.

**File order in these commands is not cosmetic.** `gfortran` compiles the files it's given left to right and needs each module's `.mod` file to already exist before compiling something that `USE`s it — so the main program (`mssel.f90` etc.) must always be *last*, after every module it depends on, in the Module Dependencies order below. Earlier drafts of this file listed the main program first, which fails outright; the order above has been verified to build cleanly.

## Code Architecture

### Directory Structure

| Directory | Description | Status |
|-----------|-------------|--------|
| `fortran_orig/` | Original Fortran code from Peter Bijma | **Never modify — treat as read-only reference** |
| `fortran_linux/` | Linux-compatible fork | Working, recommended |
| `fortran_mac/` | macOS fork of `fortran_linux/` | Working — active development directory, see "macOS" above |
| `manual/` | User manual + program description (Markdown + PDF) | Reference documentation |
| `docs/` | LaTeX technical reports on the underlying methods | Reference documentation |
| `examples/` | Sample input files and a worked GUI example | Reference/test fixtures |
| `tests/` | Canonical `.in`/`.out` regression fixtures + `run_tests.sh`, shared across all platform builds and the R port | Working |

### Module Dependencies (same in fortran_orig/fortran_linux/fortran_mac)

```
seltools.f90 (base statistical functions)
    ↓
selparameters.f90 (global parameters, depends on seltools.f90)
    ↓
selroutines.f90 (mathematical routines, depends on both above)
    ↓
seldiscrete.f90, selovlp.f90, selinbreeding.f90 (depend on all above)
    ↓
Main programs (mssel.f90, msseld.f90, msselo.f90)
```

### Key Components

- `mssel.f90` — full version supporting all selection types
- `msseld.f90` — discrete generations only
- `msselo.f90` — overlapping generations only
- `seldiscrete.f90` — core discrete-generation selection calculations (`sel1s`, `sel2s`, `sel3s`)
- `selovlp.f90` — overlapping generation calculations
- `selinbreeding.f90` — BLUP-based inbreeding calculations
- `selparameters.f90` — global parameters and shared variables
- `selroutines.f90` — matrix operations and mathematical utilities (e.g. `invrt`, `trunc`)
- `seltools.f90` — statistical/distribution functions (`gcef`, `sabf`, `sintvi`, `rawl3`, `dutt*`)

## Development Guidelines

### Working with Fortran Code

- Use gfortran with `-g -O2 -Wall` flags.
- Maintain module dependency order during compilation (see above).
- `fortran_linux/` is **not** an independent rewrite of `fortran_orig/` — it's the same code with the minimum edits needed to satisfy a modern compiler. `fortran_mac/` follows the same approach: a copy of `fortran_linux/` plus only the fixes recorded in `NEWS.md`.
- **Never edit anything under `fortran_orig/`.** If a fix is needed, make it in `fortran_mac/` (the active directory) and record it in `NEWS.md`.
- `fortran_linux/selinbreeding.f90` restricts its `USE selroutines` to `USE selroutines, ONLY: trunc`. Both `selroutines.f90` and `selinbreeding.f90` (in `fortran_orig/` too) contain a full copy of `dFmtblup` and its helpers (`create_C`, `Poissoncorr`, `hyper_correct`). **The live copy is the one in `selroutines.f90`**: `sel1s` gets it via `use selroutines`, and `MODULE Inbreeding` in `selinbreeding.f90` is never `USE`d anywhere — it is compiled into `mssel`/`msseld` but dead (and has its own defects, see the technical report's known issues). A blanket `USE selroutines` inside `selinbreeding.f90` would import a second `dFmtblup` and collide with that module's own definition, so the `ONLY: trunc` restriction is what lets the dead module compile; it has no effect on numerics.

### Testing

- Canonical regression fixtures live in `tests/fixtures/` (not inside any platform directory), so `fortran_linux`, `fortran_mac`, a future `fortran_windows`, and an eventual C++ port all validate against the same `.in`/`.out` pairs instead of drifting copies. Run `tests/run_tests.sh [platform_dir]` (defaults to `fortran_linux`); see `tests/README.md` for the fixture format, the manifest that maps fixtures to valid binaries, and — important if adding fixtures — the 8-character filename constraint imposed by `character (len=8) :: fnam` in `selparameters.f90`.
- Fixtures: `test1` (3-trait discrete 1-stage, ported from the original distribution's smoke test), `test2s` (discrete 2-stage, `sel2s`), `test3s` (discrete 3-stage, `sel3s`), `blup1` (discrete 1-stage isolating the BLUP-specific branch of the inbreeding calculation), `advgrp` (discrete 1-stage isolating the unconfigured/partially-configured group-type matrix-block guards, including a progeny-groups path no other fixture exercises), `ovlp2` (overlapping generations, 2-trait, 2-age-class-per-sex, `msselo` only, own performance as the only info source), and `ovlpgrp` (overlapping generations, all three group types — full-sib/half-sib/progeny — configured and selected as info sources alongside own performance). The first five validate against both `mssel` and `msseld`. Overlapping generations (`ovlp` in `selovlp.f90`) previously had no fixture; the crash that made it unusable is fixed: `pheninfo` and `posgcorr` (both `allocatable` in `selparameters.f90`) were assigned to before being allocated — `pheninfo` was allocated ~150 lines later than its first use, and `posgcorr` wasn't allocated anywhere in this file at all (unlike its correctly-allocated counterpart in `seldiscrete.f90`). Both allocations were moved to immediately before first use, right after `ntraits`/`nclass` are read. This bug was inherited unchanged from `fortran_orig/selovlp.f90` (confirmed present there too, untouched, since `fortran_orig/` is never modified) and predates the Linux fork. Building the `ovlp2` fixture then surfaced a second, distinct bug in the same file: `ccprog` (progeny-test common-environmental effect) is only conditionally read (`initprog.eq."y" .and. initc.eq."y"`) but used unconditionally a few hundred lines later — same uninitialized-read shape as the group-array bug below, just in `selovlp.f90`. Fixed by zero-initializing `ccprog` alongside the group arrays. Building `ovlpgrp` then surfaced a third, unrelated uninitialized-read bug present in **four** subroutines (`info_sources`/`info_sourcesovlp`/`info_sources2`/`info_sources3`, all in `selroutines.f90`, so it affected discrete generations too, not just `ovlp`): a local `initblup` flag was read in a comparison on the very first call to each subroutine within a program run before ever being assigned, its value undefined until a BLUP (code 2) info source was actually seen. Fixed by explicitly initializing `initblup="n"` in all four. See `tests/README.md` for all three in full detail. `ovlpgrp` deliberately does **not** combine BLUP breeding values with a group as an info source — see the coverage-gap note below for why.
- `fsgroupsoff`/`hsgroupsoff`/`hsgroupsdams`/`proggroupsdams`/`proggroupsoffs`/`proggroupsoffd` (fixed `real, dimension(20)` in `selparameters.f90`) are only populated for the actually-configured number of groups, but `selection_index`/`intra_sd` in `selroutines.f90` unconditionally summed/indexed all 20 slots — a real uninitialized-read bug (confirmed via a `-finit-real=snan -ffpe-trap=...` debug build that segfaulted at `selroutines.f90:1539`), first fixed by zero-initializing all six arrays in `sel1s`/`sel2s`/`sel3s` (`seldiscrete.f90`) and `ovlp` (`selovlp.f90`) before use. That closed the uninitialized-read but left every division by those arrays running unconditionally even for unconfigured/partially-configured group types — mathematically undefined (`x/0.0` or `0.0/0.0`) and still trapped under strict FPE flags. Both subroutines now take `fsgroups`/`hsgroups`/`proggroups` as arguments (matching the existing `info_sources` pattern) and guard each division to only run when that specific group index is actually configured. See `tests/README.md` ("Resolved: unconfigured group-type matrix blocks") for the full detail, and its "Resolved: negative `sigmai`" section for a separate trap (`sqrt` of a negative `sigmai`) this fix exposed, since fixed.
- **`ovlp` truncation threshold search (fixed, fortran_mac only)**: `riddr_root`'s bracket in `selovlp.f90` was ±1.5 SD (so ≥6.7% of young sires were always selected; `ovlpgrp` selected 67.5 sires instead of 10), and `trunc_delta`'s side-effect writes to `pvalcl`/`nselec` were left at the bracket midpoint on one exit path. Fixed with a wider bracket (now ±8 SD) and a re-evaluation at the root; later `sdutt1` was switched to the exact `erfc` tail and `trunc_delta`'s ±3 SD clamp (which forced ≥0.135% of every age class to be selected) removed; `ovlp2`/`ovlpgrp` expected outputs regenerated (and again after the generation-interval accumulation fix in `ovlp`). The earlier-reported "BLUP + group under `ovlp` collapses to zero" could not be reproduced before or after this fix. See `tests/README.md` and the open questions for the original authors in `NEWS.md`.
- **Triage rule for `ovlp`-specific findings in general**: a crash/FPE-trap/bounds-violation traceable to an uninitialized variable, a missing zero-init, or a division unguarded for an unconfigured case is a plain programming bug — fix it directly, same pattern as `ccprog`/`initblup`/the group-array guards below, no equation review needed. Numerically *plausible-but-wrong* output (a response, accuracy, or covariance term whose value looks off but doesn't crash) is different — treat it like the BLUP+group issue above: don't guess, document precisely what looks wrong and where, and get the original theory (Bijma/Dekkers, or the original manual/technical report) before touching the equations.
- `tests/README.md` also documents why `blup1.out` was regenerated: its BLUP index weight for a non-breeding-goal trait is genuinely near zero after 25 rounds of iterative equilibrium, right at the display-rounding boundary — sensitive to compiler-version-level floating-point differences, not a functional bug. The reference toolchain is recorded there.
- `make test` / `make docs` referenced in older versions of this file do not exist — there is no build system beyond the direct `gfortran` commands above and `tests/run_tests.sh`.
- **TODO**: wire `tests/run_tests.sh` into a GitHub Actions workflow and add a real build/test-status badge to `README.md`. Until then, don't add a CI/build-status badge — there'd be nothing behind it but the compile step, which isn't the same as correctness.

## Common Issues

- **Module not found errors**: ensure compilation order is correct (see Module Dependencies above).
- **Long line errors**: add `-ffixed-line-length-none` when compiling `fortran_orig/` directly.
- **Singular matrix errors**: check genetic parameter consistency in input data (correlation matrices must be positive definite).

## Related Project

A separate R package, `SelActionR`, reimplements this program's selection index theory for a modern scriptable interface (targeting CRAN). It lives in its own repository, not this one. This repository is its validation reference — R outputs should be checked against the fixtures in `tests/fixtures/` (see `tests/README.md`) and the `examples/` outputs.

## Documentation Resources

- `manual/SelAction_Manual.md` — user manual with GUI instructions
- `manual/SelAction_Program_Description.md` — technical description and mathematics
- `docs/SelAction_Technical_Report.pdf` and the per-module reports in `docs/` — detailed derivations
- `README_Inputs.md` — field-by-field input file mapping guide
