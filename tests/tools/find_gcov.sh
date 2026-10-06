# Sourced by coverage.sh and read_map.sh: sets GCOV to GCC's gcov for
# the compiler in $FC (default gfortran), or exits 2 with a message.
#
# It must be GCC's gcov of the same major version as gfortran (another
# version may not read the coverage data). Apple's /usr/bin/gcov is
# LLVM's and can't read it at all.

FC="${FC:-gfortran}"

is_gcc_gcov() {
  local first
  first="$("$1" --version 2>/dev/null | head -1)"
  # GCC's says "gcov (GCC) 14.2.0" or "gcov (Ubuntu 14.2.0-...) 14.2.0";
  # Apple's says "Apple LLVM version ...".
  [[ "$first" == gcov* && "$first" != *LLVM* ]] || return 1
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
# Also try the compiler's own name with gfortran -> gcov, e.g. Ubuntu's
# x86_64-linux-gnu-gfortran-14 -> x86_64-linux-gnu-gcov-14.
fc_base="$(basename "$fc_path")"
for candidate in "$(dirname "$fc_path")/${fc_base/gfortran/gcov}" \
                 "$(dirname "$fc_path")/gcov-$major" "$(command -v "gcov-$major" || true)" \
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

