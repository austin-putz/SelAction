<!-- badges: start -->
<table align="center" border="0">
<tr>
<td width="230" align="center" valign="middle">
<img src="logos/SelAction_hex.png" alt="SelAction hex logo" width="210" />
</td>
<td valign="middle">

<h1 align="left" style="border-bottom: none;">SelAction</h1>

<p align="left"><strong>Predict selection response and rate of inbreeding in livestock breeding programs.</strong></p>

<p align="left">
<a href="https://www.repostatus.org/#active"><img src="https://img.shields.io/badge/status-active%20development-2ea44f.svg?style=for-the-badge" alt="Status: active development" /></a>
<a href="NEWS.md"><img src="https://img.shields.io/badge/version-1.2-4ecdc4.svg?style=for-the-badge" alt="Version 1.2" /></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue.svg?style=for-the-badge" alt="License: GPL-3.0" /></a>
<a href="https://doi.org/10.1093/jhered/93.6.456"><img src="https://img.shields.io/badge/cite-J.%20Hered.%202002-b31b1b.svg?style=for-the-badge" alt="Citation: Journal of Heredity 2002" /></a>
</p>

<p align="left">
<a href="https://fortran-lang.org"><img src="https://img.shields.io/badge/Fortran-90-734f96.svg?style=for-the-badge&logo=fortran&logoColor=white" alt="Fortran 90" /></a>
<a href="https://gcc.gnu.org/fortran/"><img src="https://img.shields.io/badge/tested%20with-gfortran%2014.2-orange.svg?style=for-the-badge&logo=gnu&logoColor=white" alt="Tested with gfortran 14.2" /></a>
<a href="#installation-and-compilation"><img src="https://img.shields.io/badge/build-make-427819.svg?style=for-the-badge&logo=gnu&logoColor=white" alt="Build: make" /></a>
<a href="tests/README.md"><img src="https://img.shields.io/badge/tests-7%20golden%20fixtures-1f9c5a.svg?style=for-the-badge" alt="Tests: 7 golden fixtures" /></a>
<a href="docs/SelAction_Technical_Report.pdf"><img src="https://img.shields.io/badge/docs-technical%20report-555555.svg?style=for-the-badge&logo=latex&logoColor=white" alt="Docs: technical report" /></a>
</p>

</td>
</tr>
</table>
<!-- badges: end -->

## Citation

Please cite the original paper from Rutten *et al.* using the following:

