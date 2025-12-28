#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Build the default global basemap for this project.
#
# Opinionated defaults:
#   - Source: NASA Blue Marble (global)
#   - Projection: EPSG:3857
#   - Zooms: 0–8
#   - Output: public/cesium/tiles/blue-marble
#   - Format: JPEG
#
# Optional overrides are allowed via CLI flags, but not required.
# -----------------------------------------------------------------------------

python3 --version >/dev/null 2>&1 || {
  echo "ERROR: python3 is required but not found in PATH"
  exit 1
}

# create python virtual environment if it doesn't exist
if [[ ! -d ".venv" ]]; then
  echo "Creating Python virtual environment..."
  python3 -m venv .venv
fi

echo "Activating Python virtual environment..."
source .venv/bin/activate

echo "Installing required Python packages..."
install-requirements() {
  pip install --upgrade pip
  pip install -r scripts/requirements.txt
}

install-requirements

# ---- DOWNLOAD SOURCE IMAGE (optional low res imagery) ----
# if [[ ! -f "./scripts/world.topo.bathy.200408.3x21600x10800_geo.tif" ]]; then
#   echo "Downloading Blue Marble source image..."
#   curl -L -o ./scripts/world.topo.bathy.200408.3x21600x10800_geo.tif \
#     https://assets.science.nasa.gov/content/dam/science/esd/eo/images/bmng/bmng-topography-bathymetry/august/world.topo.bathy.200408.3x21600x10800_geo.tif
# else
#   echo "Blue Marble source image already exists, skipping download."
# fi

# ---- DOWNLOAD HIGH RES SOURCE IMAGE (optional) ----
if [[ ! -f "data/working/bmng_500m_august_mosaic.tif" ]]; then
  echo "Downloading high-resolution Blue Marble source image..."
  mkdir -p data/working
  ./scripts/get_blue_marble_500m.sh
else
  echo "High-resolution Blue Marble source image already exists, skipping download."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PYTHON="$PROJECT_ROOT/scripts/build_tiles.py"

# ---- HARD-CODED DEFAULTS ----
# https://assets.science.nasa.gov/content/dam/science/esd/eo/images/bmng/bmng-topography-bathymetry/august/world.topo.bathy.200408.3x21600x10800_geo.tif
# DEFAULT_INPUT="./scripts/world.topo.bathy.200408.3x21600x10800_geo.tif"
DEFAULT_INPUT="data/working/bmng_500m_august_mosaic.tif"
DEFAULT_TILESET="blue-marble"
DEFAULT_ZOOM="0-8"
DEFAULT_FORMAT="jpg"
DEFAULT_JPEG_QUALITY="85"
DEFAULT_OVERWRITE="--overwrite"

# ---- ENV OVERRIDES (optional) ----
INPUT="${INPUT:-$DEFAULT_INPUT}"
TILESET="${TILESET:-$DEFAULT_TILESET}"
ZOOM="${ZOOM:-$DEFAULT_ZOOM}"
FORMAT="${FORMAT:-$DEFAULT_FORMAT}"
JPEG_QUALITY="${JPEG_QUALITY:-$DEFAULT_JPEG_QUALITY}"

# ---- SANITY CHECKS ----
if [[ ! -f "$PROJECT_ROOT/$INPUT" ]]; then
  echo "ERROR: Source image not found:"
  echo "  $PROJECT_ROOT/$INPUT"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 not found in PATH"
  exit 1
fi

# ---- EXECUTE ----
echo "Building Cesium basemap with defaults:"
echo "  Input:     $INPUT"
echo "  Tileset:   $TILESET"
echo "  Zoom:      $ZOOM"
echo "  Format:    $FORMAT"
echo "  Quality:   $JPEG_QUALITY"
echo

python3 "$PYTHON" \
  --input "$INPUT" \
  --tileset "$TILESET" \
  --zoom "$ZOOM" \
  --format "$FORMAT" \
  --jpeg-quality "$JPEG_QUALITY" \
  $DEFAULT_OVERWRITE
