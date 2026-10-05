#!/usr/bin/env bash
#
# Runs every fixture in tests/fixtures/ (per manifest.txt) against the
# compiled binaries in a source directory (default: fortran) and diffs
# actual output against the canonical expected output.
#
# Usage:
#   tests/run_tests.sh [platform_dir]
#
# platform_dir defaults to fortran, the single source tree (the same code
# builds on every OS). The argument is kept so a future port (e.g. a C++
# build dir) can be checked against the same fixtures.
#
# A listed binary that isn't built in platform_dir is skipped (SKIP), as
# long as at least one of the fixture's binaries ran.
#
# Nothing is allowed to pass silently: a fixture with NONE of its binaries
# built (e.g. a failed or forgotten build), or with its .in/.out missing,
# is a FAIL. The script exits non-zero on any FAIL.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
MANIFEST="$FIXTURES_DIR/manifest.txt"
PLATFORM_DIR="${1:-fortran}"
PLATFORM_PATH="$REPO_ROOT/$PLATFORM_DIR"

if [[ ! -d "$PLATFORM_PATH" ]]; then
  echo "error: platform directory not found: $PLATFORM_PATH" >&2
  exit 2
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: manifest not found: $MANIFEST" >&2
  exit 2
fi

pass=0
fail=0
skip=0

while IFS=: read -r base binaries description; do
  [[ -z "$base" || "$base" == \#* ]] && continue

  in_file="$FIXTURES_DIR/$base.in"
  out_file="$FIXTURES_DIR/$base.out"

  if [[ ! -f "$in_file" || ! -f "$out_file" ]]; then
    echo "FAIL  $base (missing $base.in or $base.out in $FIXTURES_DIR)"
    fail=$((fail + 1))
    continue
  fi

  ran=0

  IFS=',' read -ra binary_list <<< "$binaries"
  for binary in "${binary_list[@]}"; do
    binary_path="$PLATFORM_PATH/$binary"

    if [[ ! -x "$binary_path" ]]; then
      echo "SKIP  $base -> $PLATFORM_DIR/$binary (binary not built)"
      skip=$((skip + 1))
      continue
    fi

    ran=$((ran + 1))
    tmp_dir="$(mktemp -d)"
    cp "$in_file" "$tmp_dir/$base.in"

    (cd "$tmp_dir" && "$binary_path" < "$base.in" > stdout.log 2>&1)

    if [[ ! -f "$tmp_dir/$base.out" ]]; then
      echo "FAIL  $base -> $PLATFORM_DIR/$binary ($description)"
      echo "      no $base.out produced - see $tmp_dir/stdout.log"
      fail=$((fail + 1))
      continue
    fi

    if diff -q "$out_file" "$tmp_dir/$base.out" > /dev/null; then
      echo "PASS  $base -> $PLATFORM_DIR/$binary"
      pass=$((pass + 1))
      rm -rf "$tmp_dir"
    else
      echo "FAIL  $base -> $PLATFORM_DIR/$binary ($description)"
      echo "      diff (expected vs actual), full output kept in $tmp_dir"
      diff "$out_file" "$tmp_dir/$base.out" | head -20 | sed 's/^/      /'
      fail=$((fail + 1))
    fi
  done

  if [[ "$ran" -eq 0 ]]; then
    echo "FAIL  $base (none of its binaries [$binaries] are built in $PLATFORM_DIR)"
    fail=$((fail + 1))
  fi
done < "$MANIFEST"

echo ""
echo "$pass passed, $fail failed, $skip skipped"

[[ "$fail" -eq 0 ]]
