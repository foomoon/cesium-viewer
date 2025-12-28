#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Midtone yellow balance correction for BMNG-style imagery
# Approximates Photoshop "Color Balance -> Midtones -> Yellow +60%"
#
# Usage:
#   ./scripts/color_correct_bmng_midtone_yellow.sh
#
# Optional overrides:
#   INPUT=path/to/mosaic.tif
#   NAME=bmng_aug_500m
#   PREVIEW_WIDTH=3000
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INPUT="${INPUT:-data/source/blue-marble-small.tif}"
NAME="${NAME:-blue_marble_small}"
PREVIEW_WIDTH="${PREVIEW_WIDTH:-3000}"

WORKDIR="$PROJECT_ROOT/data/working"
mkdir -p "$WORKDIR"

INPATH="$PROJECT_ROOT/$INPUT"

OUT="$WORKDIR/${NAME}_midtone_yellow.tif"
PRE_BEFORE="$WORKDIR/${NAME}_preview_before.png"
PRE_AFTER="$WORKDIR/${NAME}_preview_after.png"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing '$1'"; exit 1; }; }

need gdal_translate

IM=""
if command -v magick >/dev/null 2>&1; then
  IM="magick"
elif command -v convert >/dev/null 2>&1; then
  IM="convert"
else
  echo "ERROR: ImageMagick not found (need 'magick' or 'convert')."
  exit 1
fi

echo "== Midtone Yellow Balance Correction =="
echo "Input: $INPATH"
echo

# Preview BEFORE
gdal_translate -of PNG -outsize "$PREVIEW_WIDTH" 0 "$INPATH" "$PRE_BEFORE" >/dev/null

# Core operation:
# 1) Sigmoidal contrast isolates midtones
# 2) Channel gain warms midtones (R+G up, B slightly down)
# 3) sRGB for Cesium/WebGL safety
"$IM" "$INPATH" \
  -sigmoidal-contrast 6x50% \
  -channel R -evaluate multiply 1.08 +channel \
  -channel G -evaluate multiply 1.08 +channel \
  -channel B -evaluate multiply 0.92 +channel \
  -colorspace sRGB \
  "$OUT"

# Preview AFTER
gdal_translate -of PNG -outsize "$PREVIEW_WIDTH" 0 "$OUT" "$PRE_AFTER" >/dev/null

echo
echo "Done."
echo "Compare:"
echo "  BEFORE: $PRE_BEFORE"
echo "  AFTER : $PRE_AFTER"
