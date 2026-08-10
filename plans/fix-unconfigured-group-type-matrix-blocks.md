# Fix: unconfigured group-type matrix blocks in `selection_index` / `intra_sd`

## Status

**Implemented.** `selection_index` and `intra_sd` (`fortran_linux/selroutines.f90`)
now take `fsgroups`/`hsgroups`/`proggroups` as arguments and guard every
division by the six group arrays with `i.le.locXgroups` (tighter than the
`locXgroups.gt.0` this doc originally proposed — needed to also cover the
*partially*-configured case, not just the fully-unconfigured one; see
`tests/README.md` for why). All 19 call sites across `seldiscrete.f90`/
`selovlp.f90` updated. Verified via a `-finit-real=snan -ffpe-trap=invalid,
zero,overflow` debug build: zero traps for `test1`/`test2s`/`test3s`
(previously trapped at `selroutines.f90:1539`/`:1571`). A new fixture,
`advgrp`, was added to exercise the previously-untested progeny-groups
path. `blup1` still traps under the strict build, but at an unrelated line
(`sqrt` of a negative `sigmai`) exposed by this fix, not caused by it — see
`plans/investigate-negative-sigmai.md` for that follow-up.

## Context

`fsgroupsoff`, `hsgroupsoff`, `hsgroupsdams`, `proggroupsdams`,
`proggroupsoffs`, `proggroupsoffd` (fixed `real, dimension(20)` in
`fortran_linux/selparameters.f90:18-19`) are populated only for the
actually-configured number of full-sib/half-sib/progeny groups (via read
loops in `sel1s`/`sel2s`/`sel3s` in `seldiscrete.f90` and `ovlp` in
`selovlp.f90`). The previous fix zero-initializes all six arrays before
those read loops, closing an uninitialized-*read* bug for indices beyond a
*partially* configured group count (e.g. 1 half-sib group out of the fixed
20 slots).

What that fix does **not** address: `selection_index` and `intra_sd` (both
in `fortran_linux/selroutines.f90`) build their "maximum matrix" blocks with
loops that unconditionally run `i=1,20` (and `j=1,20`) for full-sib,
half-sib, and progeny groups **regardless of whether that group type was
configured at all** — not just regardless of the exact count within a used
type. When a group type isn't used (e.g. no progeny groups configured, true
for every current fixture), these loops still divide by the now-correctly-
zero array slots. That's `x/0.0` (→ `Inf`, harmless unless read) when the
numerator is nonzero, but `0.0/0.0` (→ `NaN`, "invalid" FPE) whenever a
numerator term (e.g. `cove(p,q)`, `covapaq(p,q)`) is legitimately zero for
some trait pair — which does happen.

