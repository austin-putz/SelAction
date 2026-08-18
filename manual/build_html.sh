#!/usr/bin/env bash
# Compiles SelAction_Program_Description_raw_ocr.md to HTML with pandoc.
# Requires: pandoc (https://pandoc.org)

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pandoc SelAction_Program_Description_OCR.md \
  -f markdown+tex_math_single_backslash \
  -t html5 \
  --standalone \
  --mathjax="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js" \
  --css SelAction_Program_Description.css \
  --metadata pagetitle="SelAction - Description of the Program" \
  -o SelAction_Program_Description_OCR.html

echo "Wrote SelAction_Program_Description_OCR.html"

