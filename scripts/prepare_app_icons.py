#!/usr/bin/env python3
"""
Prepare iOS 18+ app icon variants for Arcade Collector.

iOS 18+ requires the dark and tinted appearance variants to have transparent
backgrounds so the system can composite them over its own chrome:

  Dark    - non-background pixels stay; the near-black background becomes alpha=0
            so the system's dark glass shows through.
  Tinted  - grayscale content stays as a luminance mask; alpha carries the mask so
            iOS can tint the shape with the user's chosen color.

Idempotent: on first run, the current opaque PNGs are backed up to
scripts/icon_sources/<name>.opaque.png. Subsequent runs use those backups as
the source, so re-running the script always produces the same result even if
you've already overwritten the file in the iconset. The sources live outside
the .appiconset because Xcode's asset catalog flags any unassigned files in
that folder as warnings.

Usage:
    python3 scripts/prepare_app_icons.py

Requires: Pillow (`python3 -m pip install --user Pillow`).
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageChops

REPO_ROOT = Path(__file__).resolve().parent.parent
ICONSET = REPO_ROOT / "ArcadeCollectorApp/ArcadeCollector/Assets.xcassets/AppIcon.appiconset"
SOURCES = Path(__file__).resolve().parent / "icon_sources"

DARK_ICON = ICONSET / "dark_icon_1024x1024.png"
TINTED_ICON = ICONSET / "Arcade Collector Tinted.png"

# Any pixel within this max-channel distance from the sampled corner color is
# treated as background and made fully transparent. Distances above 2x fade
# smoothly to fully opaque, giving a soft edge that reads correctly at small
# sizes without an obvious cutout ring.
DARK_BG_THRESHOLD = 40


def backup_source(target: Path) -> Path:
    """Return the .opaque.png backup in `SOURCES`, creating it from `target` on first run."""
    SOURCES.mkdir(exist_ok=True)
    backup = SOURCES / target.with_suffix(".opaque.png").name
    if not backup.exists():
        if not target.exists():
            raise FileNotFoundError(f"missing both {target} and {backup}")
        backup.write_bytes(target.read_bytes())
    return backup


def strip_dark_background(src: Path, dst: Path, threshold: int = DARK_BG_THRESHOLD) -> None:
    """Sample the corner as background color, convert matching pixels to alpha=0."""
    img = Image.open(src).convert("RGBA")
    bg = img.getpixel((0, 0))[:3]

    r, g, b, _ = img.split()
    dr = ImageChops.difference(r, Image.new("L", img.size, bg[0]))
    dg = ImageChops.difference(g, Image.new("L", img.size, bg[1]))
    db = ImageChops.difference(b, Image.new("L", img.size, bg[2]))
    distance = ImageChops.lighter(ImageChops.lighter(dr, dg), db)

    def ramp(value: int) -> int:
        if value <= threshold:
            return 0
        if value >= threshold * 2:
            return 255
        return int(255 * (value - threshold) / threshold)

    alpha = distance.point(ramp)
    img.putalpha(alpha)
    img.save(dst, "PNG")
    print(f"  wrote {dst.name}  (bg sampled from corner {bg}, threshold {threshold})")


def luminance_to_alpha(src: Path, dst: Path) -> None:
    """Rewrite the tinted icon as grayscale RGB + luminance alpha.

    The system tint is applied where alpha > 0, using the RGB grayscale as an
    intensity map. Black background becomes fully transparent (no tint applied);
    white content becomes fully opaque (full tint applied).
    """
    img = Image.open(src).convert("RGBA")
    gray = img.convert("L")
    result = Image.merge("RGBA", (gray, gray, gray, gray))
    result.save(dst, "PNG")
    print(f"  wrote {dst.name}  (grayscale RGB + luminance alpha)")


def main() -> int:
    if not ICONSET.is_dir():
        print(f"error: iconset not found at {ICONSET}", file=sys.stderr)
        return 1

    print("Preparing dark icon…")
    strip_dark_background(backup_source(DARK_ICON), DARK_ICON)

    print("Preparing tinted icon…")
    luminance_to_alpha(backup_source(TINTED_ICON), TINTED_ICON)

    print(
        "\nDone. Delete the app from the simulator/device and rebuild — "
        "iOS aggressively caches app icons."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
