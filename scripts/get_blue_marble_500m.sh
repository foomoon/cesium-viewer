#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Download NASA Blue Marble Next Generation (topography + bathymetry), August 2004
# 500m tiles (A1-D1 top row, A2-D2 bottom row), then mosaic to a single GeoTIFF.
#
# Output:
#   data/source/bmng_500m/august/*.tif
#   data/working/bmng_500m_august.vrt
#   data/working/bmng_500m_august_mosaic.tif
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---- Hard-coded defaults ----
BASE_URL="https://assets.science.nasa.gov/content/dam/science/esd/eo/images/bmng/bmng-topography-bathymetry/august"
FNAME_PREFIX="world.topo.bathy.200408.3x21600x21600"
DEST_DIR="$PROJECT_ROOT/data/source/bmng_500m/august"
WORK_DIR="$PROJECT_ROOT/data/working"

VRT_OUT="$WORK_DIR/bmng_500m_august.vrt"
MOSAIC_OUT="$WORK_DIR/bmng_500m_august_mosaic.tif"

mkdir -p "$DEST_DIR" "$WORK_DIR"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing '$1' in PATH"; exit 1; }
}

need curl
need gdalbuildvrt
need gdal_translate
need gdalinfo

# Tile IDs in correct order: top row A1-D1, then bottom row A2-D2
TILES=(A1 B1 C1 D1 A2 B2 C2 D2)

echo "== Downloading BMNG 500m August tiles =="
echo "Base URL:  $BASE_URL"
echo "Dest dir:  $DEST_DIR"
echo

for t in "${TILES[@]}"; do
  url="${BASE_URL}/${FNAME_PREFIX}.${t}_geo.tif"
  out="${DEST_DIR}/${FNAME_PREFIX}.${t}_geo.tif"

  if [[ -f "$out" ]]; then
    echo "SKIP (exists): $t"
    continue
  fi

  echo "GET  $t  ->  $(basename "$out")"
  curl -L --fail --retry 3 --retry-delay 2 -o "$out" "$url"
done

echo
echo "== Building VRT mosaic =="
# Provide files explicitly in the known order so the layout matches A1-D2
FILES=()
for t in "${TILES[@]}"; do
  FILES+=("${DEST_DIR}/${FNAME_PREFIX}.${t}_geo.tif")
done

gdalbuildvrt -overwrite "$VRT_OUT" "${FILES[@]}"

echo
echo "== Writing GeoTIFF mosaic =="
gdal_translate \
  -co TILED=YES \
  -co COMPRESS=DEFLATE \
  -co BIGTIFF=YES \
  "$VRT_OUT" "$MOSAIC_OUT"

echo
echo "== Done =="
echo "VRT:    $VRT_OUT"
echo "Mosaic: $MOSAIC_OUT"
echo
echo "Quick check:"
echo "  gdalinfo \"$MOSAIC_OUT\" | head -n 40"