**Confirmed harmless today**: `tests/run_tests.sh` passes 8/8 on the normal
(non-trapping) `-g -O2 -Wall` build, because the corrupted cells correspond
to information-source codes none of the 4 current fixtures select (per
`info_sources` in `selroutines.f90`, confirmed the same way the original
`pheninfo`/`posgcorr` investigation traced consumption paths) — garbage is
computed but never read. This is a latent risk, not a proven live bug: it
would start mattering the moment a fixture (or a real user's input) mixes
group types such that one type is fully unused while another's info-source
codes are selected, or once the `ovlp` fixture (still not built) is added,
since `ovlp` also calls `selection_index`.

## Root cause detail

Confirmed via source inspection and reproduced with a
`-finit-real=snan -finit-integer=-999999999 -ffpe-trap=invalid,zero,overflow`
debug build (see the commit for the first trap; a second, distinct trap at
`selroutines.f90:1615` was found while verifying that fix — that's the one
this plan addresses):

```fortran
! selroutines.f90:1608-1618, inside selection_index — "progeny groups" block
do i=1,20
  do j=1,20
    if (locinitindsel.eq."s") then
      if (i.eq.j) then
        matp(p,q,i+63,j+63)=(0.25*covapaq(p,q))+ &
          & ((0.25*covapaq(p,q))/proggroupsdams(i))+ &
          & (covcprog(p,q)/proggroupsdams(i))+(covaw(p,q)/proggroupsoffs(i))+ &
          & (cove(p,q)/proggroupsoffs(i))
      ...
```

`proggroupsdams(i)`/`proggroupsoffs(i)` are `0.0` for **every** `i` when no
progeny groups are configured at all (`proggroups=0`), so this always
divides by zero here, not just for `i` beyond some partial count.

**Two subroutines are affected**, both in `fortran_linux/selroutines.f90`:

- `selection_index` (`selroutines.f90:1458-2152`) — the shared index-
  construction routine, called from all four entry points. 18 call sites
  total: `seldiscrete.f90` (16, across `sel1s`/`sel2s`/`sel3s`) and
  `selovlp.f90` (2, in `ovlp`). Contains 4 repeated sets of full-sib/
  half-sib/progeny blocks internally (building different matrix regions —
  `matp`, `matrhs`, `matrfs`, and cross-terms).
- `intra_sd` (`selroutines.f90:2726-3065`) — same pattern, same three group
  types. Only 1 call site, from `sel1s` (`seldiscrete.f90:727`), right
  after `selection_index`'s 25-round loop. Not called from `sel2s`/`sel3s`/
  `ovlp` at all.

Neither subroutine currently receives the actual `fsgroups`/`hsgroups`/
`proggroups` counts as arguments — only the fixed-size arrays themselves.

## The fix is precedented in this codebase already

`info_sources` (`selroutines.f90:285-291`) already takes exactly this
shape of argument — `fsgroups,hsgroups,proggroups` alongside the group
arrays — and uses the counts to know which sources are actually available.
This isn't a novel pattern to introduce; it's extending an existing,
working convention to two subroutines that should have had it from the
start.

## Proposed approach

1. Add `locfsgroups, lochsgroups, locprogroups` (matching the `loc`-prefix
   convention `selection_index`/`intra_sd` already use for their other
   dummy arguments) to both subroutines' signatures.
2. Inside each subroutine, wrap each of the "full-sib groups" / "half-sib
   groups" / "progeny groups" comment-delimited blocks (4 of each inside
   `selection_index`, fewer inside `intra_sd` — enumerate exactly by
   re-running `grep -n "! full-sib groups\|! half-sib groups\|! progeny groups"`
   scoped to each subroutine's line range before editing) in
   `if (locfsgroups.gt.0) then ... end if` / `if (lochsgroups.gt.0) then
   ... end if` / `if (locprogroups.gt.0) then ... end if` respectively. Do
   **not** change the inner loop bounds (`i=1,20`/`j=1,20`) — those stay
   as-is for whenever the group type *is* used (that part is already
   correctly handled by the zero-init fix); only skip the block entirely
   when the count is zero. This is the minimal change that closes the
   `0/0` path without touching any formula.
3. Update all 19 call sites (18 for `selection_index`, 1 for `intra_sd`)
   to pass `fsgroups, hsgroups, proggroups` as three additional trailing
   (or wherever matches the new signature position) actual arguments —
   these variables are already in scope at every call site (module-level
   via `use selparameters` in `seldiscrete.f90`; local to `ovlp` in
   `selovlp.f90`).

Only `fortran_linux/selroutines.f90` (signature + guards), and the call
sites in `fortran_linux/seldiscrete.f90` and `fortran_linux/selovlp.f90`,
need to change. `fortran_orig/` must not be touched (per project rules);
`fortran_mac/` is out of scope, consistent with the two prior fixes.

## Verification

1. Rebuild all three binaries, run `tests/run_tests.sh` — confirm all 4
   current fixtures are **byte-for-byte unchanged** (this fix should be a
   pure no-op for every fixture that already passes, since none of them
   currently read the corrupted cells — if any output changes, that's a
   sign the guard is wrong, e.g. skipping a computation that was actually
   being relied upon rather than just skipping dead-cell garbage).
2. Rebuild with `-finit-real=snan -finit-integer=-999999999
   -ffpe-trap=invalid,zero,overflow -fbacktrace` and re-run all 4 fixtures —
   confirm **no traps at all** now (this is the check that was expected,
   and failed, after the narrower fix — this is what should finally make
   it pass).
3. Construct at least one new adversarial input that specifically exercises
   the previously-broken path — e.g. a fixture with a half-sib group
   configured *and* a progeny-group information source selected but zero
   progeny groups declared (or vice versa) — and confirm it runs to
   completion under the SNaN/FPE-trap build without crashing. This is the
   scenario the current fixtures don't cover and the original bug report
   flagged as the actual risk case.
4. Update `tests/README.md`'s "Known residual issue" section to remove it
   (issue closed) or convert it into a short changelog-style note,
   whichever reads better once the fix is in.

## Risks / why this wasn't just done inline

- 19 call sites across two files is a wider blast radius than the two
  previous fixes (each ~1 file, ~10 lines). Worth doing carefully, one
  subroutine at a time, with the SNaN-trap rebuild as a tight feedback loop
  after each call site is updated rather than all-at-once.
- `intra_sd`'s block structure hasn't been read as closely as
  `selection_index`'s yet — confirm its exact full-sib/half-sib/progeny
  block boundaries (comment-delimited, same style) before editing, same
  way `selection_index`'s were mapped for this plan.
- Consider whether `sel2s`/`sel3s` also ever call something equivalent to
  `intra_sd` under a different name (not confirmed either way here) before
  assuming the fix is complete — a repo-wide search for the same six array
  names across all of `fortran_linux/*.f90`, not just `selroutines.f90`,
  is a reasonable first step when this plan is picked up.
