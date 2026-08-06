#!/usr/bin/env python3
"""Generate MirrorLock macOS app icon PNGs."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "MirrorLock" / "Assets.xcassets" / "AppIcon.appiconset"

SIZES = {
    "icon_16.png": 16,
    "icon_16@2x.png": 32,
    "icon_32.png": 32,
    "icon_32@2x.png": 64,
    "icon_128.png": 128,
    "icon_128@2x.png": 256,
    "icon_256.png": 256,
    "icon_256@2x.png": 512,
    "icon_512.png": 512,
    "icon_512@2x.png": 1024,
}


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s = size / 1024.0
    pad = 64 * s
    radius = 220 * s

    # Background gradient (diagonal)
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(lerp(15, 58, t))
        g = int(lerp(23, 110, t))
        b = int(lerp(42, 220, t))
        bg_draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    # Rounded rect mask
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        (pad, pad, size - pad, size - pad), radius=radius, fill=255
    )
    bg = Image.composite(bg, Image.new("RGBA", (size, size), (0, 0, 0, 0)), mask)
    img = Image.alpha_composite(img, bg)

    draw = ImageDraw.Draw(img)

    # Mirror frame (back rectangle)
    mx1, my1 = 250 * s, 220 * s
    mx2, my2 = 780 * s, 720 * s
    draw.rounded_rectangle(
        (mx1, my1, mx2, my2),
        radius=48 * s,
        fill=(255, 255, 255, 35),
        outline=(255, 255, 255, 90),
        width=max(1, int(6 * s)),
    )

    # Mirror shine band
    shine = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shine_draw = ImageDraw.Draw(shine)
    shine_draw.polygon(
        [
            (280 * s, 260 * s),
            (520 * s, 260 * s),
            (420 * s, 680 * s),
            (220 * s, 680 * s),
        ],
        fill=(255, 255, 255, 28),
    )
    img = Image.alpha_composite(img, shine)

    draw = ImageDraw.Draw(img)

    # Lock body
    lx, ly = 430 * s, 480 * s
    lw, lh = 220 * s, 180 * s
    draw.rounded_rectangle(
        (lx, ly, lx + lw, ly + lh),
        radius=28 * s,
        fill=(255, 255, 255, 230),
    )

    # Lock shackle
    sh_x = lx + lw * 0.18
    sh_y = ly - 95 * s
    sh_w = lw * 0.64
    sh_h = 110 * s
    draw.arc(
        (sh_x, sh_y, sh_x + sh_w, sh_y + sh_h * 2),
        start=180,
        end=0,
        fill=(255, 255, 255, 230),
        width=max(2, int(28 * s)),
    )
    leg_top = min(sh_y + sh_h, ly - 1)
    draw.rectangle(
        (sh_x + 8 * s, leg_top, sh_x + 28 * s, ly),
        fill=(255, 255, 255, 230),
    )
    draw.rectangle(
        (sh_x + sh_w - 28 * s, leg_top, sh_x + sh_w - 8 * s, ly),
        fill=(255, 255, 255, 230),
    )

    # Keyhole
    kx = lx + lw / 2
    ky = ly + lh * 0.42
    kr = 16 * s
    draw.ellipse(
        (kx - kr, ky - kr, kx + kr, ky + kr),
        fill=(58, 110, 220, 255),
    )
    draw.rectangle(
        (kx - 8 * s, ky, kx + 8 * s, ky + 42 * s),
        fill=(58, 110, 220, 255),
    )

    # Subtle outer glow for large sizes
    if size >= 128:
        glow = img.filter(ImageFilter.GaussianBlur(radius=max(1, int(8 * s))))
        glow = Image.blend(
            Image.new("RGBA", (size, size), (0, 0, 0, 0)),
            glow,
            alpha=0.15,
        )
        img = Image.alpha_composite(glow, img)

    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, px in SIZES.items():
        icon = draw_icon(px)
        icon.save(OUT / name, "PNG")
        print(f"Wrote {name} ({px}px)")

    # Also export for website
    web_dir = ROOT / "docs" / "assets"
    web_dir.mkdir(parents=True, exist_ok=True)
    draw_icon(512).save(web_dir / "icon-512.png", "PNG")
    draw_icon(180).save(web_dir / "apple-touch-icon.png", "PNG")
    draw_icon(32).save(web_dir / "favicon.png", "PNG")
    print("Wrote docs/assets icons")


if __name__ == "__main__":
    main()
