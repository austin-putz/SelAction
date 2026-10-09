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
# any FAIL. A malformed manifest line, an .in not listed in the manifest,
# or a manifest with no cases is also a FAIL.

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
listed=" "

# "|| [[ -n ... ]]" also reads a last line that has no newline.
while IFS=: read -r name want_code files expected description || [[ -n "$name" ]]; do
  name="${name%$'\r'}"
  [[ -z "$name" || "$name" == \#* ]] && continue
  listed="$listed$name "

  bad=""
  [[ "$want_code" =~ ^[1-9][0-9]*$ ]] || bad="exit code '$want_code' is not a positive integer"
  [[ "$files" == none || "$files" == report ]] || bad="files field '$files' is not none or report"
  [[ -n "$expected" ]] || bad="expected text is empty"
  if [[ -n "$bad" ]]; then
    echo "FAIL  $name (manifest: $bad)"
    fail=$((fail + 1))
    continue
  fi

  in_file="$CASES_DIR/$name.in"
  if [[ ! -f "$in_file" ]]; then
    echo "FAIL  $name (missing $name.in in $CASES_DIR)"
    fail=$((fail + 1))
    continue
  fi

  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/selaction.XXXXXX")" || { echo "error: mktemp failed" >&2; exit 2; }
  # The program writes its input echo to <filename>.in: feed it a copy
  # under another name so it never overwrites the file it is reading.
  cp "$in_file" "$tmp_dir/input.stdin"
  (cd "$tmp_dir" && "$binary" < input.stdin > stdout.log 2>&1)
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

# Every .in in the directory must be in the manifest.
for f in "$CASES_DIR"/*.in; do
  [[ -e "$f" ]] || continue
  n="$(basename "$f" .in)"
  if [[ "$listed" != *" $n "* ]]; then
    echo "FAIL  $n.in is not listed in manifest.txt"
    fail=$((fail + 1))
  fi
done

if [[ $((pass + fail)) -eq 0 ]]; then
  echo "FAIL  no error cases listed in $MANIFEST"
  fail=1
fi

echo ""
echo "$pass passed, $fail failed (error cases)"

[[ "$fail" -eq 0 ]]
