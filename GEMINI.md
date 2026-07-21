# Gemini Code Assistant Guidance

This file provides guidance to the Gemini Code Assistant when working with the SelAction repository.

## Overview

SelAction is a Fortran-based animal breeding selection index program that calculates genetic responses and inbreeding effects for various selection schemes. This repository contains the original reference code plus two lightly-modified forks for compiling with a modern gfortran on Linux and macOS.

## Directory Structure

- `fortran_orig/`: Original Fortran code from Peter Bijma (unmodified reference — never edit).
- `fortran_linux/`: Linux-compatible fork (working, minimal changes for compilation only).
- `fortran_mac/`: macOS-specific fork (currently not working due to conflicts).
- `manual/`: Documentation in Markdown and PDF format.
- `docs/`: LaTeX technical reports on the underlying methods.
- `examples/`: Sample input files and a worked GUI-based example.

There is no "modernized 2.0" directory in this repository. Earlier drafts of this file referenced a `fortran/`/`fortran_2/` placeholder for future work; it was empty and has been removed rather than carried forward.

## Build Commands

### Linux Version (Recommended)

```bash
cd fortran_linux/
# Full version
gfortran -o mssel mssel.f90 seldiscrete.f90 selovlp.f90 selparameters.f90 selroutines.f90 seltools.f90 selinbreeding.f90

# Discrete generations only
gfortran -o msseld msseld.f90 seldiscrete.f90 selparameters.f90 selroutines.f90 seltools.f90 selinbreeding.f90

# Overlapping generations only
gfortran -o msselo msselo.f90 selovlp.f90 selparameters.f90 selroutines.f90 seltools.f90 selinbreeding.f90
```

### Mac Version (Currently Non-Functional)

The `fortran_mac/` directory contains a `Makefile` (builds `mssel` only), but per the README this is currently not functional. Don't present it as a working build target.

### Original Version (Reference)

```bash
cd fortran_orig/
# Same compilation commands as Linux version, but may require additional flags,
# or may not build at all on modern gfortran. Reference only — never modify.
```

## Code Architecture

### Key Fortran Files (present in all three variants)

- `mssel.f90`: Main program for all selection types.
- `msseld.f90`: Main program for discrete generations only.
- `msselo.f90`: Main program for overlapping generations only.
- `seldiscrete.f90`: Core calculations for 1, 2, and 3-stage selection.
- `selovlp.f90`: Calculations for overlapping generations.
- `selinbreeding.f90`: BLUP-based inbreeding calculations.
- `selparameters.f90`: Global parameter definitions.
- `selroutines.f90`: Mathematical and matrix operations.
- `seltools.f90`: Statistical functions.

## Development Guidelines

- When working with the Fortran code, use the `gfortran` compiler.
- For reliable compilation, prefer the `fortran_linux/` version.
- Never modify anything under `fortran_orig/`.
- Input for the programs can be provided interactively or via a redirected input file.

## Common Issues

- **Mac Compilation:** The `fortran_mac/` version is known to have compilation conflicts.
- **Singular Matrix Errors:** Check the consistency of genetic parameters in the input data.
- **Input Format:** The program is sensitive to the input file format. Refer to `README_Inputs.md` and `examples/output_discrete_1_stage/SelAction_Inputs.txt` for the correct format.

## Documentation Resources

The `manual/` and `docs/` directories contain comprehensive documentation:

- `SelAction_Manual.md`: User manual with GUI instructions.
- `SelAction_Program_Description.md`: Technical details and mathematical formulations.
- `SelAction_Technical_Report.pdf`: A high-level technical description of the program.

The `README.md` and `README_Inputs.md` files also provide valuable information about the project and its usage.

## Related Project

A separate R package, `SelActionR`, reimplements this program's theory for CRAN. It lives in its own repository, not this one.
