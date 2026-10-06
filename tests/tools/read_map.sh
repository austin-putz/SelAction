#!/usr/bin/env bash
#
# Input map: lists every input statement in fortran/*.f90 (read *,
# read(*,...), call read_name) and which test inputs reach it.
#
# Usage:
#   tests/tools/read_map.sh
#
# Builds build/coverage (as coverage.sh does), runs each fixture
# (tests/fixtures) and each error case (tests/errors) on its own, and
# reads GCC's per-line counts after each run. Writes
#   tests/input_map/reads.csv   file,line,routine,statement,hit_by
# where hit_by lists the test inputs that executed the line (empty =
# never reached). tests/input_map/README.md explains each question; this
# script only produces the raw table. Rerun it after adding fixtures.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD=build/coverage
OUT_DIR=tests/input_map
CSV="$OUT_DIR/reads.csv"

cd "$REPO_ROOT" || exit 2
mkdir -p build "$OUT_DIR"

source "$SCRIPT_DIR/find_gcov.sh"

echo "== coverage build ($BUILD), gcov: $GCOV"
if ! make --no-print-directory BUILD="$BUILD" FFLAGS="-O0 -g --coverage" > "$BUILD.log" 2>&1; then
  echo "FAIL  coverage build did not compile - see $BUILD.log"
  exit 1
fi
binary="$REPO_ROOT/$BUILD/selaction"
[[ -x "$binary" ]] || binary="$binary.exe"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# --- 1. every input statement ------------------------------------------------
# file<TAB>line<TAB>routine<TAB>statement
for src in fortran/*.f90; do
  LC_ALL=C tr -d '\r' < "$src" | awk -v file="$(basename "$src")" '
    {
      line = $0
      code = line
      sub(/^[ \t]+/, "", code)
      if (code ~ /^!/) next
      low = tolower(code)
      if (match(low, /^((recursive|pure|elemental)[ \t]+)*(subroutine|program|module)[ \t]+[a-z0-9_]+/) ||
          match(low, /^[a-z0-9_ ()*=,]*function[ \t]+[a-z0-9_]+/)) {
        s = substr(low, RSTART, RLENGTH)
        n = split(s, w, /[ \t]+/)
        routine = w[n]
      }
      # drop a trailing comment (good enough: no "!" inside these statements)
      c = low
      sub(/!.*$/, "", c)
      if (c ~ /(^|[^a-z0-9_])read[ \t]*(\*|\()/ || c ~ /call[ \t]+read_name[ \t]*\(/) {
        stmt = code
        sub(/[ \t]*!.*$/, "", stmt)
        gsub(/\t/, " ", stmt)
        gsub(/  +/, " ", stmt)
        printf "%s\t%d\t%s\t%s\n", file, NR, routine, stmt
      }
    }'
done > "$work/reads.tsv"

# --- 2. which lines each test input executes ---------------------------------
# lists of name<TAB>input file, in manifest order
{
  grep -v '^#' tests/fixtures/manifest.txt | grep -v '^[[:space:]]*$' | cut -d: -f1 |
    while read -r name; do printf "%s\ttests/fixtures/%s.in\n" "$name" "$name"; done
  grep -v '^#' tests/errors/manifest.txt | grep -v '^[[:space:]]*$' | cut -d: -f1 |
    while read -r name; do printf "%s\ttests/errors/%s.in\n" "$name" "$name"; done
} > "$work/inputs.tsv"

: > "$work/hits.tsv"   # name<TAB>file<TAB>line
while IFS=$'\t' read -r name input; do
  rm -f "$BUILD"/*.gcda
  run="$work/run_$name"
  mkdir -p "$run"
  cp "$input" "$run/$name.in"
  (cd "$run" && "$binary" < "$name.in" > stdout.log 2>&1)
  for gcda in "$BUILD"/selaction-*.gcda; do
    [[ -f "$gcda" ]] || continue
    "$GCOV" -t "$gcda" 2>/dev/null | awk -v name="$name" -F: '
      $2 + 0 == 0 && $3 == "Source" { src = $4; sub(/^.*\//, "", src); next }
      {
        count = $1
        gsub(/[ *]/, "", count)
        if (count ~ /^[0-9]+$/ && count + 0 > 0) printf "%s\t%s\t%d\n", name, src, $2 + 0
      }'
  done >> "$work/hits.tsv"
  echo "ran   $name"
done < "$work/inputs.tsv"

# --- 3. join and write the CSV -----------------------------------------------
awk -F'\t' '
  FILENAME == ARGV[1] { order[++n] = $1; next }
  FILENAME == ARGV[2] { hit[$2 SUBSEP $3 SUBSEP $1] = 1; next }
  {
    by = ""
    for (i = 1; i <= n; i++)
      if ((($1 SUBSEP $2 SUBSEP order[i]) in hit)) by = by (by == "" ? "" : " ") order[i]
    stmt = $4
    gsub(/"/, "\"\"", stmt)
    printf "%s,%s,%s,\"%s\",%s\n", $1, $2, $3, stmt, by
  }' "$work/inputs.tsv" "$work/hits.tsv" "$work/reads.tsv" > "$work/body.csv"

{
  echo "file,line,routine,statement,hit_by"
  cat "$work/body.csv"
} > "$CSV"

# --- 4. summary --------------------------------------------------------------
echo ""
echo "Input statements reached by at least one test input:"
awk -F, 'NR > 1 { tot[$1]++; if ($NF != "") hit[$1]++ }
  END { for (f in tot) { printf "  %-18s %3d of %3d\n", f, hit[f], tot[f]; T += tot[f]; H += hit[f] }
        printf "  %-18s %3d of %3d\n", "TOTAL", H, T }' "$CSV" | sort -k1,1 | awk '/TOTAL/ {t = $0; next} {print} END {print t}'
echo ""
echo "wrote $CSV"
