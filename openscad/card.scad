// ============================================================
// RESET WALK business card — Lloyd Merchant
// "Modern Minimalist" layout, adapted from a design mockup into the
// validated multi-color AMS printing pipeline (real data-driven QR,
// stroke-fattened text, full manifold/overlap verification).
//
// Multi-color card for Bambu Lab P1S + AMS.
//
// Prints as THREE separate STL bodies sharing one coordinate
// system (do not move them after import):
//   - card_base.stl   (black)
//   - card_red.stl    (red)
//   - card_white.stl  (white)
// Import all three into Bambu Studio at their saved position
// (uncheck "auto arrange" / don't let it move parts), assign
// each object to its own AMS filament slot, then slice as one
// plate — Bambu Studio purges/swaps filament within each layer
// to print the flush multi-color surface.
//
// See build.sh to regenerate the three STL files, or open this
// file directly in the OpenSCAD GUI and use the "part" variable
// in the Customizer to preview/export each body individually.
// ============================================================

// The QR is printed directly in two colors (white background, black
// modules) — see the qr_shape() comment below. Confirmed on a real print
// (with tuned retraction/Z-hop/travel-speed settings — see README) to
// print and scan reliably.
include <qr_data.scad>  // provides qr_matrix + qr_modules, encodes Lloyd's vCard

/* [Part selection] */
// Which body to render: "all" (preview only), "base", "red", "white",
// or one of the small diagnostic swatches (see the swatch section below)
part = "all"; // [all, base, red, white, swatch1_base, swatch1_red, swatch2_base, swatch2_white]

/* [Card dimensions, mm] */
card_w = 88.9;      // standard US business card width
card_h = 50.8;      // standard US business card height
card_t = 1.6;       // total thickness
corner_r = 3.0;     // corner rounding radius
top_layer = 0.6;    // depth of the color-swap zone at the top surface (multiple of layer height)

/* [Typography] */
font_bold = "Liberation Sans:style=Bold";

// At small point sizes, bold sans caps produce strokes thinner than a
// 0.4mm nozzle reliably prints, so the slicer's thin-wall handling can
// drop or fuse them. Fattening every glyph outward by this amount (added
// to both edges of every stroke) fixes that without redrawing the whole
// layout. 0.18 was settled on after an earlier, smaller value (0.13)
// still left a few letters printing wrong on a real card.
stroke_fatten = 0.18;

$fn = 48;

// ---------- helpers ----------

module bold_text(t, size, halign = "left") {
    offset(delta = stroke_fatten)
        text(t, size = size, font = font_bold, halign = halign, valign = "baseline");
}

module rounded_rect(w, h, r) {
    hull() {
        for (x = [r, w - r])
            for (y = [r, h - r])
                translate([x, y]) circle(r = r);
    }
}

// QR code as a 2D shape, drawn with lower-left corner at [0,0],
// occupying size x size mm. A QR scanner needs standard polarity —
// dark modules on a light field, including a light quiet zone — so
// this is the WHITE body: a solid square (light modules + quiet
// zone) with the dark modules punched out, leaving the black base
// showing through as the "dark module" color.
module qr_shape(size) {
    quiet = 4; // modules of quiet zone (spec-recommended)
    total_modules = qr_modules + 2 * quiet;
    module_size = size / total_modules;
    // adjacent holes share exact edges, which trips up CGAL's manifold
    // check (many thousands of coincident edges); nudge every hole to
    // overlap its neighbors by a hair so there are no shared edges left.
    eps = module_size * 0.06;
    difference() {
        square([size, size]);
        for (row = [0 : qr_modules - 1]) {
            for (col = [0 : qr_modules - 1]) {
                if (qr_matrix[row][col] == 1) {
                    translate([
                        (col + quiet) * module_size - eps / 2,
                        (qr_modules - 1 - row + quiet) * module_size - eps / 2
                    ])
                    square([module_size + eps, module_size + eps]);
                }
            }
        }
    }
}

// ---------- layout (all coordinates in mm, origin = bottom-left of card) ----------
//
// Text is laid out with a top-down "cursor": cap_frac approximates how far
// a bold-caps baseline sits below the top of the em box (~0.75 x size for
// Liberation Sans Bold), and each row advances from the previous baseline.
// Font-metric queries aren't available in this OpenSCAD version, so sizes
// were chosen conservatively for character count and confirmed by render.
//
// Two blocks on the left (RESET + name up top, a two-tone title pinned to
// the bottom), a QR + caption on the right, and a short vertical divider
// accent filling the empty gap between the two left blocks — sized to sit
// entirely in that gap rather than spanning the full card height, so nothing
// can grow into it as text sizes get tuned.

margin_l = 8.0;
margin_r = 6.0;
margin_top = 6.0;
margin_bottom = 5.0;
cap_frac = 0.75;

logo_size    = 9.0;   // "RESET"
name_size    = 3.4;   // "LLOYD MERCHANT"
title_size   = 2.15;  // "COMMUNITY MITIGATION" / "VOLUNTEER COORDINATOR"
caption_size = 2.2;   // "SCAN TO SAVE"

qr_size = 30.0; // 30mm / 61 total modules (53 data + 4 quiet zone each side) = ~0.49mm/module
qr_x = card_w - margin_r - qr_size;
qr_y = (card_h - qr_size) / 2;

