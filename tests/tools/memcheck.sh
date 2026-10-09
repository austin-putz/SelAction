#!/usr/bin/env bash
#
# Memory check: builds selaction into build/memcheck (-O0 -g) and runs
# every fixture and error case under valgrind, which reports any use of a
# value that was never set. Such a value can change results only on some
# machines or some runs (2026-10-09: ovlp2 once selected 0 sires on Linux
# because unset common-environmental correlations held a NaN). The strict
# build can't see this for allocated arrays; valgrind can.
#
# Usage:
#   make memcheck
#   tests/tools/memcheck.sh
#
# Needs valgrind, which runs on Linux (not on current macOS). CI runs this
# in the Linux job. Exits non-zero on any valgrind error, or if valgrind
# is missing.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD=build/memcheck

if ! command -v valgrind > /dev/null; then
  echo "error: valgrind not found (it runs on Linux; on a Mac use Docker or CI)" >&2
  exit 2
fi

cd "$REPO_ROOT" || exit 2
mkdir -p "$BUILD"

echo "== memcheck build ($BUILD)"
if ! make -B --no-print-directory BUILD="$BUILD" FFLAGS="-O0 -g" > "$BUILD.log" 2>&1; then
  echo "FAIL  memcheck build did not compile - see $BUILD.log"
  exit 1
fi
binary="$REPO_ROOT/$BUILD/selaction"

pass=0
fail=0
# name<TAB>input<TAB>expected exit code
{
  grep -v '^#' tests/fixtures/manifest.txt | grep -v '^[[:space:]]*$' | cut -d: -f1 |
    while read -r n; do printf "%s\ttests/fixtures/%s.in\t0\n" "$n" "$n"; done
  grep -v '^#' tests/errors/manifest.txt | grep -v '^[[:space:]]*$' | cut -d: -f1,2 |
    while IFS=: read -r n c; do printf "%s\ttests/errors/%s.in\t%s\n" "$n" "$n" "$c"; done
} > "$BUILD/inputs.tsv"

while IFS=$'\t' read -r name input want; do
  run="$(mktemp -d "${TMPDIR:-/tmp}/selaction.XXXXXX")" || { echo "error: mktemp failed" >&2; exit 2; }
  cp "$input" "$run/input.stdin"
  # 99 marks a valgrind error, distinct from the program's own exit codes.
  (cd "$run" && valgrind -q --error-exitcode=99 --track-origins=yes \
     "$binary" < input.stdin > stdout.log 2> valgrind.log)
  rc=$?
  if [[ "$rc" -eq 99 ]]; then
    echo "FAIL  $name: valgrind found errors - see $run/valgrind.log"
    grep -m 6 -E "Conditional jump|uninitialised|at 0x|by 0x" "$run/valgrind.log" | sed 's/^/      /'
    fail=$((fail + 1))
  elif [[ "$rc" -ne "$want" ]]; then
    echo "FAIL  $name: exit code $rc, expected $want - see $run/stdout.log"
    fail=$((fail + 1))
  else
    echo "PASS  $name"
    pass=$((pass + 1))
    rm -rf "$run"
  fi
done < "$BUILD/inputs.tsv"

echo ""
echo "$pass passed, $fail failed (valgrind memcheck)"
[[ "$fail" -eq 0 && "$pass" -gt 0 ]]
