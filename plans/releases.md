# Plan: prebuilt downloads on GitHub Releases

## Status

**Not started (written 2026-10-05).** This plan records the approach
only. Its prerequisite, T6's CI workflow (`.github/workflows/tests.yml`),
exists since 2026-10-06 and already builds and tests on Linux, macOS
Apple Silicon and Windows (MSYS2), so this can start any time.

## Goal

Someone who doesn't program can download **one file** for their
computer and run SelAction, with no compiler and no `make`. The test case
is Jack: an Apple Silicon (M-series) MacBook and no programming
background.

Every download must be a build that passed the regression tests on that
platform, for a known version of the source.

## How it works

1. A version tag is pushed (e.g. `v1.2.0`). The tag must match the
   version in the banner (`intro` in `fortran/selroutines.f90`).
2. A GitHub Actions workflow (`.github/workflows/release.yml`) builds
   `selaction` on each platform with `make`, using the release flags
   below.
3. On each platform it runs the tests **before** uploading anything:
   `make test` (byte for byte) where CI shows the stored outputs are
   reproduced exactly (Linux, Windows), and `tests/run_tests.sh
   --tolerant` plus the error cases on Apple Silicon, where last digits
   differ. Any failure
   stops the release.
4. The binaries and a `SHA256SUMS` file are attached to a GitHub Release.
   The release notes are the matching `NEWS.md` section.

## Platforms and file names

| File | Built on | For |
|---|---|---|
| `selaction-macos` (universal) | `macos-14` (arm64) + `macos-13` (x86_64), joined with `lipo` | any Mac (Intel or M-series) |
| `selaction-linux-x86_64` | `ubuntu-*` (or an older-glibc container) | Linux |
| `selaction-windows-x86_64.exe` | `windows-latest` with MSYS2 (UCRT64 gfortran) | Windows 10/11 |

One universal macOS file is easiest for non-programmers: there is no
"which Mac do I have?" question. Separate `-arm64`/`-x86_64` files are
the fallback if `lipo` causes problems.

## Self-contained binaries

The downloads must run on a machine without gfortran installed:

- **macOS:** `-static-libgfortran -static-libgcc -static-libquadmath`
  (macOS can't link fully static). Check with `otool -L` that only
  system libraries remain.
- **Windows:** `-static`. Check with `ntldd` that no MinGW DLLs are needed.
- **Linux:** `-static`, or build on an old glibc so the binary runs on
  older distributions. Check with `ldd`.

These go in as a Makefile target or variable (e.g. `make release`) so
the CI and a local build use the same command. The normal `make` stays
unchanged, so the golden fixtures are still built with `-g -O2 -Wall`.
Release builds must also pass the tests, with the tolerant comparison if
static linking changes anything in the last digit.

## macOS Gatekeeper

macOS blocks unsigned programs downloaded from a browser ("cannot be
opened because the developer cannot be verified").

- **Short term (free):** document the workaround on the getting-started
  page. Either run `xattr -d com.apple.quarantine selaction-macos` once
  in Terminal, or allow it under System Settings → Privacy & Security.
- **Proper fix:** sign and notarize with an Apple Developer ID ($99 a
  year). The workflow signs with `codesign` and submits with
  `notarytool`. Then the file just runs. This is Austin's decision.

## Getting started without programming

A short page (`docs/getting-started.md`, linked from the top of
`README.md` and from every release). Screenshots where they help.

1. Go to the Releases page and download the file for your computer.
2. Open Terminal (macOS/Linux) or PowerShell (Windows).
3. macOS/Linux only: make it runnable with
   `chmod +x selaction-macos`, plus the Gatekeeper step above.
4. Make a folder, put an example input in it (e.g. `test1.in` from
   `tests/fixtures/`, also attached to the release), and run it there:
   `./selaction-macos < test1.in`.
5. The report appears as `test1.out` in the same folder.
6. To run your own scheme, run it without `< file` and answer the prompts.
   Or, once `plans/modernize-inputs-and-outputs.md` is done, edit a YAML
   scenario instead.

## Later options

- **Homebrew tap** (`brew install austin-putz/tap/selaction`) for Mac
  users who already use Homebrew.
- **The R driver** from `plans/modernize-inputs-and-outputs.md` could
  download the right release binary itself, so R users never handle the
  file at all.
- **Example inputs bundle:** a zip of `tests/fixtures/*.in` and
  `examples/` attached to each release.

## Open decisions

1. Apple signing and notarization: yes (paid) or the free workaround.
2. One universal macOS binary, or separate Intel and M-series files.
3. Whether Windows ships in the first release. (CI tests it since
   2026-10-06: byte-identical results apart from line endings.)
4. The first release version: `v1.2.0` now, or wait until the open
   modelling questions are answered.

## Acceptance

- Pushing a test tag (e.g. `v1.2.0-rc1`) produces a release with every
  file. Each one is downloaded fresh on a clean machine and runs
  `test1.in`, giving the expected `test1.out`.
- Jack (or someone equally non-technical) follows the getting-started
  page on an M-series Mac without help.
