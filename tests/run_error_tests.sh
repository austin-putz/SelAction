#!/usr/bin/env bash
#
# Runs every case in tests/errors/ (per manifest.txt) against selaction in
# a binary directory (default: build) and checks that the program stops
# with the expected exit code and message, instead of finishing normally.
#
# Usage:
#   make test                          # runs this after tests/run_tests.sh
#   tests/run_error_tests.sh [bin_dir]
#
# bin_dir defaults to build (relative to the repository root, or absolute).
# A case that exits 0, exits with the wrong code, prints the wrong message,
# or leaves the wrong files behind is a FAIL. The script exits non-zero on
# any FAIL.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CASES_DIR="$SCRIPT_DIR/errors"
MANIFEST="$CASES_DIR/manifest.txt"
BIN_DIR="${1:-build}"
case "$BIN_DIR" in
  /*) BIN_PATH="$BIN_DIR" ;;
  *)  BIN_PATH="$REPO_ROOT/$BIN_DIR" ;;
esac

binary="$BIN_PATH/selaction"
if [[ ! -x "$binary" && -x "$binary.exe" ]]; then
  binary="$binary.exe"
fi
if [[ ! -x "$binary" ]]; then
  echo "error: selaction not found in $BIN_PATH (run \`make\` first)" >&2
  exit 2
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: manifest not found: $MANIFEST" >&2
  exit 2
fi

pass=0
fail=0

while IFS=: read -r name want_code files expected description; do
  [[ -z "$name" || "$name" == \#* ]] && continue

  in_file="$CASES_DIR/$name.in"
  if [[ ! -f "$in_file" ]]; then
    echo "FAIL  $name (missing $name.in in $CASES_DIR)"
    fail=$((fail + 1))
    continue
  fi

  tmp_dir="$(mktemp -d)"
  cp "$in_file" "$tmp_dir/$name.in"
  (cd "$tmp_dir" && "$binary" < "$name.in" > stdout.log 2>&1)
  code=$?

  problems=()
  [[ "$code" -ne "$want_code" ]] && problems+=("exit code $code, expected $want_code")
  grep -qF -- "$expected" "$tmp_dir/stdout.log" || problems+=("message not found: $expected")

  outs=("$tmp_dir"/*.out)
  case "$files" in
    none)
      [[ -e "${outs[0]}" ]] && problems+=("a .out file was created")
      ;;
    report)
      if [[ ! -e "${outs[0]}" ]]; then
        problems+=("no .out file was created")
      else
        grep -qF -- "$expected" "${outs[0]}" || problems+=(".out does not contain the error")
        tail -1 "${outs[0]}" | grep -qF "run stopped" || problems+=(".out does not end with 'run stopped'")
      fi
      ;;
    *)
      problems+=("unknown files field '$files' in manifest")
      ;;
  esac

  if [[ ${#problems[@]} -eq 0 ]]; then
    echo "PASS  $name (exit $code)"
    pass=$((pass + 1))
    rm -rf "$tmp_dir"
  else
    echo "FAIL  $name ($description)"
    for p in "${problems[@]}"; do echo "      $p"; done
    echo "      output kept in $tmp_dir"
    fail=$((fail + 1))
  fi
done < "$MANIFEST"

echo ""
echo "$pass passed, $fail failed (error cases)"

[[ "$fail" -eq 0 ]]
