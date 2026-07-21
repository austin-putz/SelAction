# SelAction: Selection Index Program for Animal Breeding

A comprehensive multi-trait selection index program for animal breeding applications, calculating genetic response and inbreeding effects for various selection schemes.

## Table of Contents

- [Overview](#overview)
- [Program Structure](#program-structure)
- [Installation and Compilation](#installation-and-compilation)
- [Program Descriptions](#program-descriptions)
- [Input Parameters](#input-parameters)
- [Output Files](#output-files)
- [Mathematical Background](#mathematical-background)
- [Usage Examples](#usage-examples)
- [Known Issues](#known-issues)
- [Troubleshooting](#troubleshooting)
- [Related Project: SelActionR](#related-project-selactionr)
- [License](#license)
- [References](#references)

## Overview

SelAction is a Fortran-based program developed by Marc J.M. Rutten and Piter Bijma at Wageningen University (2000) for calculating selection responses and inbreeding rates in animal breeding programs. The program supports:

- **Single, two, and three-stage selection** in discrete generations
- **Overlapping generations** with multiple age classes
- **Multi-trait selection indices** with various information sources
- **Inbreeding calculations** using BLUP-EBV methods
- **Complex breeding structures** including full-sib and half-sib families

### Key Features

- Multi-trait genetic response predictions
- Selection index weight optimization
- Breeding value accuracy calculations
- Rate of inbreeding estimation
- Flexible information source handling
- Support for complex mating designs

## Program Structure

### Directory Organization

| Directory | Description | Status |
|-----------|-------------|--------|
| `fortran_orig/` | Original Fortran code from Peter Bijma | Reference only — never modified |
| `fortran_linux/` | Linux-compatible fork of the original code | Working — recommended for use |
| `fortran_mac/` | macOS-compatible fork of the original code | **Known broken** — see [Known Issues](#known-issues) |
| `manual/` | User manual and program description (Markdown + original PDF) | Complete |
| `docs/` | LaTeX technical reports on the underlying methods | Complete |
| `examples/` | Sample input files and a worked GUI-based example | Complete |

`fortran_linux/` and `fortran_mac/` are **not** rewrites — each is `fortran_orig/` with the minimum changes needed to satisfy a modern gfortran compiler (array-constructor syntax, line-continuation formatting, a couple of local-variable renames, one added `USE` statement). There is no separate "2.0" or "modernized" codebase; earlier drafts of this documentation referenced one, but it was never built and has been removed from these docs.

### Files (present in all three of `fortran_orig/`, `fortran_linux/`, `fortran_mac/`)

| File | Description | Lines | Purpose |
|------|-------------|-------|---------|
| `mssel.f90` | Main program (full version) | 45 | Entry point supporting all selection types |
| `msseld.f90` | Discrete generations main | 46 | Entry point for discrete generations only |
| `msselo.f90` | Overlapping generations main | 46 | Entry point for overlapping generations only |
| `seldiscrete.f90` | Discrete selection routines | 4,794 | Core calculations for 1-, 2-, 3-stage selection |
| `selovlp.f90` | Overlapping generations | ~1,000 | Overlapping generation calculations |
| `selinbreeding.f90` | Inbreeding calculations | 368 | BLUP-based inbreeding rate calculations |
| `selparameters.f90` | Global parameters | 120 | Variable definitions and declarations |
| `selroutines.f90` | Mathematical routines | ~3,400 | Matrix operations and utility functions |
| `seltools.f90` | Statistical functions | ~1,100 | Normal distribution and selection functions |

## Installation and Compilation

### Prerequisites

- **Fortran Compiler**: gfortran (GNU Fortran) 4.6 or later
- **Operating System**: Linux or macOS
- **Memory**: Minimum 512 MB RAM (depends on problem size)

### Installing gfortran

```bash
# macOS (Homebrew)
brew install gcc

# Ubuntu/Debian
sudo apt-get install gfortran

# CentOS/RHEL
sudo yum install gcc-gfortran
```

### Linux (recommended, verified working)

`gfortran` compiles left to right and needs each module already built before compiling anything that `USE`s it, so **the main program must come last**, after every module it depends on:

```bash
cd fortran_linux/

# Full version
gfortran -o mssel seltools.f90 selparameters.f90 selroutines.f90 \
         selinbreeding.f90 selovlp.f90 seldiscrete.f90 mssel.f90

# Discrete generations only
gfortran -o msseld seltools.f90 selparameters.f90 selroutines.f90 \
         selinbreeding.f90 seldiscrete.f90 msseld.f90

# Overlapping generations only
gfortran -o msselo seltools.f90 selparameters.f90 selroutines.f90 \
         selovlp.f90 msselo.f90
```

All three binaries have been built and smoke-tested against `fortran_linux/test1.in` with this exact sequence.

### macOS (known broken — see Known Issues)

```bash
cd fortran_mac/
make        # builds only `mssel`; currently fails/misbehaves, see Known Issues
```

### Original version (reference only)

```bash
cd fortran_orig/
# Same compilation order as the Linux version above. mssel and msseld
# will still fail with a modern gfortran even with correct ordering
# (see Known Issues — this is a pre-existing bug in the original code,
# unrelated to file order). msselo builds and runs fine. This directory
# exists for comparison against Rutten & Bijma's original source, not
# as a build target — use fortran_linux/ if you need a working binary.
```

### Compilation Flags

- `-O2`: Optimization level 2
- `-g`: Include debugging information
- `-Wall`: Enable warnings
- `-ffixed-line-length-none`: Needed if you hit "line truncated" errors against `fortran_orig/`

## Program Descriptions

### Main Executables

#### mssel (Full Version)
The complete program supporting all selection schemes:

**Features:**
- 1-, 2-, 3-stage selection in discrete generations
- Overlapping generations with multiple age classes
- Interactive menu system for selection type choice

**Usage:**
```bash
./mssel
# Follow interactive prompts to select:
# 1 = Single stage
# 2 = Two stage
# 3 = Three stage
# o = Overlapping generations
```

#### msseld (Discrete Generations)
Specialized for discrete generation breeding schemes — single, two, and three-stage selection, optimized for traditional breeding programs.

#### msselo (Overlapping Generations)
Specialized for overlapping generation schemes — multiple age classes per sex, age-specific selection intensities, generation interval optimization, complex family structures.

### Core Modules

#### Selection Calculations (`seldiscrete.f90`)
Three main subroutines: `sel1s` (single-stage), `sel2s` (two-stage), `sel3s` (three-stage). Each handles trait parameter input, information source configuration, genetic correlation matrices, selection index calculation, and response prediction.

#### Overlapping Generations (`selovlp.f90`)
Age class definition, selection across age groups, generation interval calculation, genetic lag computation.

#### Inbreeding Module (`selinbreeding.f90`)
Calculates inbreeding rates using BLUP breeding values, multi-trait selection indices, finite population corrections, and Poisson variance corrections.

## Input Parameters

See [`README_Inputs.md`](README_Inputs.md) for a full field-by-field mapping guide, and `examples/input_selaction.txt` / `examples/output_discrete_1_stage/` for worked examples.

### General Parameters

| Parameter | Description | Range | Default |
|-----------|-------------|--------|---------|
| `ntraits` | Number of traits | 1-20 | - |
| `filename` | Base filename (max 8 chars) | - | "test" |
| `indexdiff` | Different indices for sires/dams | y/n | n |
| `initc` | Common environment effects | y/n | n |

### Population Structure

| Parameter | Description | Units |
|-----------|-------------|--------|
| `nsires` | Number of selected sires | count |
| `ndams` | Number of selected dams | count |
| `noffs` | Male offspring per dam | count |
| `noffd` | Female offspring per dam | count |

### Genetic Parameters

| Parameter | Description | Range |
|-----------|-------------|--------|
| `h²` | Heritability | 0.01-0.99 |
| `c²` | Common environment ratio | 0.0-0.5 |
| `rG` | Genetic correlations | -1.0 to 1.0 |
| `rP` | Phenotypic correlations | -1.0 to 1.0 |

### Information Sources

The program supports 84 different information source types:

1. **Own performance** (source 1)
2. **EBV of dam** (source 2)
3. **EBV of sire** (source 3)
4. **Full-sib information** (sources 4-23)
5. **Half-sib information** (sources 24-43)
6. **Dam half-sib EBV** (sources 44-63)
7. **Progeny information** (sources 64-83)

### Selection Intensities

Input as either **proportions selected** (0.01 to 1.0) or **number of animals selected** (truncation selection).

## Output Files

#### Input File (`.in`)
Contains all input parameters in structured format, e.g.:
```
        1 ! stage selection
 test ! filenames
        2 ! number of traits
        n ! different indices for sires and dams
        y ! common environmental effects
```

#### Output File (`.out`)
Contains the header (program identification, input parameter summary, date/time stamp) and results (selection index weights, genetic responses per trait, accuracies and correlations, inbreeding rates if calculated).

### Example Output Interpretation

```
Selection Index Weights:
Trait 1 (Sires):   0.45
Trait 2 (Sires):   0.32

Genetic Response per Generation:
Trait 1: 0.85 genetic standard deviations
Trait 2: 0.62 genetic standard deviations

Index Accuracy: 0.78
Rate of Inbreeding: 0.0125 per generation
```

## Mathematical Background

### Selection Index Theory

The program implements Smith-Hazel selection indices:

**Index:** I = b'P

Where:
- b = vector of index weights
- P = vector of phenotypic values

**Optimal weights:** b = P⁻¹Gv

Where:
- P⁻¹ = inverse of phenotypic covariance matrix
- G = genetic covariance matrix
- v = vector of economic weights

### Multi-stage Selection

For k-stage selection, the program calculates stage-specific responses, correlated responses between stages, and combined selection response.

### Inbreeding Calculations

Uses the formula from Bijma and Woolliams (2000):

ΔF = (1/8) × (m×σ²ₛ + f×σ²ᵈ)

Where m, f = number of sires and dams; σ²ₛ, σ²ᵈ = variance in family size for sires and dams.

### Accuracy Calculations

Index accuracy: rᵢₕ = √(b'Pb)/(h²σ²ₐ)

Where b'Pb = variance of index; h²σ²ₐ = genetic variance.

See `docs/SelAction_Technical_Report.pdf` and the individual module reports (`docs/seldiscrete_report.pdf`, `docs/selovlp_report.pdf`, `docs/selinbreeding_report.pdf`) for the full derivations.

## Usage Examples

### Example 1: Single Trait, Single Stage

```bash
./mssel
# Select: 1 (single stage)
# Input: filename example1, 1 trait, h² 0.3, 10 sires, 100 dams, own performance
```

### Example 2: Two Traits, Two Stages

```bash
./mssel
# Select: 2 (two stage)
# Trait 1: h² = 0.4, economic weight = 1.0
# Trait 2: h² = 0.2, economic weight = 0.5
# Genetic correlation: 0.3
# Stage 1: own performance; Stage 2: progeny test
```

### Example 3: Overlapping Generations

```bash
./msselo
# filename overlap1, 1 trait, 3 age classes
```

### Example 4: Worked example from the GUI version

See `examples/output_discrete_1_stage/` for a complete 3-trait, single-stage worked example including the original Windows GUI screenshots, the input file, and the output file — useful as a template for building your own `.in` files, and as a reference `README_Inputs.md` explains field-by-field.

## Known Issues

- **`fortran_mac/` does not build cleanly.** It diverges from `fortran_orig/` in most of its modules (not just the handful of compiler-compatibility tweaks in `fortran_linux/`), and those changes currently conflict. Use `fortran_linux/` — including on macOS via a case-sensitive filesystem or Linux VM/container — until this is debugged. Contributions welcome; please open an issue with the exact gfortran version and error output.
- **`selroutines.f90` contains dead, duplicated code.** Somewhere in its history, the entire `dFmtblup` inbreeding function (and its helpers `create_C`, `Poissoncorr`, `hyper_correct`) got copy-pasted into `selroutines.f90` in addition to living in `selinbreeding.f90`/`MODULE Inbreeding` where it's actually used. This is present in `fortran_orig/` too — it's not something introduced by either fork. It only becomes a build error because `selinbreeding.f90` does `USE selroutines` unrestricted, which collides with its own `dFmtblup`. `fortran_linux/selinbreeding.f90` fixes this with `USE selroutines, ONLY: trunc` (the one symbol it actually needs); `fortran_orig/` and `fortran_mac/` are unaffected/untouched by that fix, so `mssel`/`msseld` from `fortran_orig/` still won't build even with correct file order.
- **Singular matrix errors**: usually caused by inconsistent genetic parameters (correlation matrices that aren't positive definite) — check inputs before assuming a code bug.
- **Module not found / build order**: always compile `seltools.f90` → `selparameters.f90` → `selroutines.f90` → `selinbreeding.f90`/`selovlp.f90`/`seldiscrete.f90` → the main program, in that order (see [Installation and Compilation](#installation-and-compilation)). The main program must always come last.

## Troubleshooting

### Common Issues

#### Compilation Errors

**Module not found:**
```
Fatal Error: Cannot open module file 'seltools.mod'
```
**Solution:** Compile modules in dependency order (see [Installation and Compilation](#installation-and-compilation)).

**Long line errors (only against `fortran_orig/`):**
```
Error: Line truncated
```
**Solution:** Add `-ffixed-line-length-none`, or use `fortran_linux/` instead, which already fixes this.

#### Runtime Errors

**Singular matrix:**
```
ERROR: Matrix is singular - cannot invert
```
**Solution:** Check genetic parameters for logical consistency (correlation matrices must be positive definite).

**Negative heritability:**
```
Wrong input, heritability must be higher than 0!
```
**Solution:** Enter heritability between 0.01 and 0.99.

#### Input Validation

**Invalid selection proportion:**
```
P-value out of bounds
```
**Solution:** Enter proportions between 0.01 and 1.0.

### Getting Help

1. Check input files for parameter validation (see `README_Inputs.md`)
2. Review output files for error messages
3. Verify genetic parameters are biologically reasonable
4. Test with simple examples (`examples/`) before complex scenarios

## Related Project: SelActionR

An R package reimplementation, `SelActionR`, is being developed as a separate project (not included in this repository) to provide a modern, scriptable interface to the same selection index theory, targeting eventual CRAN release. This repository remains the canonical reference implementation and validation source for that work.

## License

No license file is currently included in this repository. The original Fortran code was authored by Marc J.M. Rutten and Piter Bijma at Wageningen University — terms of reuse and redistribution should be confirmed with the original authors/institution before this repository is used beyond personal/research reference.

## References

### Primary References

1. **Rutten, M.J.M. and Bijma, P. (2000)**. SelAction: Multi-trait Selection Index Software. Animal Breeding and Genetics Group, Wageningen University.
2. **Smith, H.F. (1936)**. A discriminant function for plant selection. Annals of Eugenics, 7, 240-250.
3. **Hazel, L.N. (1943)**. The genetic basis for constructing selection indexes. Genetics, 28, 476-490.

### Inbreeding Theory

4. **Bijma, P. and Woolliams, J.A. (2000)**. Prediction of rates of inbreeding in populations selected on best linear unbiased prediction of breeding value. Genetics, 156, 361-373.
5. **Wray, N.R., Woolliams, J.A. and Thompson, R. (1990)**. Methods for predicting rates of inbreeding in selected populations. Theoretical and Applied Genetics, 80, 503-512.

### Selection Theory

6. **Bulmer, M.G. (1971)**. The effect of selection on genetic variability. American Naturalist, 105, 201-211.
7. **Lynch, M. and Walsh, B. (1998)**. Genetics and Analysis of Quantitative Traits. Sinauer Associates, Sunderland, MA.

### Implementation Details

8. **Press, W.H., Teukolsky, S.A., Vetterling, W.T. and Flannery, B.P. (2007)**. Numerical Recipes in Fortran 90: The Art of Parallel Scientific Computing. Cambridge University Press.

---

**SelAction Version 1.1 (2000)** — original development by Marc J.M. Rutten and Piter Bijma.

For questions about the original software, contact the Animal Breeding and Genetics Group at Wageningen University.
