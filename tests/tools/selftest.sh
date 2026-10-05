#!/usr/bin/env bash
#
# Checks that tests/tools/compare_out.R catches what it should and lets
# through what it should, using small made-up reports. Run by
# tests/run_all.sh before the layers that rely on it. Needs R.
#
# Usage:
#   tests/tools/selftest.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPARE="$SCRIPT_DIR/compare_out.R"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/base.out" <<'OUT'
 SelAction test report
 trait          eADG     eBF
 response      12.345   -0.000
 sires            20
 ebv of the dam                       for eADG      (  -0.000)
 rate of inbreeding    1.234E-03
OUT

pass=0
fail=0

# check <name> <expected exit code> <sed expression applied to base.out>
check() {
  local name="$1" want="$2" expr="$3"
  sed "$expr" "$tmp/base.out" > "$tmp/$name.out"
  Rscript "$COMPARE" "$tmp/base.out" "$tmp/$name.out" > "$tmp/$name.log" 2>&1
  local got=$?
  if [[ "$got" -eq "$want" ]]; then
    echo "PASS  $name (exit $got)"
    pass=$((pass + 1))
  else
    echo "FAIL  $name (expected exit $want, got $got)"
    sed 's/^/      /' "$tmp/$name.log"
    fail=$((fail + 1))
  fi
}

# Must match.
check identical          0 's/^//'
check negative_zero      0 's/(  -0\.000)/(   0.000)/'
check last_digit         0 's/12\.345/12.346/'
check exponent_digit     0 's/1\.234E-03/1.235E-03/'
# Must not match.
check number_changed     1 's/12\.345/12.347/'
check integer_changed    1 's/  20$/  21/'
check text_changed       1 's/response/responses/'
check exponent_changed   1 's/E-03/E-02/'
check line_missing       1 '/sires/d'

echo ""
echo "$pass passed, $fail failed (compare_out.R self-test)"
[[ "$fail" -eq 0 ]]
