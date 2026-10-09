#!/usr/bin/env bash
#
# Code coverage: builds selaction into build/coverage with --coverage,
# runs every fixture and error case on it, and prints which share of
# lines and branches the tests reached, per source file.
#
# Usage:
#   make coverage
#   tests/tools/coverage.sh [--min-lines N]
#
# --min-lines N fails (exit 1) if total line coverage is below N percent.
# The table is also saved to build/coverage/summary.txt.
#
# Every compiled source file must appear in the table: a file with no
# coverage data (e.g. after a crash) is a FAIL, not left out.
#
# Needs GCC's gcov, the one that matches gfortran (see coverage_build.sh).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD=build/coverage

min_lines=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-lines)
      [[ $# -ge 2 && "$2" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "error: --min-lines needs a number" >&2; exit 2; }
      min_lines="$2"; shift 2 ;;
    *) echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

cd "$REPO_ROOT" || exit 2

# Sets GCOV, builds $BUILD with --coverage, clears old .gcda files.
source "$SCRIPT_DIR/coverage_build.sh"

status=0
echo "== fixtures (tolerant comparison)"
tests/run_tests.sh --tolerant "$BUILD" > "$BUILD/run_tests.log" 2>&1 || status=1
tail -1 "$BUILD/run_tests.log"
echo "== error cases"
tests/run_error_tests.sh "$BUILD" > "$BUILD/run_error_tests.log" 2>&1 || status=1
tail -1 "$BUILD/run_error_tests.log"
if [[ "$status" -ne 0 ]]; then
  echo "FAIL  some tests failed on the coverage build - see $BUILD/run_tests.log and $BUILD/run_error_tests.log"
fi

# --- summarise -------------------------------------------------------------
summary="$BUILD/summary.txt"
missing=0
{
  printf "%-20s %16s %22s\n" "File" "Lines executed" "Branches taken"
  tot_l=0; tot_lx=0; tot_b=0; tot_bx=0
  # One .gcno per compiled file; its .gcda exists only if the file ran.
  for gcno in "$BUILD"/selaction-*.gcno; do
    [[ -f "$gcno" ]] || continue
    gcda="${gcno%.gcno}.gcda"
    src="$(basename "$gcno" .gcno)"
    src="${src#selaction-}.f90"
    if [[ ! -f "$gcda" ]]; then
      # a file with only declarations (selparameters.f90) has nothing to run
      if "$GCOV" -n "$gcno" 2>/dev/null | grep -q "No executable lines"; then
        continue
      fi
      printf "%-20s %s\n" "$src" "NO COVERAGE DATA (never ran, or the run crashed)"
      missing=$((missing + 1))
      continue
    fi
    out="$("$GCOV" -b -n "$gcda" 2> "$BUILD/gcov_errors.log")"
    # gcov prints one block per file, including included files; keep only
    # our own sources.
    row="$(printf "%s\n" "$out" | awk '
      /^File / { gsub(/\047/, "", $2); f = $2; keep = (f ~ /^fortran\//); l=""; ln=""; b=""; bn=""; next }
      keep && /^Lines executed:/ { split($0, a, /[:% ]+/); l = a[3]; ln = a[5] }
      keep && /^Taken at least once:/ { split($0, a, /[:% ]+/); b = a[5]; bn = a[7] }
      keep && /^$/ { if (l != "") { print l "|" ln "|" b "|" bn }; keep = 0 }
      END { if (keep && l != "") print l "|" ln "|" b "|" bn }')"
    if [[ -z "$row" ]]; then
      printf "%-20s %s\n" "$src" "GCOV FAILED (see $BUILD/gcov_errors.log)"
      missing=$((missing + 1))
      continue
    fi
    IFS='|' read -r lpct lnum bpct bnum <<< "$row"
    printf "%-20s %7s%% of %5s %10s%% of %5s\n" "$src" "$lpct" "$lnum" "${bpct:--}" "${bnum:--}"
    tot_l=$((tot_l + lnum))
    tot_lx=$(awk -v a="$tot_lx" -v p="$lpct" -v n="$lnum" 'BEGIN{printf "%.0f", a + p*n/100}')
    if [[ -n "$bnum" ]]; then
      tot_b=$((tot_b + bnum))
      tot_bx=$(awk -v a="$tot_bx" -v p="$bpct" -v n="$bnum" 'BEGIN{printf "%.0f", a + p*n/100}')
    fi
  done
  lpct_tot=$(awk -v x="$tot_lx" -v n="$tot_l" 'BEGIN{ if (n > 0) printf "%.2f", 100*x/n; else print "0" }')
  bpct_tot=$(awk -v x="$tot_bx" -v n="$tot_b" 'BEGIN{ if (n > 0) printf "%.2f", 100*x/n; else print "0" }')
  printf "%-20s %7s%% of %5s %10s%% of %5s\n" "TOTAL" "$lpct_tot" "$tot_l" "$bpct_tot" "$tot_b"
} > "$summary"

echo ""
cat "$summary"

if [[ "$(grep -c '%' "$summary")" -le 1 ]]; then
  echo "FAIL  no coverage data was collected (no .gcda files in $BUILD)"
  exit 1
fi
if [[ "$missing" -gt 0 ]]; then
  echo "FAIL  $missing source file(s) have no coverage data"
  status=1
fi

if [[ -n "$min_lines" ]]; then
  total="$(awk '/^TOTAL/ { sub(/%/, "", $2); print $2 }' "$summary")"
  if awk -v t="$total" -v m="$min_lines" 'BEGIN{ exit !(t + 0 < m + 0) }'; then
    echo "FAIL  line coverage $total% is below the minimum $min_lines%"
    status=1
  else
    echo "PASS  line coverage $total% >= $min_lines%"
  fi
fi

exit "$status"
