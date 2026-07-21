# SelAction Input File Mapping Guide

This document explains how to map your breeding program parameters into the input format required by the sel1s subroutine in SelAction.

## Example Data Mapping

Based on the file `output_discrete_1_stage/SelAction_Inputs.txt`, here's how the data maps to program inputs:

### Basic Setup
```
Line 1: 3              # Number of traits
Line 2: eADG           # Filename (creates eADG.in and eADG.out)
```

### Trait Information
```
Lines 3-5: ADG, FCR    # Trait names (first trait "eADG" used for breeding goal)
```

### Trait Parameters (for 3 traits)
```
Line 6: 20.000 100.000 0.500    # Phenotypic variances for traits 1, 2, 3
Line 7: 0.250 0.300 0.200       # Heritabilities (h²) for traits 1, 2, 3  
Line 8: 0.050 0.050 0.050       # Common environmental effects (c²) for traits 1, 2, 3
Line 9: 0.000 5.000 -27.000     # Economic values for traits 1, 2, 3
```

### Selection Parameters
```
Line 10: 10.000         # Number of selected sires
Line 11: 200.000        # Number of selected dams
Line 12: 5.000          # Male selection candidates per dam
Line 13: 5.000          # Female selection candidates per dam
Line 14: 0.010          # Proportion selected sires
Line 15: 0.200          # Proportion selected dams
```

### Configuration Options
```
Line 16: 1              # Use different indices for sires/dams? (1=yes, 0=no)
Line 17: 9.000          # (Purpose unclear from current analysis)
Line 18: 1              # (Purpose unclear from current analysis)
Line 19: 200.000 190.000 # (Additional parameters)
Line 20: 0              # (Boolean flag)
Line 21: n              # Use common environmental effects? (y/n)
```

### Information Sources (Large arrays on lines 21-22)
The long arrays specify which information sources are available for each trait:
- 1 = own performance
- 2 = BLUP breeding values  
- 4 = full-sib group 1
- 24 = half-sib group 1
- -1 = end of sequence

Pattern: `1 2 4 24 -1` repeated for each trait indicates:
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
./mssel
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
./mssel < input.txt
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