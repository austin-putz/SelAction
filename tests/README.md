# Regression tests

Canonical, platform-agnostic input/output fixtures for validating every
implementation of SelAction against each other: `fortran_linux`, `fortran_mac`,
a future `fortran_windows`, and an eventual C++ port. Fixtures live here, not
inside a platform directory, so there is exactly one source of truth for
"what should this input produce" - every platform's runner points back at
this same directory instead of carrying its own copy that can drift out of
sync.

This is also the intended validation reference for `SelActionR` (a separate
repository) - its test suite should assert against the same `.in`/`.out`
pairs.

## Layout

```
tests/
  fixtures/
    manifest.txt   maps each fixture to the binaries it's valid input for
    <name>.in       input fed to the program via stdin redirection
    <name>.out      expected output, byte-for-byte
  run_tests.sh
```

## Running

```bash
tests/run_tests.sh                # against fortran_linux (default)
tests/run_tests.sh fortran_mac    # against another platform dir
```

Binaries listed in `manifest.txt` that aren't built in the target platform
directory are skipped (not failed), so the suite runs against partially-built
platforms like `fortran_mac`.

## How a fixture is invoked

`mssel`/`msseld`/`msselo` are interactive programs: they read prompts from
stdin, and separately re-open a file by name (derived from the "filenames"
prompt answer) to read the bulk of the input and to write output. So a
fixture named `test1` is run as:

```bash
cp tests/fixtures/test1.in ./          # must be present under this exact name
./mssel < test1.in                      # produces ./test1.out
```

`run_tests.sh` does this in a scratch temp dir per run and diffs the result
against `tests/fixtures/test1.out`.

## Filename length constraint

**Fixture base names must be 8 characters or fewer.** The "filenames" field
inside a `.in` file is read into `fnam`, declared `character (len=8)` in
`selparameters.f90`. A longer name is silently truncated by the Fortran
list-directed read, so the program ends up trying to open a file that
doesn't match the fixture's actual filename - the run fails to find its own
input. Keep both the fixture's file stem and the "filenames" line *inside*
the `.in` file itself under 8 characters and identical to each other.

## manifest.txt

Each fixture must declare which binaries it's valid for. The three programs
have different interactive prompt sequences:

- `mssel` — asks `1/2/3 stage selection, or overlapping generations? (1/2/3/o)`
- `msseld` — asks the same `1/2/3` question but rejects `o`
- `msselo` — only accepts `o`; feeding it a `1/2/3` fixture makes it
  re-prompt against an exhausted stdin stream rather than failing cleanly

Running a fixture against a binary it wasn't written for doesn't error
usefully - confirm the fixture's stage-selection answer matches the binary
before adding a manifest entry.

## Numerical precision and the reference toolchain

These fixtures are captured by actually running a real binary and diffing
byte-for-byte, so they're sensitive to the exact `gfortran` build that
produced them. The canonical reference toolchain used to capture the
current fixtures is:

```
GNU Fortran (Ubuntu 15.2.0-16ubuntu1) 15.2.0
```

For most fixtures this doesn't matter - the underlying computation is well
away from any rounding boundary. But a fixture can legitimately contain a
coefficient that's genuinely close to zero (e.g. `blup1`'s BLUP index weight
for a non-breeding-goal trait, after 25 rounds of `sel1s`'s iterative
BLUP-equilibrium loop) - right at the display precision limit. For values
like that, ordinary compiler-version-level floating-point differences
(instruction scheduling, FMA contraction, vectorization, libm rounding) can
flip the last displayed digit or the sign of a near-zero value with no bug
involved at all. If `run_tests.sh` fails with a diff isolated to a single
near-zero or last-digit value, don't assume it's either "definitely a
regression" or "definitely safe to regenerate" - check whether the affected
value is genuinely near a rounding boundary (as `blup1`'s was) before doing
either.

## Resolved: unconfigured group-type matrix blocks

`selroutines.f90`'s `selection_index` and `intra_sd` build their
`matp`/`matrhs`/`matrfs` "maximum matrix" blocks by looping `i=1,20`/
`j=1,20` for full-sib, half-sib, and progeny groups. A prior fix
zero-initialized the six group arrays (`fsgroupsoff`/`hsgroupsoff`/
`hsgroupsdams`/`proggroupsdams`/`proggroupsoffs`/`proggroupsoffd`, fixed
`real, dimension(20)` in `selparameters.f90`), closing an
uninitialized-read bug for indices beyond a *partially* configured group
count. That still left every division by those arrays running
unconditionally even when a group *type* wasn't configured at all (or an
index exceeded its actual count within a configured type), which is
mathematically undefined (`x/0.0` or `0.0/0.0`) and traps under
`-ffpe-trap=invalid,zero,overflow`.

