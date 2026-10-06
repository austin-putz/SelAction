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
# Needs GCC's gcov, the one that matches gfortran. Apple's /usr/bin/gcov
# is LLVM's and can't read GCC's coverage data, so this script looks next
# to the real gfortran first, then for gcov-<major version>, and stops if
# it only finds a gcov that isn't GCC's.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD=build/coverage
FC="${FC:-gfortran}"

min_lines=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-lines)
      [[ $# -ge 2 ]] || { echo "error: --min-lines needs a number" >&2; exit 2; }
      min_lines="$2"; shift 2 ;;
    *) echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

cd "$REPO_ROOT" || exit 2
mkdir -p build

# --- find GCC's gcov -------------------------------------------------------
# GCC's gcov of the same major version as gfortran (another version may
# not read the coverage data).
is_gcc_gcov() {
  local first
  first="$("$1" --version 2>/dev/null | head -1)"
  [[ "$first" == *GCC* ]] || return 1
  [[ "$(printf "%s\n" "$first" | awk '{print $NF}' | cut -d. -f1)" == "$major" ]]
}

fc_path="$(command -v "$FC" || true)"
if [[ -z "$fc_path" ]]; then
  echo "error: $FC not found on PATH" >&2
  exit 2
fi
# Follow symlinks by hand (macOS readlink has no -f before macOS 12.3).
while [[ -L "$fc_path" ]]; do
  link="$(readlink "$fc_path")"
  case "$link" in
    /*) fc_path="$link" ;;
    *)  fc_path="$(dirname "$fc_path")/$link" ;;
  esac
done
major="$("$FC" -dumpversion | cut -d. -f1)"

GCOV=""
for candidate in "$(dirname "$fc_path")/gcov-$major" "$(command -v "gcov-$major" || true)" \
                 "$(dirname "$fc_path")/gcov" "$(command -v gcov || true)"; do
  if [[ -n "$candidate" && -x "$candidate" ]] && is_gcc_gcov "$candidate"; then
    GCOV="$candidate"
    break
  fi
done
if [[ -z "$GCOV" ]]; then
  echo "error: no GCC gcov $major found for $FC (version $major)." >&2
  echo "       Looked next to $fc_path and for gcov-$major on PATH." >&2
  echo "       (Apple's /usr/bin/gcov is LLVM's and can't read GCC coverage data.)" >&2
  exit 2
fi

# --- build and run ---------------------------------------------------------
echo "== coverage build ($BUILD), gcov: $GCOV"
if ! make --no-print-directory BUILD="$BUILD" FFLAGS="-O0 -g --coverage" > "$BUILD.log" 2>&1; then
  echo "FAIL  coverage build did not compile - see $BUILD.log"
  exit 1
fi
rm -f "$BUILD"/*.gcda

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
{
  printf "%-20s %16s %22s\n" "File" "Lines executed" "Branches taken"
  tot_l=0; tot_lx=0; tot_b=0; tot_bx=0
  for gcda in "$BUILD"/selaction-*.gcda; do
    [[ -f "$gcda" ]] || continue
    out="$("$GCOV" -b -n "$gcda" 2>/dev/null)"
    # gcov prints one block per file, including included/system files;
    # keep only our own sources.
    while IFS='|' read -r file lpct lnum bpct bnum; do
      [[ -n "$file" ]] || continue
      printf "%-20s %7s%% of %5s %10s%% of %5s\n" "$file" "$lpct" "$lnum" "${bpct:--}" "${bnum:--}"
      tot_l=$((tot_l + lnum))
      tot_lx=$(awk -v a="$tot_lx" -v p="$lpct" -v n="$lnum" 'BEGIN{printf "%.0f", a + p*n/100}')
      if [[ -n "$bnum" ]]; then
        tot_b=$((tot_b + bnum))
        tot_bx=$(awk -v a="$tot_bx" -v p="$bpct" -v n="$bnum" 'BEGIN{printf "%.0f", a + p*n/100}')
      fi
    done < <(printf "%s\n" "$out" | awk '
      /^File / { gsub(/\047/, "", $2); f = $2; keep = (f ~ /^fortran\//); l=""; ln=""; b=""; bn=""; next }
      keep && /^Lines executed:/ { split($0, a, /[:% ]+/); l = a[3]; ln = a[5] }
      keep && /^Taken at least once:/ { split($0, a, /[:% ]+/); b = a[5]; bn = a[7] }
      keep && /^$/ { if (l != "") { sub(/^fortran\//, "", f); print f "|" l "|" ln "|" b "|" bn }; keep = 0 }
      END { if (keep && l != "") { sub(/^fortran\//, "", f); print f "|" l "|" ln "|" b "|" bn } }')
  done
  lpct_tot=$(awk -v x="$tot_lx" -v n="$tot_l" 'BEGIN{ if (n > 0) printf "%.2f", 100*x/n; else print "0" }')
  bpct_tot=$(awk -v x="$tot_bx" -v n="$tot_b" 'BEGIN{ if (n > 0) printf "%.2f", 100*x/n; else print "0" }')
  printf "%-20s %7s%% of %5s %10s%% of %5s\n" "TOTAL" "$lpct_tot" "$tot_l" "$bpct_tot" "$tot_b"
} > "$summary"

echo ""
cat "$summary"

if [[ "$(wc -l < "$summary")" -le 2 ]]; then
  echo "FAIL  no coverage data was collected (no .gcda files in $BUILD)"
  exit 1
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