module red_shape_2d() {
    // "RESET" wordmark, top-left
    reset_baseline = card_h - margin_top - logo_size * cap_frac;
    translate([margin_l, reset_baseline])
        bold_text("RESET", size = logo_size);

    // two-tone title, top half (red) — bottom-left, above its white half
    title2_baseline = margin_bottom + 0.5;
    title1_baseline = title2_baseline + title_size * 1.45;
    translate([margin_l, title1_baseline])
        bold_text("COMMUNITY MITIGATION", size = title_size);

    // short vertical divider accent, filling the gap between the RESET/
    // name block above and the title block below (not the full card
    // height, so it can't collide with either as sizes get tuned)
    name_baseline = reset_baseline - logo_size * 0.35 - 2.0;
    divider_top = name_baseline - 1.5;
    divider_bottom = title1_baseline + title_size * cap_frac + 1.5;
    translate([margin_l, divider_bottom])
        square([1.2, divider_top - divider_bottom]);
}

module white_shape_2d() {
    // "LLOYD MERCHANT" name, under RESET
    reset_baseline = card_h - margin_top - logo_size * cap_frac;
    name_baseline = reset_baseline - logo_size * 0.35 - 2.0;
    translate([margin_l, name_baseline])
        bold_text("LLOYD MERCHANT", size = name_size);

    // two-tone title, bottom half (white) — directly under its red half
    title2_baseline = margin_bottom + 0.5;
    translate([margin_l, title2_baseline])
        bold_text("VOLUNTEER COORDINATOR", size = title_size);

    // QR code
    translate([qr_x, qr_y])
        qr_shape(qr_size);

    // caption under the QR, centered under the QR block
    cap_cx = qr_x + qr_size / 2;
    cap_baseline = qr_y - 2.0 - caption_size * cap_frac;
    translate([cap_cx, cap_baseline])
        bold_text("SCAN TO SAVE", size = caption_size, halign = "center");
}

// ---------- solid bodies ----------

module base_outline_2d() {
    rounded_rect(card_w, card_h, corner_r);
}

module black_part() {
    difference() {
        linear_extrude(height = card_t) base_outline_2d();
        // color-swap band: RESET/name/title/divider/QR/caption, all in
        // one flat recess
        translate([0, 0, card_t - top_layer])
            linear_extrude(height = top_layer + 0.02)
                union() {
                    red_shape_2d();
                    white_shape_2d();
                }
    }
}

module red_part() {
    translate([0, 0, card_t - top_layer])
        linear_extrude(height = top_layer)
            intersection() {
                base_outline_2d();
                red_shape_2d();
            }
}

module white_part() {
    translate([0, 0, card_t - top_layer])
        linear_extrude(height = top_layer)
            intersection() {
                base_outline_2d();
                white_shape_2d();
            }
}

// ---------- diagnostic swatches ----------
//
// Small coupons cropped out of the real design, for testing print
// settings (retraction, Z-hop, travel speed, nozzle...) in a few
// minutes instead of re-printing the whole card each time.
//   - swatch1: "RESET" in red — big bold letters
//   - swatch2: the QR code + "SCAN TO SAVE" caption — the dense module
//     pattern, the most demanding thing on the card to print
// Print each swatch's base + color pair together (same as the full
// card: same position, one AMS slot each).

module crop_box_3d(x0, y0, x1, y1) {
    translate([x0, y0, -1])
        cube([x1 - x0, y1 - y0, card_t + 2]);
}

swatch1_box = [4, 33, 55, 46];    // around "RESET"
swatch2_box = [48, 4, 85, 41];    // around the QR + "SCAN TO SAVE"

module swatch1_base() {
    translate([-swatch1_box[0], -swatch1_box[1], 0])
        intersection() { black_part(); crop_box_3d(swatch1_box[0], swatch1_box[1], swatch1_box[2], swatch1_box[3]); }
}
module swatch1_red() {
    translate([-swatch1_box[0], -swatch1_box[1], 0])
        intersection() { red_part(); crop_box_3d(swatch1_box[0], swatch1_box[1], swatch1_box[2], swatch1_box[3]); }
}
module swatch2_base() {
    translate([-swatch2_box[0], -swatch2_box[1], 0])
        intersection() { black_part(); crop_box_3d(swatch2_box[0], swatch2_box[1], swatch2_box[2], swatch2_box[3]); }
}
module swatch2_white() {
    translate([-swatch2_box[0], -swatch2_box[1], 0])
        intersection() { white_part(); crop_box_3d(swatch2_box[0], swatch2_box[1], swatch2_box[2], swatch2_box[3]); }
}

// ---------- output selection ----------

if (part == "base") {
    color("black") black_part();
} else if (part == "red") {
    color("red") red_part();
} else if (part == "white") {
    color("white") white_part();
} else if (part == "swatch1_base") {
    color("black") swatch1_base();
} else if (part == "swatch1_red") {
    color("#c81e2c") swatch1_red();
} else if (part == "swatch2_base") {
    color("black") swatch2_base();
} else if (part == "swatch2_white") {
    color("white") swatch2_white();
} else {
    color("black") black_part();
    color("#c81e2c") red_part();
    color("white") white_part();
}
