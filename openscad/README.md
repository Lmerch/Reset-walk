# Lloyd Merchant business card — OpenSCAD / Bambu P1S + AMS

`card.scad` generates a 3.375" x 2.125" (85.6 x 54mm, ISO/credit-card size)
business card as **three separate solid bodies** that fit together into one
flush 3mm-thick card:

| File              | Color | Content                                                                 |
|--------------------|-------|--------------------------------------------------------------------------|
| `card_base.stl`    | Black | The card body, with the red/white artwork recessed 0.8mm into the top   |
| `card_red.stl`     | Red   | Name, divider line, "RESET" wordmark                                    |
| `card_white.stl`   | White | Title, department, phone, QR code, "SCAN TO SAVE CONTACT"               |

All three share the same coordinate system and were verified to be
watertight and mutually non-overlapping (their volumes sum exactly to the
rounded-rectangle card volume) — so they combine into one solid card with no
gaps or interference.

## QR code

The QR code encodes a vCard for Lloyd Merchant (name, title, department,
phone) generated from `qr_data.scad`. Scanning it saves the contact
directly, matching the "SCAN TO SAVE CONTACT" caption. To change the
encoded data (e.g. add an email or website), regenerate `qr_data.scad`:

```bash
python3 -c "
import qrcode
vcard = '\r\n'.join([
    'BEGIN:VCARD','VERSION:3.0','N:Merchant;Lloyd;;;','FN:Lloyd Merchant',
    'TITLE:Community Mitigation & Volunteer Coordinator',
    'ORG:Roanoke Police Department','TEL;TYPE=WORK,VOICE:(540) 853-5304',
    'END:VCARD',
])
qr = qrcode.QRCode(version=None, error_correction=qrcode.constants.ERROR_CORRECT_L, box_size=1, border=0)
qr.add_data(vcard); qr.make(fit=True)
m = qr.get_matrix(); n = len(m)
lines = [f'qr_modules = {n};', 'qr_matrix = [']
lines += ['  [' + ','.join('1' if v else '0' for v in row) + '],' for row in m]
lines.append('];')
open('qr_data.scad','w').write('\n'.join(lines) + '\n')
"
```
(`pip install qrcode` if needed.) Then re-run `./build.sh`.

## Regenerating the STLs

```bash
./build.sh
```

Requires OpenSCAD on `PATH`. Or open `card.scad` directly in the OpenSCAD
GUI, use the Customizer's "part" dropdown (`base` / `red` / `white`) to
preview/export each body, or leave it on `all` for a full-color preview.

## Printing on a Bambu P1S with AMS

1. Open Bambu Studio, **File > Import** all three STL files at once.
2. Make sure "auto-arrange on import" is off, or immediately undo any
   arrangement — the three parts must stay at their saved position (they're
   pre-aligned; do not move, rotate, or scale any of them relative to each
   other).
3. Select each object in the object list and assign it a filament/AMS slot:
   `card_base.stl` -> black, `card_red.stl` -> red, `card_white.stl` -> white.
4. Slice as a single plate. Bambu Studio will purge/swap filament within
   each layer of the top 0.8mm band to print the flush multi-color surface.
5. Recommended print settings: 0.4mm nozzle, 0.2mm layer height (the 0.8mm
   color band = 4 layers), 2-3 walls, 100% infill (card is thin/solid — no
   real benefit to sparse infill), no supports needed (flat, no overhangs).

### A note on QR print resolution

The QR is 53x53 modules + a 4-module quiet zone, sized to 25mm, so each
module is ~0.41mm — just above the reliable minimum feature size for a
0.4mm nozzle. If it doesn't scan reliably off the printer:
- Try a 0.2mm nozzle if you have one, or
- Increase `qr_size` in `card.scad` (and shrink other text a bit to keep
  clearances, matching what `build.sh`/the Customizer already validates via
  render), or
- Shorten the vCard data (e.g. drop `TITLE`) to drop the QR to a lower
  version with fewer modules.

## Adjusting the design

All layout constants (margins, font sizes, QR size, card dimensions,
recess depth) are declared near the top of `card.scad` with comments. Text
width can't be queried in this OpenSCAD version (2021.01), so sizes were
tuned by rendering and eyeballing clearance against the QR code and card
edges — if you change any text, re-render (`openscad -o preview.png
--viewall --autocenter --projection=ortho card.scad`) and check for overlap
before printing.
