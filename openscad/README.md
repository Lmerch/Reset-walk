# Lloyd Merchant business card — OpenSCAD / Bambu P1S + AMS

`card.scad` generates a 3.375" x 2.125" (85.6 x 54mm, ISO/credit-card size)
business card as **three separate solid bodies** that fit together into one
flush 3mm-thick card:

| File              | Color | Content                                                                 |
|--------------------|-------|--------------------------------------------------------------------------|
| `card_base.stl`    | Black | The card body, with the red/white artwork recessed 0.8mm into the top, plus a shallow 0.15mm QR sticker pocket |
| `card_red.stl`     | Red   | Name, divider line, "RESET" wordmark                                    |
| `card_white.stl`   | White | Title, department, phone, "SCAN TO SAVE CONTACT"                        |

All three share the same coordinate system and were verified to be
watertight and mutually non-overlapping (their volumes sum exactly to the
card volume minus the QR pocket) — so they combine into one solid card with
no gaps or interference.

## The QR code is a separate applied sticker, not printed in color

The first version tried to print the actual QR pattern (53x53 modules) in
two AMS filament colors, like the text. **That doesn't work**: it requires
~2800 filament swaps within one small area, most of them between
diagonally-touching modules, which leaves slivers of material far thinner
than a 0.4mm nozzle can resolve. A real print confirmed this — sparse white
noise instead of a dense QR pattern, illegible to any scanner.

So the 3D-printed card now only has a **plain, bare 0.15mm pocket** where
the QR goes (fully AMS-friendly — one flat color-swap region, same as the
text). The actual QR is printed separately and applied as a sticker:

```bash
pip install qrcode
python3 sticker.py
```

This writes `sticker.svg` (vector, exact 24x24mm — print this for best
results) and `sticker.png` (high-res raster preview/fallback). Print it on
adhesive label paper at 100% scale / "actual size" (don't let your print
dialog "fit to page"), cut along the 24x24mm square, and stick it into the
card's QR pocket after printing. The pocket is 0.15mm deep so a typical
label sheet sits flush with the surrounding surface.

To change the encoded data (e.g. add an email or website), edit the
`vcard` block near the top of `sticker.py` and rerun it.

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
   each layer of the top 0.8mm band to print the flush multi-color text
   surface (the QR pocket is single-color, no swaps needed there).
5. Recommended print settings: 0.4mm nozzle, 0.2mm layer height (the 0.8mm
   color band = 4 layers), 2-3 walls, 100% infill (card is thin/solid — no
   real benefit to sparse infill), no supports needed (flat, no overhangs).
   In Bambu Studio, also enable **Advanced > Detect thin walls** — this
   design leans on it for the small text to come out solid instead of
   getting skipped as sub-perimeter-width features.
6. After printing, apply the QR sticker from `sticker.py`/`sticker.svg`
   into the recessed pocket (top-right, where the QR was on the reference
   design).

### Why the small text vanished at first, and how it's fixed now

The first version's title/department text sized letters directly off cap
height (e.g. a 2.2mm cap height), which gives bold sans strokes only
~0.35mm wide — thinner than a 0.4mm nozzle can reliably lay down, so the
slicer's thin-wall handling dropped or fused them. Two fixes are baked into
`card.scad` now:
- Every piece of text goes through the `bold_text()` helper, which applies
  `offset(delta = stroke_fatten)` (0.13mm) to fatten every stroke by ~0.26mm
  total before it's cut/extruded — checked by rendering a close-up top-down
  crop to confirm letters (esp. counters in O/A/R/&) stayed open and
  didn't fuse together. Confirmed on a real print: text came out crisp.
- The title/department/caption font sizes were bumped up (title 2.3→2.6mm,
  department 2.2→2.3mm, caption 2.1→2.3mm) within the space freed up by
  trimming margin_r from 4.0 to 3.0mm.

If letters still come out faint or broken after slicing with "Detect thin
walls" on, raise `stroke_fatten` (try 0.18-0.20) and/or the individual
`*_size` variables further, re-render, and re-check clearance against the
QR pocket before reprinting.

## Adjusting the design

All layout constants (margins, font sizes, QR pocket size/depth, card
dimensions, recess depth) are declared near the top of `card.scad` with
comments. Text width can't be queried in this OpenSCAD version (2021.01),
so sizes were tuned by rendering and eyeballing clearance against the QR
pocket and card edges — if you change any text, re-render (`openscad -o
preview.png --viewall --autocenter --projection=ortho card.scad`) and check
for overlap before printing. If you resize the QR pocket (`qr_size` in
`card.scad`), update `QR_SIZE_MM` in `sticker.py` to match.

## Testing settings changes on a small swatch first

Re-printing the whole card to test each settings tweak is slow. Two small
diagnostic coupons are cropped straight out of the real design so you can
test in a few minutes instead:

| Files                                   | What it tests                                          |
|-------------------------------------------|---------------------------------------------------------|
| `swatch1_base.stl` + `swatch1_red.stl`    | "RESET" in red — large letters, few islands/travels     |
| `swatch2_base.stl` + `swatch2_white.stl`  | title/org/phone in white — small letters, many islands  |

Print each pair together (same as the full card: same saved position, one
AMS slot each). If stray specks show up on both swatches equally, it's a
general travel/retraction/Z-hop setting, not something specific to the fine
text — fix the settings once and reprint the full card. If they only show
up on swatch2, island density is the driver and the fine text may need to
get simplified/enlarged further, or you may need a smaller nozzle after all.

Regenerate them (e.g. after changing the design) via:
```bash
for p in swatch1_base swatch1_red swatch2_base swatch2_white; do
    openscad -D "part=\"$p\"" -o "$p.stl" --export-format=binstl card.scad
done
```
