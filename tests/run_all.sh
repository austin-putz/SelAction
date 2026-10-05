#!/usr/bin/env bash
#
# Runs every test layer and prints one summary. Exits non-zero if any
# layer fails.
#
# Usage:
#   make check
#   tests/run_all.sh
#
# Layers, in order:
#   build        make (build/selaction)
#   tools        tests/tools/selftest.sh       compare_out.R catches changes (R)
#   golden       tests/run_tests.sh            byte-exact fixtures
#   errors       tests/run_error_tests.sh      bad input stops with the right code
#   strict       tests/tools/strict.sh         strict debug build, tolerant (R)
#   unit         tests/unit/run.sh             (test-hardening T3)
#   validation   tests/validation/run.sh       (T4)
#   properties   tests/properties/run.sh       (T5)
# A layer whose script doesn't exist yet is listed as "not yet present".
# Layers marked (R) need Rscript; without it they FAIL rather than being
# skipped. `make test` (golden + errors) needs no R.
#
# Coverage is not a layer here: run `make coverage`.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 2

names=()
results=()
failed=0

record() {
  names+=("$1")
  results+=("$2")
  [[ "$2" == FAIL* ]] && failed=1
}

# run_layer <name> <needs R: 0/1> <command...>
run_layer() {
  local name="$1" needs_r="$2"
  shift 2
  if [[ ! -x "$1" ]]; then
    record "$name" "not yet present"
    return
  fi
  if [[ "$needs_r" -eq 1 ]] && ! command -v Rscript > /dev/null; then
    record "$name" "FAIL (R is needed: Rscript not found)"
    return
  fi
  echo ""
  echo "=================== $name ==================="
  if "$@"; then
    record "$name" "PASS"
  else
    record "$name" "FAIL"
  fi
}

echo "=================== build ==================="
mkdir -p build
if make --no-print-directory > build/make.log 2>&1; then
  record build PASS
else
  record build "FAIL (see build/make.log)"
  tail -20 build/make.log
fi

if [[ "${results[0]}" == PASS ]]; then
  run_layer tools      1 tests/tools/selftest.sh
  run_layer golden     0 tests/run_tests.sh build
  run_layer errors     0 tests/run_error_tests.sh build
  run_layer strict     1 tests/tools/strict.sh
  run_layer unit       1 tests/unit/run.sh
  run_layer validation 1 tests/validation/run.sh
  run_layer properties 1 tests/properties/run.sh
fi

echo ""
echo "=================== summary ==================="
for i in "${!names[@]}"; do
  printf "  %-12s %s\n" "${names[$i]}" "${results[$i]}"
done

if [[ "$failed" -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "all present layers passed"
