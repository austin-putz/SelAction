# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SelAction is a Fortran-based animal breeding selection index program that calculates genetic responses and inbreeding effects for various selection schemes. This repository holds the original reference code from Peter Bijma plus two lightly-modified forks that make it compile with a modern gfortran, on Linux and macOS respectively.

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

### macOS (currently broken — do not assume this works)

```bash
cd fortran_mac/
make        # builds only `mssel`; known to fail/misbehave, see README.md "Known Issues"
```

### Original version (reference only, never modify)

```bash
cd fortran_orig/
# Same compilation commands as Linux, but may need -ffixed-line-length-none
# or fail outright on modern gfortran. This directory is a byte-for-byte
# copy of Peter Bijma's original code and exists for comparison only.
```

There is no top-level Makefile in this repository. Each platform directory is compiled directly with the `gfortran` invocations above (or, for `fortran_mac/`, via its own local `Makefile`).

**File order in these commands is not cosmetic.** `gfortran` compiles the files it's given left to right and needs each module's `.mod` file to already exist before compiling something that `USE`s it — so the main program (`mssel.f90` etc.) must always be *last*, after every module it depends on, in the Module Dependencies order below. Earlier drafts of this file listed the main program first, which fails outright; the order above has been verified to build cleanly.

## Code Architecture

### Directory Structure

| Directory | Description | Status |
|-----------|-------------|--------|
| `fortran_orig/` | Original Fortran code from Peter Bijma | **Never modify — treat as read-only reference** |
| `fortran_linux/` | Linux-compatible fork | Working, recommended |
| `fortran_mac/` | macOS-compatible fork | Known broken, do not present as working |
| `manual/` | User manual + program description (Markdown + PDF) | Reference documentation |
| `docs/` | LaTeX technical reports on the underlying methods | Reference documentation |
| `examples/` | Sample input files and a worked GUI example | Reference/test fixtures |
| `tests/` | Canonical `.in`/`.out` regression fixtures + `run_tests.sh`, shared across all platform builds and the R port | Working |

### Module Dependencies (all three of fortran_orig/fortran_linux/fortran_mac)

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
- `fortran_linux/` and `fortran_mac/` are **not** independent rewrites of `fortran_orig/` — they're the same code with the minimum edits needed to satisfy a modern compiler. When fixing something in `fortran_mac/`, diff it against `fortran_orig/` first to see exactly what already changed and why, rather than re-deriving from scratch.
- **Never edit anything under `fortran_orig/`.** If a fix is needed, make it in `fortran_linux/` or `fortran_mac/`.
- `fortran_linux/selinbreeding.f90` restricts its `USE selroutines` to `USE selroutines, ONLY: trunc`. `selroutines.f90` (present in `fortran_orig/` too) contains a leftover, fully duplicated copy of the whole `dFmtblup` function and its helpers (`create_C`, `Poissoncorr`, `hyper_correct`) — dead code from whenever `selinbreeding.f90` was split out that was never removed. A blanket `USE selroutines` pulls in that duplicate `dFmtblup` and collides with `selinbreeding.f90`'s own definition, breaking the build for `mssel`/`msseld` (but not `msselo`, which never links `selinbreeding.f90`). The `ONLY: trunc` restriction is the one symbol actually needed and avoids the collision without changing any numerics.

### Testing

- Canonical regression fixtures live in `tests/fixtures/` (not inside any platform directory), so `fortran_linux`, `fortran_mac`, a future `fortran_windows`, and an eventual C++ port all validate against the same `.in`/`.out` pairs instead of drifting copies. Run `tests/run_tests.sh [platform_dir]` (defaults to `fortran_linux`); see `tests/README.md` for the fixture format, the manifest that maps fixtures to valid binaries, and — important if adding fixtures — the 8-character filename constraint imposed by `character (len=8) :: fnam` in `selparameters.f90`.
- Fixtures: `test1` (3-trait discrete 1-stage, ported from the original distribution's smoke test), `test2s` (discrete 2-stage, `sel2s`), `test3s` (discrete 3-stage, `sel3s`), `blup1` (discrete 1-stage isolating the BLUP-specific branch of the inbreeding calculation). All four validate against both `mssel` and `msseld`. Overlapping generations (`ovlp` in `selovlp.f90`) has no fixture yet — `selovlp.f90:174` assigns to the module-level allocatable array `pheninfo` before it's ever allocated (allocation happens later, at line 330), which crashes `mssel`/`msselo` with a runtime "Assignment of scalar to unallocated array" error for any input reaching that point; this bug is inherited unchanged from `fortran_orig/selovlp.f90`, so it predates the Linux/Mac forks and isn't something the fixture work introduced.
- `make test` / `make docs` referenced in older versions of this file do not exist — there is no build system beyond the direct `gfortran` commands above and `tests/run_tests.sh`.
- **TODO**: wire `tests/run_tests.sh` into a GitHub Actions workflow and add a real build/test-status badge to `README.md`. Until then, don't add a CI/build-status badge — there'd be nothing behind it but the compile step, which isn't the same as correctness.

## Common Issues

- **Module not found errors**: ensure compilation order is correct (see Module Dependencies above).
- **Long line errors**: add `-ffixed-line-length-none` when compiling `fortran_orig/` directly.
- **Singular matrix errors**: check genetic parameter consistency in input data (correlation matrices must be positive definite).
- **`fortran_mac/` compilation conflicts**: known and unresolved — use `fortran_linux/` instead unless you're specifically working on the macOS fix.

## Related Project

A separate R package, `SelActionR`, reimplements this program's selection index theory for a modern scriptable interface (targeting CRAN). It lives in its own repository, not this one. This repository is its validation reference — R outputs should be checked against the fixtures in `tests/fixtures/` (see `tests/README.md`) and the `examples/` outputs.

## Documentation Resources

- `manual/SelAction_Manual.md` — user manual with GUI instructions
- `manual/SelAction_Program_Description.md` — technical description and mathematics
- `docs/SelAction_Technical_Report.pdf` and the per-module reports in `docs/` — detailed derivations
- `README_Inputs.md` — field-by-field input file mapping guide
