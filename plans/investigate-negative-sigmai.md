# Investigate: negative `sigmai` causing `sqrt` trap in `selection_index`

## Status

Not started. Discovered while verifying the unconfigured-group-type
matrix-block fix (`plans/fix-unconfigured-group-type-matrix-blocks.md`,
implemented). That fix's SNaN/FPE-trap verification removed an earlier
crash, which let execution reach further into `selection_index` than any
previous run — and revealed this next, unrelated crash. Confirmed
unrelated to the group-block fix: `locfsgroups`/`lochsgroups`/
`locprogroups` are threaded through correctly at the trap site.

## Context

`selection_index` (`fortran_linux/selroutines.f90:1800`) computes:

```fortran
locrih=(sqrt(sigmai/sigmah))
```

For the `blup1` and `advgrp` fixtures, `sigmai` comes out **negative**
(confirmed via gdb at the trap: `sigmai=-84.9`, `sigmah=782.8` for
`blup1`; `sigmai=-80.6`, `sigmah=782.8` for `advgrp`, second call in
`sel1s` — the dam-side `initindsel="d"` call). `sqrt` of a negative ratio
is `NaN`, which traps under `-ffpe-trap=invalid` (part of this project's
standard debug-verification flags: `-finit-real=snan
-finit-integer=-999999999 -ffpe-trap=invalid,zero,overflow -fbacktrace`).

`sigmai` is meant to be a variance (the selection index's own variance,
`sigmai=temp2sigmai(1,1)` from `matmul(temp1sigmai,locb)` a few lines
above at `selroutines.f90:1786-1787`) — variances shouldn't legitimately
go negative. The likely cause is a numerical-precision artifact: a matrix
that's supposed to be positive semi-definite (`locinvp`, or whatever feeds
`temp1sigmai`) picking up a small negative eigenvalue from floating-point
rounding during inversion, especially plausible for `blup1`/`advgrp`'s
information-source mix (BLUP breeding values + half-sib group, no own
performance) which may be closer to a near-singular/degenerate case than
`test1`'s richer source list.

**Confirmed harmless for actual output today**: both `blup1` and `advgrp`
pass byte-for-byte in the normal (non-trapping) `-g -O2 -Wall` build — in
that build, `sqrt` of a negative number silently returns `NaN` without
crashing, but apparently `locrih`'s `NaN` never propagates into any
displayed value for either fixture (or does, but rounds/displays in a way
that happens not to show `NaN` — needs to be confirmed, see step 2 below).
This is a strict-FPE-trap-only issue, not a known functional defect, but
warrants investigation since a genuinely negative variance is a red flag
regardless of whether it currently surfaces in output.

## Investigation steps (not yet done)

1. Trace `temp1sigmai`/`sigmai` back to its inputs (`locb`, `realc`,
   `locev` — read `selection_index` from the top to find exactly which
   matrix is inverted/multiplied to produce it) and identify which
   upstream quantity is going wrong.
2. Confirm whether `locrih`'s `NaN` (in the non-trapping build) actually
   reaches displayed output anywhere for `blup1`/`advgrp`, or whether it's
   computed and silently discarded — if it's discarded, this is lower
   priority; if it silently corrupts a displayed value that happens not to
   render as literal "NaN" text, that's a real correctness bug hiding
   behind `tests/run_tests.sh`'s current 10/10 pass.
3. Determine whether this is a genuine near-singularity in the underlying
   statistics (e.g. `blup1`/`advgrp`'s reduced information-source set
   makes the inverted matrix genuinely close to singular) versus an actual
   arithmetic bug (sign error, wrong matrix used, etc.) — check whether
   `test1`/`test2s`/`test3s` (which don't trap here) have a structurally
   richer source list that just avoids the near-singular region, or
   whether there's something specific to the half-sib-only BLUP pattern.
4. If it's numerical near-singularity: consider whether a small clamp
   (`sigmai=max(sigmai,0.0)` or similar) is defensible, or whether it
   should be left alone since it's a symptom rather than the actual
   problem, and clamping would just mask it.

## Constraints

Same as always: `fortran_orig/` must never be touched. Any fix belongs in
`fortran_linux/` only. `fortran_mac/` out of scope.

## Verification (once a fix is designed)

Rebuild + `tests/run_tests.sh` unchanged pass; SNaN/FPE-trap rebuild shows
zero traps for `blup1`/`advgrp` (the two fixtures currently affected);
confirm no other fixture regresses.
