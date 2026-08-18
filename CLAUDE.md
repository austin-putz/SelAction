# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SelAction is a Fortran-based animal breeding selection index program that calculates genetic responses and inbreeding effects for various selection schemes. This repository holds the original reference code from Peter Bijma plus a lightly-modified fork that makes it compile with a modern gfortran on Linux. A macOS fork (`fortran_mac/`) is planned next but doesn't exist in the repo yet — its previous, badly-diverged attempt was deleted rather than carried forward; see "macOS (not started yet)" below.

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

### macOS (not started yet)

There is no `fortran_mac/` directory in the repo right now — an earlier attempt at one diverged too far from `fortran_orig/` to be worth debugging further and was deleted. The macOS port is the next planned step: start from a fresh copy of `fortran_linux/` (the known-working reference) and apply only the minimum changes a macOS gfortran toolchain actually needs, the same way `fortran_linux/` was derived from `fortran_orig/`. Until that exists, build and test on Linux.

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
| `fortran_mac/` | macOS-compatible fork | Not started — next planned step, see "macOS (not started yet)" above |
| `manual/` | User manual + program description (Markdown + PDF) | Reference documentation |
| `docs/` | LaTeX technical reports on the underlying methods | Reference documentation |
| `examples/` | Sample input files and a worked GUI example | Reference/test fixtures |
| `tests/` | Canonical `.in`/`.out` regression fixtures + `run_tests.sh`, shared across all platform builds and the R port | Working |

### Module Dependencies (fortran_orig/fortran_linux today; same shape expected for a future fortran_mac)

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
- `fortran_linux/` is **not** an independent rewrite of `fortran_orig/` — it's the same code with the minimum edits needed to satisfy a modern compiler. When the macOS port (`fortran_mac/`) gets started, follow the same approach: start from `fortran_linux/` (already known-working) and diff/patch only what a macOS toolchain actually needs, rather than re-deriving from `fortran_orig/` from scratch.
- **Never edit anything under `fortran_orig/`.** If a fix is needed, make it in `fortran_linux/` (or, once it exists, `fortran_mac/`).
- `fortran_linux/selinbreeding.f90` restricts its `USE selroutines` to `USE selroutines, ONLY: trunc`. `selroutines.f90` (present in `fortran_orig/` too) contains a leftover, fully duplicated copy of the whole `dFmtblup` function and its helpers (`create_C`, `Poissoncorr`, `hyper_correct`) — dead code from whenever `selinbreeding.f90` was split out that was never removed. A blanket `USE selroutines` pulls in that duplicate `dFmtblup` and collides with `selinbreeding.f90`'s own definition, breaking the build for `mssel`/`msseld` (but not `msselo`, which never links `selinbreeding.f90`). The `ONLY: trunc` restriction is the one symbol actually needed and avoids the collision without changing any numerics.

### Testing

