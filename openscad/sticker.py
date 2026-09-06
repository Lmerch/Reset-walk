#!/usr/bin/env python3
"""
Generates the QR sticker that gets applied into the card's QR pocket
(see qr_shape() / sticker_depth in card.scad).

Printing a full QR pattern in two filament colors via AMS turned out to
be unreliable — see the comment on qr_shape() in card.scad — so the 3D
print only has a plain recessed pocket, and the actual scannable QR is
printed separately (any home/office printer, on adhesive label paper)
and stuck into that pocket.

Usage: python3 sticker.py
Requires: pip install qrcode
Outputs: sticker.svg (vector, exact mm size — print this) and
         sticker.png (high-res raster preview)
"""
import re

import qrcode
import qrcode.image.svg

QR_SIZE_MM = 27.0  # must match qr_size in card.scad

vcard = "\r\n".join([
    "BEGIN:VCARD",
    "VERSION:3.0",
    "N:Merchant;Lloyd;;;",
    "FN:Lloyd Merchant",
    "TITLE:Community Mitigation & Volunteer Coordinator",
    "ORG:Roanoke Police Department",
    "TEL;TYPE=WORK,VOICE:(540) 853-5304",
    "END:VCARD",
])

# Standard 4-module quiet zone — no need to skimp on it now that this
# isn't fighting a 0.4mm nozzle's resolution, so use the reliable default.
qr = qrcode.QRCode(
    version=None,
    error_correction=qrcode.constants.ERROR_CORRECT_M,
    box_size=1,
    border=4,
)
qr.add_data(vcard)
qr.make(fit=True)
modules = len(qr.get_matrix())

# Vector output at the exact physical size, for crisp printing at any DPI.
# SvgPathFillImage (not plain SvgPathImage) adds an opaque white background
# rect — without it the "light" modules are just transparent, which looks
# fine in most viewers (transparency shows through as whatever's behind
# it) but rasterizes with alpha=0 there, not actual white pixels: a QR
# scanner reading that composited/flattened image sees no light/dark
# contrast at all and fails to decode. Confirmed broken with plain
# SvgPathImage (pyzbar/opencv both failed on a rasterized render) and
# confirmed fixed below with this class instead.
factory = qrcode.image.svg.SvgPathFillImage
svg_img = qr.make_image(image_factory=factory)
svg_img.save("sticker.svg")

# Force the SVG to exactly QR_SIZE_MM x QR_SIZE_MM. qrcode's SvgPathImage
# picks its own internal width/height (NOT "{modules}mm" as you'd expect —
# e.g. it rendered "6.5mm" for a 65-module code), and the viewBox already
# matches that internal coordinate system, so only width/height need
# overriding — the SVG scales its contents to whatever physical size those
# attributes declare. Match whatever value is actually there rather than
# assuming one, so this can't silently no-op again like it did before.
with open("sticker.svg") as f:
    svg = f.read()
svg, n = re.subn(r'width="[^"]*" height="[^"]*"',
                  f'width="{QR_SIZE_MM}mm" height="{QR_SIZE_MM}mm"', svg, count=1)
assert n == 1, "sticker.svg's width/height attributes weren't found to replace"
with open("sticker.svg", "w") as f:
    f.write(svg)

png_img = qr.make_image(fill_color="black", back_color="white")
px = round(QR_SIZE_MM / 25.4 * 1000)  # ~1000dpi, sharp for preview/cutting reference
png_img = png_img.resize((px, px))
png_img.save("sticker.png")

print(f"QR version {qr.version}, {modules}x{modules} modules, "
      f"{QR_SIZE_MM}mm sticker -> sticker.svg, sticker.png")
