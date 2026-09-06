# Lloyd Merchant business card — OpenSCAD / Bambu P1S + AMS

`card.scad` generates a 3.375" x 2.125" (85.6 x 54mm, ISO/credit-card size)
business card as **three separate solid bodies** that fit together into one
flush 3mm-thick card:

| File              | Color | Content                                                                 |
|--------------------|-------|--------------------------------------------------------------------------|
| `card_base.stl`    | Black | The card body, with the red/white artwork recessed 0.8mm into the top   |
| `card_red.stl`     | Red   | "LLOYD MERCHANT" name, divider accent, "RESET" wordmark                 |
| `card_white.stl`   | White | The QR code, "SCAN ME" caption                                          |

All three share the same coordinate system and were verified to be
watertight and mutually non-overlapping (their volumes sum exactly to the
full card volume) — so they combine into one solid card with no gaps or
interference.

## Why the card only has two words and a QR

The original design also printed the job title, department, and phone
number directly on the card. All of that is redundant once the QR's vCard
carries the same information — scanning it gets you the full contact
details — so the card itself was pared down to just the name, the "RESET"
wordmark, and the QR/"SCAN ME". This is also a print-reliability win: fewer
and bigger text islands mean far fewer color-swap travel moves for the
printer to get through.

## The QR is printed directly in two colors — no sticker

An early version tried this and it looked unreliable in testing, so for a
while the card had a plain recessed pocket for a separately-printed
adhesive sticker instead. **A real print with properly tuned settings
proved the in-model QR actually works reliably** (see Print settings
below), so that's what's here now — no sticker needed.

The QR encodes a vCard for Lloyd Merchant (name, title, department, phone)
generated from `qr_data.scad`. Scanning it saves the contact directly,
matching the "SCAN ME" caption. To change the encoded data (e.g. add an
email or website), regenerate `qr_data.scad`:

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
   each layer of the top 0.8mm band to print the flush multi-color surface,
   including the QR's dense module pattern.
5. Recommended print settings: 0.4mm nozzle, 0.2mm layer height (the 0.8mm
   color band = 4 layers), 2-3 walls, 100% infill (card is thin/solid — no
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
fatten every stroke before it's cut/extruded. `stroke_fatten` is currently
0.18 (raised from an initial 0.13 after a print still showed a handful of
letters coming out wrong — the exact cause wasn't pinned down, so this is
a broader safety margin rather than a targeted fix; if letters are still
off, try raising it further).

**The QR code printed as sparse noise, not a dense pattern (this was
wrong).** At the time this looked like a hard AMS limitation (~2800
filament swaps packed into one small area, many between diagonally-
touching modules narrower than a nozzle width) and the design was changed
to a plain pocket + separately-printed sticker to work around it. A later
print with corrected retraction/Z-hop/travel-speed settings (next item)
showed the real printed QR working fine, so that diagnosis was wrong (or
at least incomplete) — the speckling below was the actual cause, and fixing
it also fixed the QR.

**Stray white/colored specks scattered across the whole card, including
plain black areas.** Not a geometry problem — turning off Bambu Studio's
"Purge into objects' infill" didn't fix it either. The actual cause was
travel-move oozing: dense multi-line text (and, it turned out, the QR
pattern) has dozens to thousands of disconnected islands, and the nozzle
travelling between them without adequate Z-hop clearance/retraction left
tiny blobs on the surface. Fixed by: Z-hop set to **Normal Lift** (not Auto
Lift, which skips lifting over "safe" flat areas — exactly the case
between every letter/module) at ≥0.4mm, increased retraction length,
enabling **avoid crossing perimeters**, reduced travel speed, and slightly
lower nozzle temperature. Confirmed clean on a real print of the `swatch1`
coupon, and confirmed the *full* printed QR scans correctly on a real
print with these settings.

## Testing settings changes on a small swatch first

Re-printing the whole card to test a settings tweak is slow. Two small
diagnostic coupons are cropped straight out of the real design so you can
test in a few minutes instead:

| Files                                   | What it tests                                    |
|-------------------------------------------|------------------------------------------------------|
| `swatch1_base.stl` + `swatch1_red.stl`    | "RESET" in red — big bold letters                     |
| `swatch2_base.stl` + `swatch2_white.stl`  | The QR code + "SCAN ME" caption — dense module pattern |

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
rendering and eyeballing clearance against the QR and card edges — if you
change any text, re-render (`openscad -o preview.png --viewall --autocenter
--projection=ortho card.scad`) and check for overlap before printing.