- Canonical regression fixtures live in `tests/fixtures/` (not inside any platform directory), so `fortran_linux`, a future `fortran_mac`/`fortran_windows`, and an eventual C++ port all validate against the same `.in`/`.out` pairs instead of drifting copies. Run `tests/run_tests.sh [platform_dir]` (defaults to `fortran_linux`); see `tests/README.md` for the fixture format, the manifest that maps fixtures to valid binaries, and — important if adding fixtures — the 8-character filename constraint imposed by `character (len=8) :: fnam` in `selparameters.f90`.
- Fixtures: `test1` (3-trait discrete 1-stage, ported from the original distribution's smoke test), `test2s` (discrete 2-stage, `sel2s`), `test3s` (discrete 3-stage, `sel3s`), `blup1` (discrete 1-stage isolating the BLUP-specific branch of the inbreeding calculation), `advgrp` (discrete 1-stage isolating the unconfigured/partially-configured group-type matrix-block guards, including a progeny-groups path no other fixture exercises), and `ovlp2` (overlapping generations, 2-trait, 2-age-class-per-sex, `msselo` only). The first five validate against both `mssel` and `msseld`. Overlapping generations (`ovlp` in `selovlp.f90`) previously had no fixture; the crash that made it unusable is fixed: `pheninfo` and `posgcorr` (both `allocatable` in `selparameters.f90`) were assigned to before being allocated — `pheninfo` was allocated ~150 lines later than its first use, and `posgcorr` wasn't allocated anywhere in this file at all (unlike its correctly-allocated counterpart in `seldiscrete.f90`). Both allocations were moved to immediately before first use, right after `ntraits`/`nclass` are read. This bug was inherited unchanged from `fortran_orig/selovlp.f90` (confirmed present there too, untouched, since `fortran_orig/` is never modified) and predates the Linux fork. Building the `ovlp2` fixture then surfaced a second, distinct bug in the same file: `ccprog` (progeny-test common-environmental effect) is only conditionally read (`initprog.eq."y" .and. initc.eq."y"`) but used unconditionally a few hundred lines later — same uninitialized-read shape as the group-array bug below, just in `selovlp.f90`. Fixed by zero-initializing `ccprog` alongside the group arrays. See `tests/README.md` for both in full detail. `ovlp2` doesn't cover fs/hs/progeny groups or BLUP breeding values under overlapping generations — a richer `ovlp` fixture covering those remains good follow-up work, but overlapping generations is no longer regression-untested.
- `fsgroupsoff`/`hsgroupsoff`/`hsgroupsdams`/`proggroupsdams`/`proggroupsoffs`/`proggroupsoffd` (fixed `real, dimension(20)` in `selparameters.f90`) are only populated for the actually-configured number of groups, but `selection_index`/`intra_sd` in `selroutines.f90` unconditionally summed/indexed all 20 slots — a real uninitialized-read bug (confirmed via a `-finit-real=snan -ffpe-trap=...` debug build that segfaulted at `selroutines.f90:1539`), first fixed by zero-initializing all six arrays in `sel1s`/`sel2s`/`sel3s` (`seldiscrete.f90`) and `ovlp` (`selovlp.f90`) before use. That closed the uninitialized-read but left every division by those arrays running unconditionally even for unconfigured/partially-configured group types — mathematically undefined (`x/0.0` or `0.0/0.0`) and still trapped under strict FPE flags. Both subroutines now take `fsgroups`/`hsgroups`/`proggroups` as arguments (matching the existing `info_sources` pattern) and guard each division to only run when that specific group index is actually configured. See `tests/README.md` ("Resolved: unconfigured group-type matrix blocks") for the full detail, and its "Known residual issue" section for a separate, unrelated trap (`sqrt` of a negative `sigmai`) this fix exposed but does not address.
- `tests/README.md` also documents why `blup1.out` was regenerated: its BLUP index weight for a non-breeding-goal trait is genuinely near zero after 25 rounds of iterative equilibrium, right at the display-rounding boundary — sensitive to compiler-version-level floating-point differences, not a functional bug. The reference toolchain is recorded there.
- `make test` / `make docs` referenced in older versions of this file do not exist — there is no build system beyond the direct `gfortran` commands above and `tests/run_tests.sh`.
- **TODO**: wire `tests/run_tests.sh` into a GitHub Actions workflow and add a real build/test-status badge to `README.md`. Until then, don't add a CI/build-status badge — there'd be nothing behind it but the compile step, which isn't the same as correctness.

## Common Issues

- **Module not found errors**: ensure compilation order is correct (see Module Dependencies above).
- **Long line errors**: add `-ffixed-line-length-none` when compiling `fortran_orig/` directly.
- **Singular matrix errors**: check genetic parameter consistency in input data (correlation matrices must be positive definite).
- **macOS build**: `fortran_mac/` doesn't exist yet — it's the next planned step (see "macOS (not started yet)" above). Use `fortran_linux/` in the meantime, including on a Mac via a Linux VM/container if needed.

## Related Project

A separate R package, `SelActionR`, reimplements this program's selection index theory for a modern scriptable interface (targeting CRAN). It lives in its own repository, not this one. This repository is its validation reference — R outputs should be checked against the fixtures in `tests/fixtures/` (see `tests/README.md`) and the `examples/` outputs.

## Documentation Resources

- `manual/SelAction_Manual.md` — user manual with GUI instructions
- `manual/SelAction_Program_Description.md` — technical description and mathematics
- `docs/SelAction_Technical_Report.pdf` and the per-module reports in `docs/` — detailed derivations
- `README_Inputs.md` — field-by-field input file mapping guide
