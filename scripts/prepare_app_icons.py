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
    """Return the .opaque.png backup in `SOURCES`, creating it from `target` on first run.

    Refuses to back up a target that already has transparency at the corner — the
    only way that happens is if a previous run already stripped the background
    and no backup was ever created (e.g., someone deleted the backup by hand),
    in which case backing it up now would freeze the *stripped* version as the
    "pristine source" and destroy the true original forever.
    """
    SOURCES.mkdir(exist_ok=True)
    backup = SOURCES / target.with_suffix(".opaque.png").name
    if not backup.exists():
        if not target.exists():
            raise FileNotFoundError(f"missing both {target} and {backup}")
        with Image.open(target) as candidate:
            if candidate.mode in ("RGBA", "LA"):
                corner = candidate.convert("RGBA").getpixel((0, 0))
                if corner[3] == 0:
                    raise SystemExit(
                        f"refusing to back up {target.name}: corner pixel is "
                        f"transparent, so this file appears to already be the "
                        f"processed output. Restore the true opaque source "
                        f"before rerunning."
                    )
        backup.write_bytes(target.read_bytes())
    return backup


def assert_uniform_corners(img: Image.Image, tolerance: int = 5) -> None:
    """Assert all four corners are within `tolerance` per channel of each other.

    The dark-background strip samples one corner and floods that color to alpha=0.
    If the corners disagree, the sampled color isn't representative — half the
    intended background will survive, or content near a differently-tinted corner
    will erase. Better to fail loud than silently produce a broken icon.
    """
    w, h = img.size
    corners = [
        img.getpixel((0, 0)),
        img.getpixel((w - 1, 0)),
        img.getpixel((0, h - 1)),
        img.getpixel((w - 1, h - 1)),
    ]
    for channel in range(3):
        values = [c[channel] for c in corners]
        if max(values) - min(values) > tolerance:
            raise SystemExit(
                f"corner colors disagree beyond tolerance {tolerance} "
                f"(channel {channel}: {values}). The background is not uniform; "
                f"corner-sampled color-key stripping would produce artifacts."
            )


def strip_dark_background(src: Path, dst: Path, threshold: int = DARK_BG_THRESHOLD) -> None:
    """Sample the corner as background color, convert matching pixels to alpha=0."""
    img = Image.open(src).convert("RGBA")
    assert_uniform_corners(img)
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