**Rutten, M.J.M., Bijma, P., Woolliams, J.A., & Van Arendonk, J.A.M. (2002)**. SelAction: Software to predict selection response and rate of inbreeding in livestock breeding programs. Journal of Heredity, 93(6), 456-458. [https://doi.org/10.1093/jhered/93.6.456](https://doi.org/10.1093/jhered/93.6.456)

When the full software package is up and running, we'll provide a citation for that as well.

## Bug Reports

Email :e-mail: putz.austin@gmail.com with a full report

## Table of Contents

- [Project Status](#project-status)
- [Overview](#overview)
- [Program Structure](#program-structure)
- [Installation and Compilation](#installation-and-compilation)
- [Program Descriptions](#program-descriptions)
- [Input Parameters](#input-parameters)
- [Output Files](#output-files)
- [Mathematical Background](#mathematical-background)
- [Usage Examples](#usage-examples)
- [Testing](#testing)
- [Known Issues](#known-issues)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Related Project: SelActionR](#related-project-selactionr)
- [License](#license)
- [References](#references)

## Project Status

*Updated 5 October 2026.*

SelAction is being brought up to date at Iowa State University (Austin Putz and Jack Dekkers), starting from the original Fortran code by Marc Rutten and Piter Bijma. The current version is **1.2**, in `fortran/`.

**Done so far** (details in [`NEWS.md`](NEWS.md)):

- The code builds with a current gfortran, as one program, `selaction`, for every selection scheme.
- **Crashes and uninitialised-value bugs fixed**, mostly inherited from the original code. These include:
  - overlapping generations crashing outright
  - variables read before they were set
  - divisions by zero for group types that are not configured
- **Fixes that change predictions:**
  - **Overlapping generations:** the truncation-point search selected the wrong number of parents (e.g. 67.5 sires when 10 were requested). The generation interval is also corrected.
  - **Multistage selection:** the normal-integral tables were too short, giving grossly wrong responses for small selected fractions.
- **Regression tests:** 7 test inputs with stored outputs, run by `make test`.
- **Technical report:** `docs/SelAction_Technical_Report.pdf` ties every equation to the routine that computes it.
- **Open modelling questions** for the original authors are written up with evidence in [`correspondence/2026-10-bijma-dekkers/SelAction_open_questions.pdf`](correspondence/2026-10-bijma-dekkers/SelAction_open_questions.pdf). The model itself has **not** been changed while these are open.

**Next:** the first part of test hardening ([`plans/test-hardening.md`](plans/test-hardening.md)), then scenario-based YAML input and CSV output ([`plans/modernize-inputs-and-outputs.md`](plans/modernize-inputs-and-outputs.md)), then the correctness tests. See [Roadmap](#roadmap) and the step-by-step order in [`plans/implementation-sequence.md`](plans/implementation-sequence.md).

## Overview

SelAction is a Fortran program developed by Marc J.M. Rutten and Piter Bijma at Wageningen University (2000). It predicts selection response and rates of inbreeding in animal breeding programs. It supports:

- **Single, two, and three-stage selection** in discrete generations
- **Overlapping generations** with multiple age classes per sex
- **Multi-trait selection indices** combining many information sources (own performance, BLUP breeding values, full-sib, half-sib and progeny groups)
- **The Bulmer effect:** reduction of genetic variance by selection, iterated to equilibrium
- **Rate of inbreeding:** predicted with the method of Bijma and Woolliams (2000), including for selection on BLUP breeding values

### Key Features

- Multi-trait genetic response predictions, per sex and in total
- Optimal selection index weights
- Index accuracy and equilibrium genetic parameters
- Rate of inbreeding per generation
- Flexible information sources, including separate indices for sires and dams

## Program Structure

### Directory Organization

| Directory | Description | Status |
|-----------|-------------|--------|
| `fortran/` | Current code (version 1.2); builds one program, `selaction`, on any OS | **Active development: use this.** Verified on macOS (Intel, gfortran 14.2) |
| `build/` | Build output from `make` (the `selaction` binary and module files) | Created on each machine; not in git |
| `fortran_orig/` | Original Fortran code from Piter Bijma | Reference only, never modified. Does not build with a current gfortran |
| `tests/` | Regression test inputs/outputs and runner, shared by all builds | Working, 7 test inputs |
| `docs/` | LaTeX technical reports on the methods as implemented | Complete; updated October 2026 |
| `manual_orig/` | Original user manual and program description (PDF), with Markdown/HTML transcriptions | Reference; describes the original Windows GUI. The PDFs are never modified |
| `examples/` | Sample input files and a worked GUI-based example | Reference |
| `correspondence/` | Write-ups sent to collaborators (e.g. open questions for the original authors) | — |
| `plans/` | Design plans for larger changes, with their status | — |

The `Makefile` at the top level builds `fortran/` into `build/` (see [Installation and Compilation](#installation-and-compilation)).

`fortran/` is **not** a rewrite. It is `fortran_orig/` with the minimum changes needed to satisfy a modern gfortran compiler (array-constructor syntax, line-continuation formatting, a few local-variable renames and one restricted `USE` statement), plus the fixes listed in [`NEWS.md`](NEWS.md). It contains nothing specific to any operating system, so there is one source tree for every platform. Until October 2026 it was called `fortran_mac/`, and an older, unfixed copy lived in `fortran_linux/`; that copy was removed (it remains in the git history).

### Files

`fortran/` has a single main program, `selaction.f90`, which builds the single `selaction` binary. `fortran_orig/` still has the original three main programs (`mssel.f90`, `msseld.f90`, `msselo.f90`).

Line counts below are for `fortran/`.

| File | Description | Lines | Purpose |
|------|-------------|-------|---------|
| `selaction.f90` (`fortran/`) | Main program | 45 | Entry point for every selection type (1/2/3 stages, overlapping generations) |
| `mssel.f90` (`fortran_orig/`) | Main program (full version) | 45 | Entry point for every selection type; `selaction.f90` is this file renamed |
| `msseld.f90` (`fortran_orig/`) | Discrete generations main | 46 | Entry point for discrete generations only |
| `msselo.f90` (`fortran_orig/`) | Overlapping generations main | 46 | Entry point for overlapping generations only |
| `seldiscrete.f90` | Discrete selection | 4,919 | `sel1s`, `sel2s`, `sel3s`: 1-, 2- and 3-stage selection |
| `selovlp.f90` | Overlapping generations | 1,499 | `ovlp`: age classes, truncation across classes, generation interval |
| `selroutines.f90` | Index and utility routines | 3,538 | Selection index, information sources, covariance updates, matrix routines, and the live rate-of-inbreeding code (`dFmtblup`) |
| `seltools.f90` | Statistical functions | 1,412 | Normal distribution, truncation, finite-population correction of intensity (`rawl3`), multivariate normal integrals |
| `selparameters.f90` | Global parameters | 120 | Shared variable declarations |

## Installation and Compilation

### Prerequisites

You need two tools, both free:

- **gfortran** (GNU Fortran), a recent version. Verified with 14.2.0.
- **make**, which runs the build commands in the top-level `Makefile`.

The same source and the same `Makefile` are used on every operating system. Only the way you install the two tools differs. If you can't install `make`, you can still build with one gfortran command (see [Building without make](#building-without-make)).

**Tested so far:** macOS (Intel). Linux, Apple Silicon Macs and Windows use the same commands but have not been verified yet; automated checks on all of them are planned (`plans/test-hardening.md`, step T6).

### Installing the tools

#### macOS (Intel and Apple Silicon)

```bash
xcode-select --install     # Apple's command-line tools: provides make and git
brew install gcc           # provides gfortran (needs Homebrew: https://brew.sh)
```

gfortran ships inside Homebrew's `gcc` formula. Apple's own `gcc` is clang and has no Fortran compiler.

#### Linux

Use your distribution's package manager:

```bash
# Ubuntu, Debian, Linux Mint, Pop!_OS
sudo apt update && sudo apt install gfortran make

# Fedora, RHEL 8+, Rocky Linux, AlmaLinux, CentOS Stream
sudo dnf install gcc-gfortran make

# CentOS 7 / RHEL 7 (older)
sudo yum install gcc-gfortran make

# Arch Linux, Manjaro
sudo pacman -S gcc-fortran make

# openSUSE
sudo zypper install gcc-fortran make
```

#### Windows

The `Makefile` uses Unix shell commands, so on Windows build inside one of these, not in Command Prompt or PowerShell:

- **MSYS2 (recommended, gives a native `selaction.exe`):**
  1. Install MSYS2 from <https://www.msys2.org>.
  2. Open the **MSYS2 UCRT64** terminal from the Start menu.
  3. Install the tools:
     ```bash
     pacman -S --needed mingw-w64-ucrt-x86_64-gcc-fortran make
     ```
  4. Go to the folder holding SelAction. Windows drives appear under `/c/`, `/d/` and so on, e.g. `cd /c/Users/<you>/SelAction`.
  5. Build with `make` as below. The program is `build/selaction.exe`. Run it from the same MSYS2 terminal. Running it from Command Prompt or PowerShell also works if `C:\msys64\ucrt64\bin` is on your `PATH`, since the program uses gfortran's runtime libraries from there. The planned ready-made downloads won't need this.
- **WSL (Windows Subsystem for Linux):** install Ubuntu with `wsl --install` in PowerShell, open the Ubuntu terminal, and follow the Linux (Ubuntu) instructions above. The result is a Linux program that runs inside WSL.

#### Check the tools

In the terminal you'll build from:

```bash
gfortran --version
make --version
```

Both should print a version. If `gfortran` is not found on macOS, open a new terminal after installing Homebrew's `gcc`.

#### Getting the code

```bash
git clone https://github.com/austin-putz/SelAction.git
cd SelAction
```

Or download the ZIP from GitHub (Code → Download ZIP), unpack it, and `cd` into the folder.

### Building `selaction` (recommended)

From the top of the repository:

```bash
make          # builds build/selaction
make test     # builds if needed, then runs the regression tests and error cases
make clean    # removes build/
```

- **Where the output goes:** everything the compiler produces (the `selaction` binary, the `.mod` module files and, on macOS, `selaction.dSYM`) goes to `build/`. `fortran/` stays source-only, and `build/` is not tracked by git, so each machine builds its own. On Windows the program is `build/selaction.exe`.
- **The flags are `-g -O2 -Wall`.** Without them, the `blup1` test differs in the sign of one near-zero value (`-0.000` vs `0.000`). That is a compiler floating-point effect, not a bug; see `tests/README.md`, "Numerical precision and the reference toolchain".
- **`-Wall` prints many warnings** on the legacy code. They are expected.
- **Overrides:** e.g. `make FC=gfortran-14` for a specific compiler, or `make BUILD=build/debug FFLAGS="-g -O0 -fcheck=all"` for a second build next to the normal one.

#### Building without make

Run the same command by hand from the top of the repository. `gfortran` compiles left to right and needs each module built before anything that `USE`s it, so **the main program must come last**:

```bash
mkdir -p build
gfortran -g -O2 -Wall -J build -o build/selaction \
         fortran/seltools.f90 fortran/selparameters.f90 fortran/selroutines.f90 \
         fortran/selovlp.f90 fortran/seldiscrete.f90 fortran/selaction.f90
```

Verified with GNU Fortran 14.2.0 on macOS (x86_64): `selaction` builds without errors and passes every test (`make test`).

The code is plain standard Fortran with nothing specific to any operating system, so `make` builds it the same way on Linux, macOS (Intel or Apple Silicon) and Windows (gfortran via MSYS2 or WSL). Only the macOS Intel build has been verified so far; automated builds on other platforms are planned (`plans/test-hardening.md`, step T6). Ready-made downloads, so you can run SelAction without compiling, are planned next ([`plans/releases.md`](plans/releases.md)). Results on other platforms or compilers can differ in the last printed digit, which is why the stored test outputs are tied to one reference toolchain (see `tests/README.md`).

### Original version (reference only)

`fortran_orig/` exists for comparison against Rutten and Bijma's original source, not as a build target. None of its three programs builds with a current gfortran (checked with 14.2.0):

- **`mssel` and `msseld`** fail because `selinbreeding.f90` imports a second copy of `dFmtblup` from `selroutines.f90` (see Known Issues).
- **All three** fail in `selovlp.f90`, where `genint` is used without being declared under `implicit none`.

## Program Descriptions

### selaction (`fortran/`)

The program to run. It is the former `mssel`, renamed, and supports every selection scheme:

- 1-, 2- and 3-stage selection in discrete generations
- Overlapping generations with several age classes per sex

Its banner (on screen and at the top of every `.out` report) reads "SelAction … version 1.2". It credits the original authors (Rutten and Bijma, Wageningen University, 2000) and the current update (Austin Putz and Jack Dekkers, Iowa State University, 2026).

```bash
build/selaction        # from the top of the repository, after `make`
# Answer the prompts. The first one chooses the scheme:
# 1 = single stage, 2 = two stage, 3 = three stage, o = overlapping generations
```

### Legacy programs (`fortran_orig/`)

- **`mssel`:** the same program as `selaction`.
- **`msseld`:** discrete generations only (refuses `o`).
- **`msselo`:** overlapping generations only.

All three call the same routines.

### Core Modules

- **`seldiscrete.f90`:** `sel1s`, `sel2s`, `sel3s`. Each reads the traits, parameters, population and information sources for its scheme, iterates the Bulmer equilibrium (25 rounds), and writes the report.
- **`selovlp.f90`:** `ovlp`. Age classes per sex, a common truncation point across classes (or fixed numbers per class), generation interval, and genetic lag between classes.
- **`selroutines.f90`:** the selection index itself (`selection_index`), information-source input, covariance updates, matrix inversion, and the rate-of-inbreeding calculation (`dFmtblup` with `Poissoncorr` and `hyper_correct`).
- **`seltools.f90`:** normal quantiles and tails, the finite-population correction of intensity (`rawl3`), and bi-/trivariate normal integrals used in multistage selection.

## Input Parameters

The program asks for its input one prompt at a time; which prompt comes next depends on earlier answers. Each answer is echoed, with a label, to `<filename>.in`, which can be replayed later. [`tests/fixtures/test1.in`](tests/fixtures/test1.in) is a complete, labelled example.

[`README_Inputs.md`](README_Inputs.md) describes the input file saved by the original Windows GUI (`examples/output_discrete_1_stage/`), which is a different format.

### General

| Input | Description | Allowed values |
|-------|-------------|----------------|
| scheme | Selection scheme | `1`, `2`, `3` (stages) or `o` (overlapping generations) |
| filename | Base name for the `.in`/`.out` files | at most 8 characters, no spaces; anything else stops the run with an error (exit code 2) |
| number of traits | Number of traits | 1–20 |
| trait name | Name of each trait | at most 8 characters, no spaces, each different (ignoring case); anything else stops the run with an error (exit code 2) |
| use of trait | Role of each trait | `i` index only, `h` breeding goal only, `b` both, `n` not used |
| different indices for sires and dams | Separate information sources per sex | `y`/`n` |
| common environment | Include common-environment (c²) effects | `y`/`n` |

### Population structure (discrete generations)

| Input | Description |
|-------|-------------|
| number of selected sires / dams | Parents selected per generation |
| male / female selection candidates per dam | Offspring per dam available for selection |
| selected proportion sires / dams | Fraction selected (per stage for multistage selection) |

### Genetic parameters

| Parameter | Description | Rule checked by the program |
|-----------|-------------|-----------------------------|
| σ²P | Phenotypic variance | — |
| h² | Heritability | 0 < h² < 1 |
| c² | Common-environment effect | 0 ≤ c² < 1 and h² + c² < 1 |
| rP, rG, rC | Phenotypic, genetic and common-environment correlations | −1 < r < 1 |

The correlation matrices must also be positive definite. The program only checks this after computing the results (see Known Issues).

### Information sources

Information sources are entered per trait as a list of codes ending with `-1`:

| Code | Source |
|------|--------|
| 1 | Own performance |
| 2 | BLUP breeding values |
| 4–23 | Full-sib group 1–20 |
| 24–43 | Half-sib group 1–20 |
| 64–83 | Progeny group 1–20 |

Codes 3 and 44–63 are never entered. They appear in the output as the expansion of code 2: the dam's EBV (shown under code 2), the sire's EBV (code 3), and the mean EBV of the dams of half-sib group k (codes 44–63). That is why `test1` enters `1 2 4 24` but its report lists six sources per trait.

### Selection

- **Discrete generations:** the proportion selected per sex (and per stage), strictly between 0 and 1.
- **Overlapping generations:** truncation across age classes with a common threshold per sex, or a fixed number selected per age class.

## Output Files

### Input echo (`<filename>.in`)

Every answer, one per line, with a `!` label:

```
         1 ! stage selection
  test1    ! filenames
         3 ! number of traits
         n ! different indices for sires and dams
  eADG     ! name of trait  1
         i ! use of eADG
```

### Report (`<filename>.out`)

The report has these parts:

- **Inputs:** trait parameters, correlation matrices, breeding goal, population size and groups.
- **Index weights:** one per information source and trait.
- **Results:**
  - equilibrium parameters after the Bulmer effect
  - response per trait, by sex and in total, in trait and economic units
  - correlated response for index-only traits
  - total response
  - index variance, breeding-goal variance and accuracy
  - rate of inbreeding

An excerpt from `tests/fixtures/test1.out`:

```
  RESPONSE
                            sires           dams          total
 ADG
         trait units :      3.455          1.859          5.314
      economic units :     17.273          9.295         26.568
 % of total response :     62.024         33.378         95.403

  TOTAL RESPONSE
                            sires           dams          total
      economic units :     18.105          9.743         27.849

        index variance :       203.380
 breeding goal variance :       612.380
     accuracy of index :         0.576

 increase of inbreeding :  4.046% per generation
```

## Mathematical Background

This is a short summary. `docs/SelAction_Technical_Report.pdf` gives the full equations as implemented, with the routine that computes each one. The module reports (`docs/seldiscrete_report.pdf`, `docs/selovlp_report.pdf`, `docs/selinbreeding_report.pdf`) go into more detail; the last describes the unused inbreeding module, which is now only in `fortran_orig/`.

### Selection index

The program uses Smith–Hazel selection indices. With **x** the vector of information sources, **P** their covariance matrix, **G** the covariance between the sources and the breeding values of the goal traits, and **v** the economic values:

- **Index:** I = **b**′**x**
- **Optimal weights:** **b** = **P**⁻¹**G****v**
- **Accuracy:** r_IH = σ_I / σ_H = √(**b**′**P****b** / **v**′**C****v**), where **C** is the genetic covariance matrix of the goal traits

### Bulmer effect

Selection reduces the genetic variance among the selected parents, and with it the variance in their offspring. The program iterates this for 25 rounds to an equilibrium (Bulmer 1971). The "equilibrium parameters" in the report are the result.

### Multistage selection

Each stage has its own index, using the information available up to that stage. Candidates must pass every stage. Response follows from the moments of the truncated multivariate normal distribution (Tallis 1961), using bi- and trivariate normal integrals.

### Overlapping generations

A common truncation point per sex is applied across age classes, each with its own index. Older classes start from a lower genetic mean (genetic lag). Annual response follows Rendel and Robertson (1950): the sum of the selection differentials of both sexes, divided by the sum of their generation intervals.

### Rate of inbreeding

Predicted with the method of Bijma and Woolliams (2000):

- **Expected long-term genetic contributions** are calculated from the selective advantage of the parents.
- **A correction for finite family sizes** is added, using co-selection probabilities of sibs (Wray, Woolliams and Thompson 1990).

The method covers selection on BLUP breeding values.

### Intensity in small populations

The selection intensity is corrected for the finite number of candidates and the correlation between the index values of sibs (Rawlings 1976; Meuwissen 1991).

## Usage Examples

All examples use `build/selaction`, built with `make`. The program writes `<filename>.out` in the directory you run it from; `selaction` below stands for the path to `build/selaction`.

### Example 1: Single trait, single stage

```bash
selaction
# Select: 1 (single stage)
# Input: filename example1, 1 trait, h² 0.3, 10 sires, 100 dams, own performance
```

### Example 2: Two traits, two stages

```bash
selaction
# Select: 2 (two stage)
# Trait 1: h² = 0.4, economic value = 1.0
# Trait 2: h² = 0.2, economic value = 0.5
# Genetic correlation: 0.3
# Stage 1: own performance; stage 2: progeny group
```

### Example 3: Overlapping generations

```bash
selaction
# Select: o (overlapping generations)
# filename overlap1, 1 trait, 3 age classes
```

### Example 4: Re-running a saved input

A saved `.in` file can be replayed. The program also opens `<filename>.in` by name, so run it in a directory holding the file under the name given on its "filenames" line:

```bash
mkdir run && cd run
cp ../tests/fixtures/test1.in .
../build/selaction < test1.in        # writes test1.out here
```

### Example 5: Worked example from the GUI version

`examples/output_discrete_1_stage/` has a complete 3-trait, single-stage worked example from the original Windows GUI: screenshots, the input file and the output file.

## Testing

```bash
# from the top of the repository
make test
```

`make test` builds `build/selaction` if needed and runs `tests/run_tests.sh build` and `tests/run_error_tests.sh build`. To test another build directory, run either script with `<dir>`.

- **What the tests check:** each of the 7 test inputs in `tests/fixtures/` is run and its report compared byte for byte with a stored copy. Together they cover 1-, 2- and 3-stage selection, BLUP, the group information sources, and overlapping generations with and without groups.
- **Error cases:** the 6 inputs in `tests/errors/` must make the program stop with exit code 2 and the right message (over-long, spaced or duplicate names).
- **More detail:** see [`tests/README.md`](tests/README.md) for the format and how to add a test.
- **Limitation:** these tests detect *changes* in results, not whether results are *correct*. Every stored output was produced by SelAction itself. [`plans/test-hardening.md`](plans/test-hardening.md) adds:
  - checks against independently computed answers
  - unit tests of the maths routines
  - property tests
  - automated builds

## Known Issues

- **Open modelling questions.** Several points of the model are under review with the original authors. They are written up with evidence in [`correspondence/2026-10-bijma-dekkers/SelAction_open_questions.pdf`](correspondence/2026-10-bijma-dekkers/SelAction_open_questions.pdf):
  - the genetic lag between age classes
  - the family-structure correction under overlapping generations
  - the 0.93 cap on stage correlations and r₁₃|₂ in three-stage selection
  - half-sib information when each sire has one dam
  - the switch in the inbreeding correction at 20 sires

  The code still follows the original model on these points until they are answered.
- **Older copies give wrong overlapping-generation results.** The earlier Linux fork (removed from this repository, still in the git history) can select the wrong number of parents (e.g. 67.5 sires instead of 10) and uses a wrong generation interval. Both are fixed in `fortran/`; use only that.
- **Some mistakes in the input are not caught:**
  - An inconsistent (non-positive-definite) set of correlations is reported only at the end of the report (`** incoherent genetic parameters detected`), and the results are still printed.
  - More than 20 groups of one type, or an invalid information-source code, are not rejected.
  - The exit code is 0 for these. Only a bad name (see below) stops the run with exit code 2.

  Names are checked: a file or trait name longer than 8 characters, containing a space, or (for traits) used twice now stops the run with `-error-30-` instead of being silently cut.

  Stricter checks are planned ([`plans/modernize-inputs-and-outputs.md`](plans/modernize-inputs-and-outputs.md)).
- **`selinbreeding.f90` removed from `fortran/` (2026-10-05).** It held `MODULE Inbreeding`, an unused older copy of `dFmtblup`; the live copy is in `selroutines.f90`, so results did not change. The file is still in `fortran_orig/`, where its unrestricted `USE selroutines` imports a second `dFmtblup` and is why the original `mssel`/`msseld` won't build.
- **Module not found / build order:** `make` handles this. By hand, compile `seltools.f90` → `selparameters.f90` → `selroutines.f90` → `selovlp.f90`/`seldiscrete.f90` → the main program, in that order. The main program must always come last.

## Troubleshooting

### Compilation errors

**Module not found:**
```
Fatal Error: Cannot open module file 'seltools.mod'
```
**Solution:** Build with `make`, which compiles in dependency order. By hand, use the order shown in [Installation and Compilation](#installation-and-compilation).

**Long line errors (only against `fortran_orig/`):**
```
Error: Line truncated
```
**Solution:** Add `-ffixed-line-length-none`, or use `fortran/`.

### Runtime errors and messages

**Singular matrix:**
```
 -error-10- : matrix is singular
```
**Solution:** Check the genetic parameters for consistency. Correlation matrices must be positive definite, and no two information sources may carry the same information.

**Incoherent parameters (printed at the end of the report):**
```
 ** incoherent genetic parameters detected
```
**Solution:** The correlation matrices are not positive definite. Treat the results above it as invalid and correct the correlations.

**Heritability out of range:**
```
 wrong input, heritability must be higher than 0!
```
**Solution:** Enter a heritability strictly between 0 and 1. The program asks again.

**Bad file or trait name:**
```
 -error-30- input error: filename 'scenario_A' is 10 characters; the maximum is 8
```
**Solution:** Use a name of at most 8 characters with no spaces, and give every trait a different name. The run stops with exit code 2; if the report was already started, it ends with this message and "run stopped; this report is incomplete".

**Proportion selected out of range:**
```
 -error-20- : P-value out of bounds
```
**Solution:** Proportions selected must lie between 0 and 1.

### Getting help

1. Compare your input with a working one (`tests/fixtures/*.in`).
2. Read the `.out` report to the end for warnings.
3. Check that the genetic parameters are biologically reasonable.
4. Start from a small example before building a complex scenario.

## Roadmap

1. **Test hardening, part 1** ([`plans/test-hardening.md`](plans/test-hardening.md), T0–T2):
   - remove the unused `selinbreeding.f90` (done 2026-10-05)
   - test tooling: a scripted strict debug build, coverage measurement, tolerant output comparison
   - test inputs for every untested feature and input path
   - automated builds on macOS and Linux (and Windows), possibly here already
2. **Scenario input and structured output** ([`plans/modernize-inputs-and-outputs.md`](plans/modernize-inputs-and-outputs.md), Phases 1–3 first). This changes no equations, and every stored report must stay byte-identical:
   - YAML scenario folders, including sweeps over inputs
   - full validation before running, and clear errors with exit codes
   - full-precision CSV results
3. **Test hardening, part 2** (T3–T5, T7), built on the CSV results and sweeps:
   - unit tests of the maths routines
   - correctness tests against independently computed answers
   - property tests
   - a coverage gate
4. **Answers to the open modelling questions** from the original authors, then any model changes they lead to. Each change will be documented with before-and-after results.
5. **Ready-made downloads** ([`plans/releases.md`](plans/releases.md)): tested binaries for macOS (Intel and Apple Silicon), Linux and Windows on GitHub Releases, so people can run SelAction without compiling it.
6. **An R implementation** (`SelActionR`), validated against this code.

## Related Project: SelActionR

An R package reimplementation, `SelActionR`, is being developed as a separate project (not included in this repository). It will provide a modern, scriptable interface to the same selection index theory, with an eventual CRAN release as the goal. This repository is the reference implementation and validation source for that work.

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See [`LICENSE`](LICENSE) for the full text.

The original Fortran code was written by Marc J.M. Rutten and Piter Bijma at Wageningen University. Piter Bijma gave direct permission (by email) to release this repository, including the original code, under GPLv3.

> [!CAUTION]
> **NO WARRANTY.** This software is provided **as-is**, without warranty of any kind, express or
> implied. The authors accept **no liability** for any damages or losses arising from its use.

## References

### Primary References

1. **Rutten, M.J.M. and Bijma, P. (2000)**. SelAction: Multi-trait Selection Index Software. Animal Breeding and Genetics Group, Wageningen University. *(Internal technical documentation; no stable public link found. See the [Citation](#citation) section above for the peer-reviewed companion paper.)*
2. **Smith, H.F. (1936)**. A discriminant function for plant selection. Annals of Eugenics, 7, 240-250. [https://doi.org/10.1111/j.1469-1809.1936.tb02143.x](https://doi.org/10.1111/j.1469-1809.1936.tb02143.x)
3. **Hazel, L.N. (1943)**. The genetic basis for constructing selection indexes. Genetics, 28, 476-490. [https://doi.org/10.1093/genetics/28.6.476](https://doi.org/10.1093/genetics/28.6.476)

### Inbreeding Theory

4. **Bijma, P. and Woolliams, J.A. (2000)**. Prediction of rates of inbreeding in populations selected on best linear unbiased prediction of breeding value. Genetics, 156, 361-373. [https://doi.org/10.1093/genetics/156.1.361](https://doi.org/10.1093/genetics/156.1.361)
5. **Wray, N.R., Woolliams, J.A. and Thompson, R. (1990)**. Methods for predicting rates of inbreeding in selected populations. Theoretical and Applied Genetics, 80, 503-512. [https://doi.org/10.1007/BF00226752](https://doi.org/10.1007/BF00226752)

### Selection Theory

6. **Bulmer, M.G. (1971)**. The effect of selection on genetic variability. American Naturalist, 105, 201-211. [https://doi.org/10.1086/282718](https://doi.org/10.1086/282718)
7. **Tallis, G.M. (1961)**. The moment generating function of the truncated multi-normal distribution. Journal of the Royal Statistical Society B, 23, 223-229. [https://doi.org/10.1111/j.2517-6161.1961.tb00408.x](https://doi.org/10.1111/j.2517-6161.1961.tb00408.x)
8. **Rendel, J.M. and Robertson, A. (1950)**. Estimation of genetic gain in milk yield by selection in a closed herd of dairy cattle. Journal of Genetics, 50, 1-8. [https://doi.org/10.1007/BF02986789](https://doi.org/10.1007/BF02986789)
9. **Rawlings, J.O. (1976)**. Order statistics for a special class of unequally correlated multinormal variates. Biometrics, 32, 875-887. [https://doi.org/10.2307/2529271](https://doi.org/10.2307/2529271)
10. **Meuwissen, T.H.E. (1991)**. Reduction of selection differentials in finite populations with a nested full-half sib family structure. Biometrics, 47, 195. [https://doi.org/10.2307/2532506](https://doi.org/10.2307/2532506)
11. **Lynch, M. and Walsh, B. (1998)**. Genetics and Analysis of Quantitative Traits. Sinauer Associates, Sunderland, MA. [https://global.oup.com/academic/product/genetics-and-analysis-of-quantitative-traits-9780878934812](https://global.oup.com/academic/product/genetics-and-analysis-of-quantitative-traits-9780878934812)

### Implementation Details

12. **Press, W.H., Teukolsky, S.A., Vetterling, W.T. and Flannery, B.P. (1996)**. Numerical Recipes in Fortran 90: The Art of Parallel Scientific Computing (2nd ed., Vol. 2). Cambridge University Press. [https://dl.acm.org/doi/10.5555/232468](https://dl.acm.org/doi/10.5555/232468)

---

**SelAction version 1.2 (2026)**: updated by Austin Putz and Jack Dekkers, Iowa State University. Original version 1.1 (2000) by Marc J.M. Rutten and Piter Bijma, Wageningen University.
