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

## Adding a new fixture

There is currently one fixture (`test1`, 3-trait discrete 1-stage). The
matrix should grow to cover 2-stage, 3-stage, overlapping generations, and
the BLUP inbreeding path, but new fixtures must come from actually running a
real binary with a valid, non-singular parameter set - do not hand-write
expected output.

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
