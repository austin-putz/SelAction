#!/usr/bin/env bash
#
# Strict debug build: builds selaction into build/strict with every
# runtime check on, then runs all fixtures and error cases on it.
#
# Usage:
#   make strict
#   tests/tools/strict.sh
#
# The flags trap array bounds errors (-fcheck=all), any use of an unset
# real (-finit-real=snan) and invalid, divide-by-zero or overflowing
# floating-point operations (-ffpe-trap). Unset integers start at a
# large negative value so their use shows up in the output.
#
# -O0 can change the last printed digit (blup1 prints 0.000 instead of
# -0.000), so reports are compared with tests/tools/compare_out.R
# (needs R) rather than byte for byte. Any trap, runtime error or
# non-zero exit is a FAIL. Exits non-zero on any failure.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD=build/strict
FLAGS="-O0 -g -fcheck=all -finit-real=snan -finit-integer=-999999999 -ffpe-trap=invalid,zero,overflow -fbacktrace"

cd "$REPO_ROOT" || exit 2
mkdir -p build

echo "== strict build ($BUILD)"
if ! make --no-print-directory BUILD="$BUILD" FFLAGS="$FLAGS" > "$REPO_ROOT/$BUILD.log" 2>&1; then
  echo "FAIL  strict build did not compile - see $BUILD.log"
  exit 1
fi

status=0
echo "== fixtures (tolerant comparison)"
tests/run_tests.sh --tolerant "$BUILD" || status=1
echo "== error cases"
tests/run_error_tests.sh "$BUILD" || status=1

exit "$status"
