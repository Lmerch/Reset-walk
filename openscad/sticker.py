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
import qrcode
import qrcode.image.svg

QR_SIZE_MM = 24.0  # must match qr_size in card.scad

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
factory = qrcode.image.svg.SvgPathImage
svg_img = qr.make_image(image_factory=factory)
svg_img.save("sticker.svg")

# Fix up the SVG to be exactly QR_SIZE_MM x QR_SIZE_MM (qrcode's SVG
# factory sizes in its own units by default) and raster preview.
with open("sticker.svg") as f:
    svg = f.read()
svg = svg.replace(
    f'width="{modules}mm" height="{modules}mm"',
    f'width="{QR_SIZE_MM}mm" height="{QR_SIZE_MM}mm"',
)
with open("sticker.svg", "w") as f:
    f.write(svg)

png_img = qr.make_image(fill_color="black", back_color="white")
png_img = png_img.resize((944, 944))  # ~1000dpi at 24mm, sharp for preview/cutting reference
png_img.save("sticker.png")

print(f"QR version {qr.version}, {modules}x{modules} modules, "
      f"{QR_SIZE_MM}mm sticker -> sticker.svg, sticker.png")
