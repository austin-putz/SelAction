# Investigate: `rawl3` log-domain trap under strict FPE flags

## Status

Not started. Discovered while verifying the `sigmai` guard fix
(`plans/investigate-negative-sigmai.md`, implemented). With both
`sqrt(sigmai...)` sites guarded, `blup1`/`advgrp` under the strict
SNaN/FPE-trap build now execute one level further and trap inside
`rawl3` (`fortran_linux/seltools.f90:167-339`) instead.

## Context

`rawl3(p,nw,nfs,nhs,tfs,ths)` is a general selection-differential utility
in `seltools.f90` — **not** specific to the `blup1`/`advgrp`/`sigmai`
path. It's called from 10 sites total: twice in `selroutines.f90`
(`:2177`, `:2503`, both inside `selection_index`) and eight times in
`seldiscrete.f90` (`sel1s`/`sel2s`/`sel3s`, at lines 1971, 1996, 2588,
2591, 3643, 3659, 4304, 4307, 4680, 4683).

The trap backtrace points into `rawl3` via `selroutines.f90:2177`
(`ii=rawl3(pval,noff,neffdams,nsires,corrfs,corrhs)`, immediately after
the two `covariance_update`... actually before it — this call feeds
`ii`, which is then used to compute `locresponse`/`loctotalresponse`, the
site guarded in the `sigmai` fix). `rawl3`'s body contains several
`log(1.-rho...)`-style calls (e.g. `seltools.f90:145`
`ac=(log(sic)-log(sia))/log(1.-rhoc)`, similarly for `rhoc2`/`rhobc`).
`log` of a non-positive argument is undefined and traps under
`-ffpe-trap=invalid`.

`tfs`/`ths` (mapped from `corrfs`/`corrhs` at the call site) are already
clamped to `[-1,1]` before the call
(`selroutines.f90:~2166-2175`, `if (corrhs.lt.-1.0) corrhs=-1.0` etc. —
confirm exact line numbers again when picking this up, they shift as
other fixes land). Despite the clamp, a boundary-adjacent value (plausibly
a residual echo of round 1's transient negative `sigmai`, since `corrfs`/
`corrhs` are computed via division by `sigmai` earlier in the same
routine) can still push one of `rawl3`'s internal `rho...` terms — a
different, derived quantity, not `tfs`/`ths` directly — outside `log`'s
valid domain.

**Confirmed harmless for actual output today**: `blup1`/`advgrp` still
pass byte-for-byte in the normal, non-trapping `-g -O2 -Wall` build.

## Open questions (not yet investigated)

1. Which exact `log()` call inside `rawl3` traps for `blup1`/`advgrp`?
   Instrument or step through with gdb (same technique used for the
   `sigmai` investigation — see `plans/investigate-negative-sigmai.md`
   for the probe-print approach) to pin down the exact line and the
   values of `p`/`nw`/`nfs`/`nhs`/`tfs`/`ths` at the trap.
2. Is this the same round-1-transient pattern as `sigmai` — i.e., does
   `ii` (rawl3's return value) get overwritten by round 2 before ever
   reaching displayed output, the same way `locresponse`/`locrih` do? If
   so, a guard here is similarly safe. Trace `ii`'s downstream usage
   within `selection_index` to confirm before assuming.
3. Or is this a genuine, independent domain-safety gap in `rawl3` itself
   — e.g. `rhoc`/`rhoc2`/`rhobc` can mathematically exceed 1 (making
   `1.-rho... ` negative) for some *legitimate*, non-transient input
   combination, not just the round-1 artifact? Since `rawl3` is called
   from 10 sites with varying inputs (`pval` vs `pvals*pvals2` etc.,
   different `noff`/`nsires`/`neffdams` per call), check whether other
   call sites are also at risk, not just the two feeding this
   investigation.
4. Given `rawl3`'s much broader call surface (10 sites, several call
   patterns) compared to the two `sigmai` sites, a fix here needs more
   care about scope — a single `if (sigmai.ge.0.0)` was sufficient
   upstream because it's a single, well-understood transient; `rawl3`'s
   internal domain constraints (`rhoc<1`, `rhoc2<1`, `rhobc<1`, etc.)
   need to be understood on their own terms before deciding whether a
   guard, a clamp, or something else is appropriate — don't assume the
   `sigmai` fix's shape transfers directly.

## Constraints

Same as always: `fortran_orig/` must never be touched. Any fix belongs in
`fortran_linux/` only. `fortran_mac/` out of scope.

## Verification (once a fix is designed)

Rebuild + `tests/run_tests.sh` unchanged pass (all 5 fixtures byte-
identical); SNaN/FPE-trap rebuild shows zero traps for `blup1`/`advgrp`;
confirm no other fixture regresses; given `rawl3`'s 10 call sites, also
worth a broader sanity pass (e.g. re-run the SNaN/FPE-trap build across
all fixtures once more, not just the two currently affected) since a fix
here touches more surface than the `sigmai` guards did.
