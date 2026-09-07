# Lloyd Merchant business card — OpenSCAD / Bambu P1S + AMS

`card.scad` generates a 3.5" x 2" (88.9 x 50.8mm, standard US business
card size), 1.6mm-thick business card as **three separate solid bodies**
that fit together into one flush card. This is the "Modern Minimalist"
layout: a big "RESET" wordmark over the name up top, a two-tone title
pinned to the bottom-left, a short vertical divider accent between them,
and a QR code + "SCAN TO SAVE" caption on the right.

| File              | Color | Content                                                                 |
|--------------------|-------|--------------------------------------------------------------------------|
| `card_base.stl`    | Black | The card body, with the red/white artwork recessed 0.6mm into the top   |
| `card_red.stl`     | Red   | "RESET" wordmark, top half of the title ("COMMUNITY MITIGATION"), divider accent |
| `card_white.stl`   | White | "LLOYD MERCHANT" name, bottom half of the title ("VOLUNTEER COORDINATOR"), the QR code, "SCAN TO SAVE" caption |

All three share the same coordinate system and were verified to be
watertight and mutually non-overlapping (their volumes sum exactly to the
full card volume) — so they combine into one solid card with no gaps or
interference.

## The QR is printed directly in two colors — no sticker

The QR encodes a vCard for Lloyd Merchant (name, title, department, phone)
generated from `qr_data.scad`. Scanning it saves the contact directly,
matching the "SCAN TO SAVE" caption. This prints reliably with the tuned
settings below — confirmed on a real print. To change the encoded data
(e.g. add an email or website), regenerate `qr_data.scad`:

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
   each layer of the top 0.6mm band to print the flush multi-color surface,
   including the QR's dense module pattern.
5. Recommended print settings: 0.4mm nozzle, 0.2mm layer height (the 0.6mm
   color band = 3 layers), 2-3 walls, 100% infill (card is thin/solid — no
   real benefit to sparse infill), no supports needed (flat, no overhangs).
   Enable **Advanced > Detect thin walls** — this design leans on it for
   the text and QR modules to come out solid instead of getting skipped as
   sub-perimeter-width features.
6. **This is the setting that actually matters most** (see history below):
   **Z-hop set to Normal Lift** (not Auto Lift) at ≥0.4mm, a bumped-up
   retraction length, **avoid crossing perimeters** enabled, reduced
   travel speed, and print temperature not needlessly high for your
   filament. Without these, expect stray specks scattered across the
   printed surface, unrelated to the QR/text content itself.

## Print troubleshooting history

Kept here since the fixes are non-obvious and might recur if the design is
extended later.

**Small text was unreadable after slicing.** Text sized directly off cap
height (e.g. 2.2mm) gives bold sans strokes only ~0.35mm wide — thinner
than a 0.4mm nozzle can reliably lay down, so the slicer's thin-wall
handling dropped or fused them. Fixed by routing all text through the
`bold_text()` helper, which applies `offset(delta = stroke_fatten)` to
fatten every stroke before it's cut/extruded. `stroke_fatten` is 0.18,
raised from an initial 0.13 after a print still showed a handful of
letters coming out wrong (the exact cause wasn't pinned down, so this is a
broader safety margin rather than a targeted fix) — checked at this
design's smallest text size (2.15mm) with a zoomed render to confirm
letters stayed legible and didn't fuse.

**The QR code printed as sparse noise, not a dense pattern (this
diagnosis turned out to be wrong).** At the time this looked like a hard
AMS limitation (~2800 filament swaps packed into one small area, many
between diagonally-touching modules narrower than a nozzle width) and the
design was briefly changed to a plain pocket + separately-printed sticker
to work around it. A later print with corrected retraction/Z-hop/
travel-speed settings (next item) showed the real printed QR working
fine, so the original diagnosis was wrong (or at least incomplete) — the
speckling below was the actual cause, and fixing it also fixed the QR.
The card has printed the QR directly ever since.

**Stray white/colored specks scattered across the whole card, including
plain black areas.** Not a geometry problem — turning off Bambu Studio's
"Purge into objects' infill" didn't fix it either. The actual cause was
travel-move oozing: dense multi-line text (and the QR pattern) has dozens
to thousands of disconnected islands, and the nozzle travelling between
them without adequate Z-hop clearance/retraction left tiny blobs on the
surface. Fixed by: Z-hop set to **Normal Lift** (not Auto Lift, which
skips lifting over "safe" flat areas — exactly the case between every
letter/module) at ≥0.4mm, increased retraction length, enabling **avoid
crossing perimeters**, reduced travel speed, and slightly lower nozzle
temperature. Confirmed clean on a real print, including the full printed
QR scanning correctly.

## Testing settings changes on a small swatch first

Re-printing the whole card to test a settings tweak is slow. Two small
diagnostic coupons are cropped straight out of the real design so you can
test in a few minutes instead:

| Files                                   | What it tests                                    |
|-------------------------------------------|------------------------------------------------------|
| `swatch1_base.stl` + `swatch1_red.stl`    | "RESET" in red — big bold letters                     |
| `swatch2_base.stl` + `swatch2_white.stl`  | The QR code + "SCAN TO SAVE" caption — dense module pattern |

Print each pair together (same as the full card: same saved position, one
AMS slot each). If stray specks show up on either, revisit the settings
above before reprinting the full card. `swatch2` is the more demanding
test since it contains the full dense QR pattern — if it prints and scans
cleanly, the full card should too.

Regenerate them (e.g. after changing the design) via:
```bash
for p in swatch1_base swatch1_red swatch2_base swatch2_white; do
    openscad -D "part=\"$p\"" -o "$p.stl" --export-format=binstl card.scad
done
```

## Adjusting the design

All layout constants (margins, font sizes, QR size, card dimensions, recess
depth) are declared near the top of `card.scad` with comments. Text width
can't be queried in this OpenSCAD version (2021.01), so sizes were tuned by
rendering and eyeballing clearance against the QR, the vertical divider,
and card edges — if you change any text, re-render (`openscad -o
preview.png --viewall --autocenter --projection=ortho card.scad`) and check
for overlap before printing. The vertical divider accent is deliberately
sized to sit only in the gap between the RESET/name block and the title
block (not the full card height) so it can't collide with either as text
sizes get tuned — if you resize things enough that the gap changes, its
`divider_top`/`divider_bottom` in `red_shape_2d()` may need adjusting too.
