#!/usr/bin/env bash
#
# Runs every fixture in tests/fixtures/ (per manifest.txt) against
# selaction in a binary directory (default: build) and compares its report
# with the stored expected output.
#
# Usage:
#   make test                                # builds, then runs this on build/
#   tests/run_tests.sh [--tolerant] [bin_dir]
#
# bin_dir defaults to build, where `make` puts selaction (relative to the
# repository root, or absolute). On Windows the binary may be
# selaction.exe; both names are accepted.
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
# Nothing may pass silently. A FAIL is: a report that differs, a run that
# exits non-zero (even if its report looks complete), a missing .in/.out,
# an .in file not listed in the manifest, or a manifest with no fixtures.
# The script exits non-zero on any FAIL.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
MANIFEST="$FIXTURES_DIR/manifest.txt"

usage() {
  echo "usage: tests/run_tests.sh [--tolerant] [bin_dir]" >&2
  exit 2
}

TOLERANT=0
BIN_DIR=""
for arg in "$@"; do
  case "$arg" in
    --tolerant) TOLERANT=1 ;;
    -*) echo "error: unknown option $arg" >&2; usage ;;
    *)
      [[ -z "$BIN_DIR" ]] || { echo "error: more than one bin_dir given" >&2; usage; }
      BIN_DIR="$arg" ;;
  esac
done
BIN_DIR="${BIN_DIR:-build}"
case "$BIN_DIR" in
  /*) BIN_PATH="$BIN_DIR" ;;
  *)  BIN_PATH="$REPO_ROOT/$BIN_DIR" ;;
esac

binary="$BIN_PATH/selaction"
[[ ! -x "$binary" && -x "$binary.exe" ]] && binary="$binary.exe"
if [[ ! -x "$binary" ]]; then
  echo "error: selaction not found in $BIN_PATH (run \`make\` first)" >&2
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
if [[ "${OS:-}" == "Windows_NT" ]]; then
  DIFF_OPTS=(--strip-trailing-cr)
else
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) DIFF_OPTS=(--strip-trailing-cr) ;;
  esac
fi

pass=0
fail=0
listed=" "

# "|| [[ -n ... ]]" also reads a last line that has no newline.
while IFS=: read -r base description || [[ -n "$base" ]]; do
  base="${base%$'\r'}"
  [[ -z "$base" || "$base" == \#* ]] && continue
  listed="$listed$base "

  in_file="$FIXTURES_DIR/$base.in"
  out_file="$FIXTURES_DIR/$base.out"
  if [[ ! -f "$in_file" || ! -f "$out_file" ]]; then
    echo "FAIL  $base (missing $base.in or $base.out in $FIXTURES_DIR)"
    fail=$((fail + 1))
    continue
  fi

  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/selaction.XXXXXX")" || { echo "error: mktemp failed" >&2; exit 2; }
  # The program writes its input echo to <filename>.in, so it must not
  # read from a file of that name: feed it a copy with another name.
  cp "$in_file" "$tmp_dir/input.stdin"
  (cd "$tmp_dir" && "$binary" < input.stdin > stdout.log 2>&1)
  rc=$?

  if [[ "$rc" -ne 0 ]]; then
    echo "FAIL  $base ($description)"
    echo "      exit code $rc - see $tmp_dir/stdout.log"
    tail -5 "$tmp_dir/stdout.log" | sed 's/^/      /'
    fail=$((fail + 1))
    continue
  fi

  if [[ ! -f "$tmp_dir/$base.out" ]]; then
    echo "FAIL  $base ($description)"
    echo "      no $base.out produced - see $tmp_dir/stdout.log"
    fail=$((fail + 1))
    continue
  fi

  if [[ "$TOLERANT" -eq 1 ]]; then
    if Rscript "$SCRIPT_DIR/tools/compare_out.R" "$out_file" "$tmp_dir/$base.out" > "$tmp_dir/compare.log" 2>&1; then
      echo "PASS  $base (tolerant)"
      pass=$((pass + 1))
      rm -rf "$tmp_dir"
    else
      echo "FAIL  $base ($description)"
      echo "      differences beyond tolerance, full output kept in $tmp_dir"
      head -20 "$tmp_dir/compare.log" | sed 's/^/      /'
      fail=$((fail + 1))
    fi
  elif diff -q ${DIFF_OPTS[@]+"${DIFF_OPTS[@]}"} "$out_file" "$tmp_dir/$base.out" > /dev/null; then
    echo "PASS  $base"
    pass=$((pass + 1))
    rm -rf "$tmp_dir"
  else
    echo "FAIL  $base ($description)"
    echo "      diff (expected vs actual), full output kept in $tmp_dir"
    diff ${DIFF_OPTS[@]+"${DIFF_OPTS[@]}"} "$out_file" "$tmp_dir/$base.out" | head -20 | sed 's/^/      /'
    fail=$((fail + 1))
  fi
done < "$MANIFEST"

# Every .in in the directory must be in the manifest.
for f in "$FIXTURES_DIR"/*.in; do
  [[ -e "$f" ]] || continue
  name="$(basename "$f" .in)"
  if [[ "$listed" != *" $name "* ]]; then
    echo "FAIL  $name.in is not listed in manifest.txt"
    fail=$((fail + 1))
  fi
done

if [[ $((pass + fail)) -eq 0 ]]; then
  echo "FAIL  no fixtures listed in $MANIFEST"
  fail=1
fi

echo ""
echo "$pass passed, $fail failed"

[[ "$fail" -eq 0 ]]
