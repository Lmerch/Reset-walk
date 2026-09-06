# Lloyd Merchant business card — OpenSCAD / Bambu P1S + AMS

`card.scad` generates a 3.375" x 2.125" (85.6 x 54mm, ISO/credit-card size)
business card as **three separate solid bodies** that fit together into one
flush 3mm-thick card:

| File              | Color | Content                                                                 |
|--------------------|-------|--------------------------------------------------------------------------|
| `card_base.stl`    | Black | The card body, with the red artwork recessed 0.8mm into the top, plus a shallow 0.15mm QR sticker pocket |
| `card_red.stl`     | Red   | "LLOYD MERCHANT" name, divider accent, "RESET" wordmark                  |
| `card_white.stl`   | White | "SCAN ME" caption under the QR                                          |

All three share the same coordinate system and were verified to be
watertight and mutually non-overlapping (their volumes sum exactly to the
card volume minus the QR pocket) — so they combine into one solid card with
no gaps or interference.

## Why the card only has two words and a QR

The original design also printed the job title, department, and phone
number directly on the card. All of that is redundant once the QR's vCard
carries the same information — scanning it gets you the full contact
details — so the card itself was pared down to just the name, the "RESET"
wordmark, and the QR/"SCAN ME". This is also a print-reliability win: fewer
and bigger text islands mean far fewer color-swap travel moves for the
printer to get through, which is what caused the speckling problems on the
denser first version (see the history below).

## The QR code is a separate applied sticker, not printed in color

An early version tried to print the actual QR pattern (53x53 modules) in
two AMS filament colors, like the text. **That doesn't work**: it requires
~2800 filament swaps within one small area, most of them between
diagonally-touching modules, which leaves slivers of material far thinner
than a 0.4mm nozzle can resolve. A real print confirmed this — sparse white
noise instead of a dense QR pattern, illegible to any scanner.

So the 3D-printed card only has a **plain, bare 0.15mm pocket** where the
QR goes (fully AMS-friendly — one flat color-swap region, same as the
text). The actual QR is printed separately and applied as a sticker:

```bash
pip install qrcode
python3 sticker.py
```

This writes `sticker.svg` (vector, exact 27x27mm — print this for best
results) and `sticker.png` (high-res raster preview/fallback). Print it on
adhesive label paper at 100% scale / "actual size" (don't let your print
dialog "fit to page"), cut along the 27x27mm square, and stick it into the
card's QR pocket after printing. The pocket is 0.15mm deep so a typical
label sheet sits flush with the surrounding surface.

The sticker's vCard still carries the full name/title/department/phone —
only the printed card text was trimmed down, not the contact details you
get from scanning. To change what's encoded (e.g. add an email or
website), edit the `vcard` block near the top of `sticker.py` and rerun it.

`sticker.py` uses `qrcode`'s `SvgPathFillImage` factory, not the plainer
`SvgPathImage` — the plain one leaves the "light" modules fully transparent
instead of white, which looks fine in most viewers (transparency shows
through as whatever's behind it) but rasterizes with no actual white
pixels, so a flattened/printed copy can have no dark/light contrast for a
scanner to read at all. Confirmed broken with the plain factory and fixed
with this one — verified by rasterizing `sticker.svg` at several DPIs and
decoding each with both pyzbar and OpenCV.

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
   design leans on it for the text to come out solid instead of getting
   skipped as sub-perimeter-width features.
6. Also check (this is what actually fixed the stray-speck problem, see
   history below): **Z-hop set to Normal Lift** (not Auto Lift) at ≥0.4mm,
   a bumped-up retraction length, **avoid crossing perimeters** enabled,
   reduced travel speed, and print temperature not needlessly high for
   your filament.
7. After printing, apply the QR sticker from `sticker.py`/`sticker.svg`
   into the recessed pocket.

## Print troubleshooting history

Kept here since the fixes are non-obvious and might recur if the design is
extended later.

**Small text was unreadable after slicing.** The first version sized
title/department text directly off cap height (e.g. 2.2mm), which gives
bold sans strokes only ~0.35mm wide — thinner than a 0.4mm nozzle can
reliably lay down, so the slicer's thin-wall handling dropped or fused
them. Fixed by routing all text through the `bold_text()` helper, which
applies `offset(delta = stroke_fatten)` (0.13mm) to fatten every stroke by
~0.26mm total before it's cut/extruded. Confirmed on a real print: text
came out crisp.

**The QR code printed as sparse noise, not a dense pattern.** Covered
above — switched to a plain pocket + separately-printed sticker.

**Stray white/colored specks scattered across the whole card, including
plain black areas.** Not a geometry problem — turning off Bambu Studio's
"Purge into objects' infill" didn't fix it either. The actual cause was
travel-move oozing: this design's original dense multi-line text had dozens
of disconnected letter islands, and the nozzle travelling between them
without adequate Z-hop clearance/retraction left tiny blobs on the surface.
Fixed by: Z-hop set to **Normal Lift** (not Auto Lift, which skips lifting
over "safe" flat areas — exactly the case between every letter) at ≥0.4mm,
increased retraction length, enabling **avoid crossing perimeters**,
reduced travel speed, and slightly lower nozzle temperature. Confirmed
clean on a real print of the `swatch1` coupon (see below) after these
changes. Reducing the amount of text (this revision) also reduces how much
this class of problem can recur, independent of the settings fix.

## Testing settings changes on a small swatch first

Re-printing the whole card to test a settings tweak is slow. Two small
diagnostic coupons are cropped straight out of the real design so you can
test in a few minutes instead:

| Files                                   | What it tests                                   |
|-------------------------------------------|----------------------------------------------------|
| `swatch1_base.stl` + `swatch1_red.stl`    | "RESET" in red — big bold letters                   |
| `swatch2_base.stl` + `swatch2_white.stl`  | QR pocket + "SCAN ME" caption — the only remaining white content |

Print each pair together (same as the full card: same saved position, one
AMS slot each). If stray specks show up on either, revisit the Z-hop/
retraction/travel-speed settings above before reprinting the full card.

Regenerate them (e.g. after changing the design) via:
```bash
for p in swatch1_base swatch1_red swatch2_base swatch2_white; do
    openscad -D "part=\"$p\"" -o "$p.stl" --export-format=binstl card.scad
done
```

## Adjusting the design

All layout constants (margins, font sizes, QR pocket size/depth, card
dimensions, recess depth) are declared near the top of `card.scad` with
comments. Text width can't be queried in this OpenSCAD version (2021.01),
so sizes were tuned by rendering and eyeballing clearance against the QR
pocket and card edges — if you change any text, re-render (`openscad -o
preview.png --viewall --autocenter --projection=ortho card.scad`) and check
for overlap before printing. If you resize the QR pocket (`qr_size` in
`card.scad`), update `QR_SIZE_MM` in `sticker.py` to match.
