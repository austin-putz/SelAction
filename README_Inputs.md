# SelAction Input File Mapping Guide

This document decodes the input file saved by the original Windows GUI version of SelAction, using the worked example in `examples/output_discrete_1_stage/`, and relates its fields to the questions the Fortran program asks.

> **Note (2026-10-05).** This guide decodes the input file saved by the
> original **Windows GUI** (`examples/output_discrete_1_stage/SelAction_Inputs.txt`).
> That format is not the one the Fortran program reads, and several of its
> fields are not yet identified (marked below).
>
> The command-line program (`build/selaction`, built with `make`) reads one answer per
> prompt. [`tests/fixtures/test1.in`](tests/fixtures/test1.in) is a
> complete example with every answer labelled. The input codes and rules
> are summarised under "Input Parameters" in [`README.md`](README.md):
> trait use `i`/`h`/`b`/`n`, and information sources 1, 2, 4–23, 24–43 and
> 64–83, ending with `-1`.

## Example Data Mapping

Based on the file `examples/output_discrete_1_stage/SelAction_Inputs.txt` (checked against `SelAction_Output.txt` in the same folder, whose datafile name is "Test Run 1"), the lines map as follows. The GUI file has no file-name line.

### Traits
```
Line 1: 3                         # Number of traits
Lines 2-4: eADG, ADG, FCR         # Trait names (the output lists these as TRAITS USED)
```

### Trait Parameters (for 3 traits)
```
Line 5: 20.000 100.000 0.500      # Phenotypic variances for traits 1, 2, 3
Line 6: 0.250 0.300 0.200         # Heritabilities (h²) for traits 1, 2, 3
Line 7: 0.050 0.050 0.050         # Common environmental effects (c²) for traits 1, 2, 3
Line 8: 0.000 5.000 -27.000       # Economic values (0 = not in the breeding goal)
```

### Selection Parameters
```
Line 9:  10.000                   # Number of selected sires
Line 10: 200.000                  # Number of selected dams
Line 11: 5.000                    # Male selection candidates per dam
Line 12: 5.000                    # Female selection candidates per dam
Line 13: 0.010                    # Proportion selected sires
Line 14: 0.200                    # Proportion selected dams
```

### Groups
```
Line 15: 1                        # Number of full-sib groups
Line 16: 9.000                    # Animals in full-sib group 1
Line 17: 1                        # Number of half-sib groups
Line 18: 200.000 190.000          # Half-sib group 1: dams, and animals
Line 19: 0                        # Number of progeny groups
Line 20: n                        # Not identified (possibly "different indices for sires and dams")
```

The output confirms the groups: "full-sib group 1 with 9.0 animals" and "half-sib group 1 with 200.0 dams, producing 190.0 animals".

### Information Sources (lines 21-22)
Each line holds 1,680 numbers: a block of 84 positions for each of up to 20 traits, with the codes for traits 1-3 at positions 1, 85 and 169 and zeros everywhere else; line 21 and line 22 are probably the sire and the dam index. The codes:
- 1 = own performance
- 2 = BLUP breeding values
- 4 = full-sib group 1
- 24 = half-sib group 1
- -1 = end of sequence

Pattern: `1 2 4 24 -1` for each trait indicates:
- Own performance available
- BLUP breeding values available
- Full-sib group 1 available
- Half-sib group 1 available
- Followed by zeros (no additional sources)

### Correlation Matrices (Lines 23-25)
```
Line 23: 1.000 0.250 0.100 0.250 1.000 -0.700 0.100 -0.700 1.000
         # Phenotypic correlations (3x3 symmetric matrix)
         # Trait 1-1: 1.000, Trait 1-2: 0.250, Trait 1-3: 0.100
         # Trait 2-1: 0.250, Trait 2-2: 1.000, Trait 2-3: -0.700
         # Trait 3-1: 0.100, Trait 3-2: -0.700, Trait 3-3: 1.000

Line 24: 1.000 0.200 0.150 0.200 1.000 -0.500 0.150 -0.500 1.000
         # Genetic correlations (3x3 symmetric matrix)

Line 25: 1.000 0.050 0.050 0.050 1.000 0.050 0.050 0.050 1.000
         # Common environmental correlations (3x3 symmetric matrix)
```

## Interactive vs File Input

The sel1s subroutine normally runs interactively, prompting for each input. However, you can redirect input from a file:

### To Run Interactively:
```bash
build/selaction        # from the top of the repository, after `make`
# Choose option "1" for single-stage selection
# Answer prompts one by one
```

### To Run with File Input:
```bash
# Create input file with responses in order
echo "1" > input.txt          # Choose single-stage selection
echo "eADG" >> input.txt      # Filename
echo "3" >> input.txt         # Number of traits
# ... continue with all parameters in sequence
build/selaction < input.txt
```

## Key Validation Rules

1. **Heritabilities**: Must be 0 < h² < 1
2. **Common Environmental Effects**: Must be 0 ≤ c² < 1, and h² + c² < 1
3. **Correlations**: Must be -1 < r < 1
4. **Economic Values**: Cannot be zero for breeding goal traits
5. **Information Sources**: Each sequence must end with -1
6. **Trait Usage**: At least one trait must be in breeding goal ("h" or "b")

## Tips for Creating Input Files

1. **Plan your trait structure first**: Decide which traits are in index only, breeding goal only, or both
2. **Check parameter consistency**: Ensure heritabilities and correlations are biologically reasonable
3. **Validate correlation matrices**: Must be positive definite (eigenvalues > 0)
4. **Test with small examples**: Start with 1-2 traits to understand the format
5. **Save working examples**: Keep successful input files as templates

## Common Issues

- **Singular matrices**: Usually due to inconsistent correlation values
- **Invalid heritabilities**: Check h² + c² < 1 constraint
- **Missing -1 terminators**: Information source lists must end with -1
- **Wrong matrix dimensions**: Correlation matrices must match number of traits