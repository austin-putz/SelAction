# Gemini Code Assistant Guidance

This file provides guidance to the Gemini Code Assistant when working with the SelAction repository. **`CLAUDE.md` is the detailed, maintained guide**; this file is a short summary of it. If the two disagree, `CLAUDE.md` is correct.

## Overview

SelAction is a Fortran animal breeding program that predicts selection response and rate of inbreeding for various selection schemes. This repository holds the original reference code plus two lightly modified forks that compile with a modern gfortran. `fortran_mac/` is the active one.

## Directory Structure

- `fortran_mac/`: **active development, recommended build.** One program, `selaction`, for every scheme. Verified on macOS (gfortran 14.2). Every fix since 2026-10-01 is here and recorded in `NEWS.md`.
- `fortran_linux/`: earlier Linux fork. Builds, but is frozen and lacks the fixes in `NEWS.md`.
- `fortran_orig/`: original code from Piter Bijma. Never edit. Does not build with a current gfortran.
- `tests/`: shared regression fixtures (`tests/fixtures/`) and `tests/run_tests.sh`.
- `docs/`: LaTeX technical reports on the methods as implemented.
- `manual/`: original user manual (Windows GUI) and program description.
- `examples/`: sample inputs and a worked GUI example.
- `plans/`: plans for major changes, with status.
- `correspondence/`: write-ups sent to collaborators.

## Build Commands

```bash
cd fortran_mac/
gfortran -g -O2 -Wall -o selaction seltools.f90 selparameters.f90 selroutines.f90 \
         selinbreeding.f90 selovlp.f90 seldiscrete.f90 selaction.f90
cd ..
tests/run_tests.sh fortran_mac
```

- **File order matters:** the main program must come last.
- **The flags matter:** without them one near-zero value in the `blup1` fixture changes sign.

## Development Guidelines

- Make changes in `fortran_mac/` and record each in `NEWS.md`.
- Never modify anything under `fortran_orig/`.
- Don't change selection-index, response or inbreeding equations without agreement from the maintainer. Open modelling questions are listed in `correspondence/2026-10-bijma-dekkers/`.
- Input can be given interactively or by redirecting a saved `.in` file; see `tests/README.md`.

## Documentation Resources

- `README.md`: project status, build, inputs, outputs, known issues.
- `docs/SelAction_Technical_Report.pdf`: the equations as implemented, by routine.
- `manual/SelAction_Manual.md`, `manual/SelAction_Program_Description.md`: original documentation.
- `README_Inputs.md`: the Windows GUI's saved input format.

## Related Project

A separate R package, `SelActionR`, will reimplement this program's theory for CRAN. It lives in its own repository, not this one.
