#!/usr/bin/env python3
"""
Build web map tiles for Cesium (Vite public/ folder) using GDAL.

Outputs XYZ tiles at:
  public/cesium/tiles/<tileset_name>/{z}/{x}/{y}.jpg

Requires:
  - GDAL installed (gdalwarp, gdaladdo, gdal2tiles.py available in PATH)

Example:
  python3 scripts/build_tiles.py \
    --input data/source/blue_marble.tif \
    --tileset blue-marble \
    --zoom 0-8
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path


def run(cmd: list[str]) -> None:
    print("\n$", " ".join(cmd))
    subprocess.run(cmd, check=True)


def require_in_path(exe: str) -> None:
    if shutil.which(exe) is None:
        raise SystemExit(
            f"Missing dependency: '{exe}' not found in PATH.\n"
            f"Install GDAL so '{exe}' is available."
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Path to source raster (GeoTIFF recommended).")
    parser.add_argument("--tileset", required=True, help="Tileset folder name under public/cesium/tiles/")
    parser.add_argument("--zoom", default="0-8", help="Zoom range like 0-8 or 0-10 (default 0-8).")
    parser.add_argument("--format", choices=["jpg", "png"], default="jpg", help="Tile image format (default jpg).")
    parser.add_argument("--jpeg-quality", type=int, default=85, help="JPEG quality (default 85).")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing output tileset folder.")
    args = parser.parse_args()

    # --- Dependencies
    require_in_path("gdalwarp")
    require_in_path("gdaladdo")
    # gdal2tiles could be "gdal2tiles.py" or "gdal2tiles" depending on install
    gdal2tiles = shutil.which("gdal2tiles.py") or shutil.which("gdal2tiles")
    if not gdal2tiles:
        raise SystemExit("Missing dependency: gdal2tiles(.py) not found in PATH.")

    project_root = Path(__file__).resolve().parents[1]
    input_path = (project_root / args.input).resolve()
    if not input_path.exists():
        raise SystemExit(f"Input not found: {input_path}")

    working_dir = project_root / "data" / "working"
    working_dir.mkdir(parents=True, exist_ok=True)

    # Reprojected output (Web Mercator)
    reproj_path = working_dir / f"{args.tileset}_3857.tif"

    out_dir = project_root / "public" / "cesium" / "tiles" / args.tileset
    if out_dir.exists():
        if args.overwrite:
            shutil.rmtree(out_dir)
        else:
            raise SystemExit(
                f"Output already exists: {out_dir}\n"
                f"Use --overwrite to replace it."
            )
    out_dir.parent.mkdir(parents=True, exist_ok=True)

    # --- Step 1: Reproject to EPSG:3857
    # Notes:
    # - For photo imagery, bilinear is a good resampling choice.
    # - Use DEFLATE on the intermediate GeoTIFF; tiles will be jpg/png.
    #
    # run([
    #     "gdalwarp",
    #     "-t_srs", "EPSG:3857",
    #     "-r", "bilinear",
    #     "-multi",
    #     "-wm", "2048",
    #     "-co", "TILED=YES",
    #     "-co", "COMPRESS=DEFLATE",
    #     "-co", "BIGTIFF=YES",
    #     str(input_path),
    #     str(reproj_path),
    # ])
    #
    run([
      "gdalwarp",
      "-t_srs", "EPSG:3857",
      "-te_srs", "EPSG:4326",
      "-te", "-180", "-85.05112878", "180", "85.05112878",
      "-r", "bilinear",
      "-multi",
      "-wm", "2048",
      "-co", "TILED=YES",
      "-co", "COMPRESS=DEFLATE",
      "-co", "BIGTIFF=YES",
      str(input_path),
      str(reproj_path),
    ])


    # --- Step 2: Build overviews (pyramids) to speed tiling
    run([
        "gdaladdo",
        "-r", "average",
        str(reproj_path),
        "2", "4", "8", "16", "32", "64", "128", "256"
    ])

    # --- Step 3: Generate XYZ tiles
    # --xyz => output is z/x/y (web standard)
    # -w none => no HTML viewer output
    # Format controls:
    # - if png: keeps transparency (bigger files)
    # - if jpg: smaller for satellite imagery
    gdal2tiles_cmd = [
        # gdal2tiles,
        "python3", "-m", "osgeo_utils.gdal2tiles",
        "-z", args.zoom,
        "--xyz",
        "-w", "none",
    ]

    if args.format == "png":
        gdal2tiles_cmd += ["--processes=8", "--tiledriver", "PNG"]
    else:
        # JPEG
        gdal2tiles_cmd += [
            "--processes=8",
            "--tiledriver", "JPEG",
            "--config", "JPEG_QUALITY", str(args.jpeg_quality),
        ]

    gdal2tiles_cmd += [str(reproj_path), str(out_dir)]
    run(gdal2tiles_cmd)

    print("\nDone.")
    print(f"Tiles written to: {out_dir}")
    print(f"Use this Cesium URL:\n  /cesium/tiles/{args.tileset}/{{z}}/{{x}}/{{y}}.{args.format}")


if __name__ == "__main__":
    main()
