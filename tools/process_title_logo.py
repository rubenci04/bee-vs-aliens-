"""Remove the title logo's pure-green chroma background and reduce green spill."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


def cutout(source: Path, destination: Path) -> None:
    rgba = np.asarray(Image.open(source).convert("RGBA"), dtype=np.float32)
    rgb = rgba[..., :3]
    red, green, blue = rgb[..., 0], rgb[..., 1], rgb[..., 2]

    # JPEG compression shifts the pure green a little. Green dominance identifies
    # the key while leaving the cyan Alien lettering (where blue >= green) intact.
    dominance = green - np.maximum(red, blue)
    low = 7.0
    high = 76.0
    t = np.clip((dominance - low) / (high - low), 0.0, 1.0)
    alpha = 1.0 - t * t * (3.0 - 2.0 * t)

    # Despill only the keyed edge: remove excess green and add its neutralized
    # component to red/blue so the yellow glow remains warm instead of green.
    spill = np.clip(dominance, 0.0, 255.0) * (1.0 - alpha)
    rgb[..., 1] = np.maximum(0.0, green - spill * 0.88)
    rgb[..., 0] = np.minimum(255.0, red + spill * 0.16)
    rgb[..., 2] = np.minimum(255.0, blue + spill * 0.12)

    out = np.dstack((np.clip(rgb, 0, 255), alpha * 255.0)).astype(np.uint8)
    destination.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(out, "RGBA").save(destination)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", nargs="?", type=Path, default=Path("assets/ui/title/title_logo.png"))
    parser.add_argument("destination", nargs="?", type=Path, default=Path("assets/ui/title/title_logo_cutout.png"))
    args = parser.parse_args()
    cutout(args.source, args.destination)
    print(f"Saved alpha cutout to {args.destination}")


if __name__ == "__main__":
    main()
