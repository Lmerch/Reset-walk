// ============================================================
// RESET WALK business card — Lloyd Merchant
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
// modules) — see the qr_shape() comment below. An earlier revision
// replaced this with a plain pocket + separately-printed sticker because
// this seemed unreliable on an AMS; a real print with tuned retraction/
// Z-hop/travel-speed settings (see README) proved it actually works, so
// it's back.
include <qr_data.scad>  // provides qr_matrix + qr_modules, encodes Lloyd's vCard

/* [Part selection] */
// Which body to render: "all" (preview only), "base", "red", "white",
// or one of the small diagnostic swatches (see the swatch section below)
part = "all"; // [all, base, red, white, swatch1_base, swatch1_red, swatch2_base, swatch2_white]

/* [Card dimensions, mm] */
card_w = 85.6;      // ISO/credit-card width
card_h = 54.0;      // ISO/credit-card height
card_t = 3.0;       // total thickness
corner_r = 3.0;     // corner rounding radius
top_layer = 0.8;    // depth of the color-swap zone at the top surface (multiple of layer height)

/* [Typography] */
font_bold = "Liberation Sans:style=Bold";

// At small point sizes, bold sans caps produce strokes thinner than a
// 0.4mm nozzle reliably prints (a 2.2mm cap height is only ~0.35mm
// stroke), so the slicer's thin-wall handling can drop or fuse them —
// this showed up as illegible letters after slicing. Fattening every
// glyph outward by this amount (added to both edges of every stroke)
// fixes that without redrawing the whole layout. Widened from 0.13 to
// 0.18 after a real print still showed a few letters printing wrong —
// neither the exact letters nor the cause were pinned down, so this is
// a broader safety margin rather than a targeted fix.
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
    quiet = 4; // modules of quiet zone (spec-recommended, no need to skimp now this actually prints reliably)
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
// Pared down from the original design (name/title/department/phone/QR) to
// just name + logo + QR: all contact details live in the QR's vCard now,
// so the card doesn't need to repeat them in print, and fewer/bigger text
// islands are also far more reliable to print in color via AMS.

margin_l = 5.5;
margin_r = 4.0;
margin_top = 5.0;
margin_bottom = 4.5;
cap_frac = 0.75;

name_size    = 5.9;
logo_size    = 10.0;
caption_size = 3.0;

qr_size = 27.0; // 27mm / 61 total modules (53 data + 4 quiet zone each side) = ~0.44mm/module
qr_x = card_w - margin_r - qr_size;
qr_y = 36.05 - qr_size; // hangs from just under the divider — see white_shape_2d

module red_shape_2d() {
    // "LLOYD MERCHANT" — top line, spans most of the card width now that
    // nothing else shares this row
    name_baseline = card_h - margin_top - name_size * cap_frac;
    translate([margin_l, name_baseline])
        bold_text("LLOYD MERCHANT", size = name_size);

    // divider accent under the name
    divider_y = name_baseline - name_size * 0.35 - 1.8;
    translate([margin_l, divider_y])
        square([34, 0.6]);

    // "RESET" wordmark, bottom-left
    reset_baseline = margin_bottom + 1.0;
    translate([margin_l, reset_baseline])
        bold_text("RESET", size = logo_size);
}

module white_shape_2d() {
    // QR code
    translate([qr_x, qr_y])
        qr_shape(qr_size);

    // caption under the QR, centered under the QR block
    cap_cx = qr_x + qr_size / 2;
    cap_baseline = qr_y - 2.0 - caption_size * cap_frac;
    translate([cap_cx, cap_baseline])
        bold_text("SCAN ME", size = caption_size, halign = "center");
}

// ---------- solid bodies ----------

module base_outline_2d() {
    rounded_rect(card_w, card_h, corner_r);
}

module black_part() {
    difference() {
        linear_extrude(height = card_t) base_outline_2d();
        // color-swap band: name/RESET/QR/caption, all in one flat recess
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
// minutes instead of re-printing the whole card each time. Two are
// provided:
//   - swatch1: "RESET" in red — big bold letters
//   - swatch2: QR pocket + "SCAN ME" caption in white — the only
//     remaining white content since the design was pared down
// If specks show up on both equally, it's a general travel/retraction
// setting. Print each swatch's base + color pair together (same as the
// full card: same position, one AMS slot each).

module crop_box_3d(x0, y0, x1, y1) {
    translate([x0, y0, -1])
        cube([x1 - x0, y1 - y0, card_t + 2]);
}

swatch1_box = [3, 3, 52, 15];    // around "RESET"
swatch2_box = [52, 3, 84, 38];   // around the QR pocket + "SCAN ME"

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
