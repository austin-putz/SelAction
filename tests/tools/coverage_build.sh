# Sourced by coverage.sh and read_map.sh (needs REPO_ROOT and BUILD set,
# and the current directory at the repository root).
#
# Sets GCOV to GCC's gcov for the compiler in $FC (default gfortran), then
# builds selaction into $BUILD with --coverage (always rebuilt, so the
# binary can't be a stale build with other flags) and removes old .gcda
# files. Exits 2 if no matching gcov is found, 1 if the build fails.
#
# gcov must be GCC's, of the same major version as gfortran (another
# version may not read the coverage data). Apple's /usr/bin/gcov is
# LLVM's and can't read it at all.

FC="${FC:-gfortran}"

is_gcc_gcov() {
  local first
  first="$("$1" --version 2>/dev/null | head -1)"
  # GCC's says "gcov (GCC) 14.2.0" or "gcov (Ubuntu 14.2.0-...) 14.2.0";
  # Apple's says "Apple LLVM version ...".
  [[ "$first" == gcov* && "$first" != *LLVM* ]] || return 1
  [[ "$(printf "%s\n" "$first" | awk '{print $NF}' | cut -d. -f1)" == "$cb_major" ]]
}

cb_fc_path="$(command -v "$FC" || true)"
if [[ -z "$cb_fc_path" ]]; then
  echo "error: $FC not found on PATH" >&2
  exit 2
fi
# Follow symlinks by hand (macOS readlink has no -f before macOS 12.3).
while [[ -L "$cb_fc_path" ]]; do
  cb_link="$(readlink "$cb_fc_path")"
  case "$cb_link" in
    /*) cb_fc_path="$cb_link" ;;
    *)  cb_fc_path="$(dirname "$cb_fc_path")/$cb_link" ;;
  esac
done
cb_major="$("$FC" -dumpversion | cut -d. -f1)"

GCOV=""
# Also try the compiler's own name with gfortran -> gcov, e.g. Ubuntu's
# x86_64-linux-gnu-gfortran-14 -> x86_64-linux-gnu-gcov-14.
cb_fc_base="$(basename "$cb_fc_path")"
for cb_candidate in "$(dirname "$cb_fc_path")/${cb_fc_base/gfortran/gcov}" \
                 "$(dirname "$cb_fc_path")/gcov-$cb_major" "$(command -v "gcov-$cb_major" || true)" \
                 "$(dirname "$cb_fc_path")/gcov" "$(command -v gcov || true)"; do
  if [[ -n "$cb_candidate" && -x "$cb_candidate" ]] && is_gcc_gcov "$cb_candidate"; then
    GCOV="$cb_candidate"
    break
  fi
done
if [[ -z "$GCOV" ]]; then
  echo "error: no GCC gcov $cb_major found for $FC (version $cb_major)." >&2
  echo "       Looked next to $cb_fc_path and for gcov-$cb_major on PATH." >&2
  echo "       (Apple's /usr/bin/gcov is LLVM's and can't read GCC coverage data.)" >&2
  exit 2
fi

echo "== coverage build ($BUILD), gcov: $GCOV"
mkdir -p "$BUILD"
if ! make -B --no-print-directory BUILD="$BUILD" FFLAGS="-O0 -g --coverage" > "$BUILD.log" 2>&1; then
  echo "FAIL  coverage build did not compile - see $BUILD.log"
  exit 1
fi
rm -f "$BUILD"/*.gcda
