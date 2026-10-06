#!/usr/bin/env bash
#
# Runs every fixture in tests/fixtures/ (per manifest.txt) against the
# compiled binaries in a binary directory (default: build) and diffs
# actual output against the canonical expected output.
#
# Usage:
#   make test                    # builds, then runs this script on build/
#   tests/run_tests.sh [--tolerant] [bin_dir]
#
# bin_dir defaults to build, where `make` puts selaction. Pass another
# directory (relative to the repository root, or absolute) to test a different build (e.g. build/strict). On Windows the
# binary may be named selaction.exe; both names are accepted.
#
# By default each report must be byte-identical to the expected .out.
# With --tolerant it is compared by tests/tools/compare_out.R instead
# (numbers within one unit in the last printed digit; needs Rscript),
# which is what the strict -O0 build and other platforms use.
#
# On Windows gfortran writes CRLF line endings, so there the byte
# comparison ignores a trailing CR on each line; everything else must
# still match exactly.
#
# Every run must also exit 0: a run that stops with an error or a trap
# fails even if its report looks complete.
#
# A listed binary that isn't built in bin_dir is skipped (SKIP), as
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
TOLERANT=0
if [[ "${1:-}" == "--tolerant" ]]; then
  TOLERANT=1
  shift
fi
BIN_DIR="${1:-build}"
case "$BIN_DIR" in
  /*) BIN_PATH="$BIN_DIR" ;;
  *)  BIN_PATH="$REPO_ROOT/$BIN_DIR" ;;
esac

if [[ ! -d "$BIN_PATH" ]]; then
  echo "error: binary directory not found: $BIN_PATH (run \`make\` first)" >&2
  exit 2
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: manifest not found: $MANIFEST" >&2
  exit 2
fi

if [[ "$TOLERANT" -eq 1 ]] && ! command -v Rscript > /dev/null; then
  echo "error: --tolerant needs R (Rscript not found on PATH)" >&2
  exit 2
fi

DIFF_OPTS=()
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) DIFF_OPTS=(--strip-trailing-cr) ;;
esac

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
    binary_path="$BIN_PATH/$binary"
    if [[ ! -x "$binary_path" && -x "$binary_path.exe" ]]; then
      binary_path="$binary_path.exe"
    fi

    if [[ ! -x "$binary_path" ]]; then
      echo "SKIP  $base -> $BIN_DIR/$binary (binary not built)"
      skip=$((skip + 1))
      continue
    fi

    ran=$((ran + 1))
    tmp_dir="$(mktemp -d)"
    cp "$in_file" "$tmp_dir/$base.in"

    (cd "$tmp_dir" && "$binary_path" < "$base.in" > stdout.log 2>&1)
    rc=$?

    if [[ "$rc" -ne 0 ]]; then
      echo "FAIL  $base -> $BIN_DIR/$binary ($description)"
      echo "      exit code $rc - see $tmp_dir/stdout.log"
      tail -5 "$tmp_dir/stdout.log" | sed 's/^/      /'
      fail=$((fail + 1))
      continue
    fi

    if [[ ! -f "$tmp_dir/$base.out" ]]; then
      echo "FAIL  $base -> $BIN_DIR/$binary ($description)"
      echo "      no $base.out produced - see $tmp_dir/stdout.log"
      fail=$((fail + 1))
      continue
    fi

    if [[ "$TOLERANT" -eq 1 ]]; then
      if Rscript "$SCRIPT_DIR/tools/compare_out.R" "$out_file" "$tmp_dir/$base.out" > "$tmp_dir/compare.log" 2>&1; then
        echo "PASS  $base -> $BIN_DIR/$binary (tolerant)"
        pass=$((pass + 1))
        rm -rf "$tmp_dir"
      else
        echo "FAIL  $base -> $BIN_DIR/$binary ($description)"
        echo "      differences beyond tolerance, full output kept in $tmp_dir"
        head -20 "$tmp_dir/compare.log" | sed 's/^/      /'
        fail=$((fail + 1))
      fi
    elif diff -q ${DIFF_OPTS[@]+"${DIFF_OPTS[@]}"} "$out_file" "$tmp_dir/$base.out" > /dev/null; then
      echo "PASS  $base -> $BIN_DIR/$binary"
      pass=$((pass + 1))
      rm -rf "$tmp_dir"
    else
      echo "FAIL  $base -> $BIN_DIR/$binary ($description)"
      echo "      diff (expected vs actual), full output kept in $tmp_dir"
      diff ${DIFF_OPTS[@]+"${DIFF_OPTS[@]}"} "$out_file" "$tmp_dir/$base.out" | head -20 | sed 's/^/      /'
      fail=$((fail + 1))
    fi
  done

  if [[ "$ran" -eq 0 ]]; then
    echo "FAIL  $base (none of its binaries [$binaries] are built in $BIN_DIR)"
    fail=$((fail + 1))
  fi
done < "$MANIFEST"

echo ""
echo "$pass passed, $fail failed, $skip skipped"

[[ "$fail" -eq 0 ]]