Both subroutines now take `fsgroups`/`hsgroups`/`proggroups` as arguments
(matching the pattern `info_sources` already used) and guard every
division statement so it only executes when the specific group index is
actually configured (`i.le.locfsgroups` etc., not just "some groups of
this type exist" - a partially-configured count needs the same guard as a
fully-unconfigured one). Verified via a `-finit-real=snan
-finit-integer=-999999999 -ffpe-trap=invalid,zero,overflow -fbacktrace`
debug build: `test1`/`test2s`/`test3s` now run without a single trap
(previously traps at `selroutines.f90:1539` and `:1571`). See `advgrp` in
`manifest.txt` for a fixture built specifically to exercise the
previously-never-tested "progeny groups configured and selected" path
alongside a fully-unconfigured full-sib type.

`blup1` still traps under the strict FPE build, but at an unrelated line
(`selroutines.f90:1800`, `sqrt` of a negative `sigmai` variance component)
that this fix does not touch - see "Known residual issue" below.

## Known residual issue: negative `sigmai` under strict FPE traps

`selection_index` computes `locrih=(sqrt(sigmai/sigmah))` at
`selroutines.f90:1800`. For `blup1` (and `advgrp`, which shares `blup1`'s
half-sib-only info-source pattern), `sigmai` comes out **negative**
(confirmed via debugger: `sigmai=-84.9`, `sigmah=782.8`), so `sqrt` of a
negative ratio traps under `-ffpe-trap=invalid`. This is unrelated to the
group-matrix-block fix above - `locfsgroups`/`lochsgroups`/`locprogroups`
are threaded through correctly, and this line was simply unreachable
before today's fix removed the earlier crash blocking execution from ever
getting this far. It's confirmed harmless for actual output: both `blup1`
and `advgrp` pass byte-for-byte in the normal (non-trapping) `-g -O2
-Wall` build. Likely a numerical-precision artifact of a near-singular
matrix inversion elsewhere in the routine (a variance component shouldn't
legitimately go negative). Not yet investigated further - out of scope for
the group-matrix-block fix.

## Adding a new fixture

There are currently 5 fixtures: `test1` (3-trait discrete 1-stage),
`test2s` (discrete 2-stage), `test3s` (discrete 3-stage), `blup1`
(discrete 1-stage isolating the BLUP-only inbreeding path), and `advgrp`
(discrete 1-stage isolating the unconfigured/partially-configured
group-type matrix-block guards, including progeny groups). Overlapping
generations (`ovlp`) has no fixture yet. New fixtures must come from
actually running a real binary with a valid, non-singular parameter set -
do not hand-write expected output.

1. Build the binaries in `fortran_linux/` (see root `README.md`).
2. Prepare a `.in` file (an existing one is the easiest starting template),
   keeping the base name ≤ 8 characters and matching the "filenames" line
   inside it.
3. Run it for real: `cd` into a scratch dir, `./mssel < name.in`, confirm it
   completes without error (a singular/non-positive-definite correlation
   matrix will fail here - that's expected feedback, not a bug).
4. Copy the resulting `name.in`/`name.out` pair into `tests/fixtures/`.
5. Add a line to `manifest.txt` naming which binaries it's valid for and
   what it exercises.
6. Run `tests/run_tests.sh` and confirm it passes.
