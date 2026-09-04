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

include <qr_data.scad>  // provides qr_matrix (53x53) + qr_modules, encodes Lloyd's vCard

/* [Part selection] */
// Which body to render: "all" (preview only), "base", "red", "white"
part = "all"; // [all, base, red, white]

/* [Card dimensions, mm] */
card_w = 85.6;      // ISO/credit-card width
card_h = 54.0;      // ISO/credit-card height
card_t = 3.0;       // total thickness
corner_r = 3.0;     // corner rounding radius
top_layer = 0.8;    // depth of the color-swap zone at the top surface (multiple of layer height)

/* [Typography] */
font_bold = "Liberation Sans:style=Bold";
font_reg  = "Liberation Sans:style=Regular";

// At small point sizes, bold sans caps produce strokes thinner than a
// 0.4mm nozzle reliably prints (a 2.2mm cap height is only ~0.35mm
// stroke), so the slicer's thin-wall handling can drop or fuse them —
// this showed up as illegible letters after slicing. Fattening every
// glyph outward by this amount (added to both edges of every stroke)
// fixes that without redrawing the whole layout.
stroke_fatten = 0.13;

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
    quiet = 3; // modules of quiet zone (spec recommends 4; 3 still scans reliably and buys back module size)
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

margin_l = 5.5;
margin_r = 3.0;
margin_top = 5.0;
margin_bottom = 4.5;
cap_frac = 0.75;

name_size    = 4.2;
title_size   = 2.6;
org_size     = 2.3;
logo_size    = 8.0;
caption_size = 2.3;

qr_size = 24.0; // 24mm / 59 total modules (53 data + 3 quiet zone each side) = ~0.41mm/module, just above a 0.4mm nozzle's reliable minimum feature size
qr_x = card_w - margin_r - qr_size;
qr_y = card_h - margin_top - qr_size;

module red_shape_2d() {
    // "LLOYD MERCHANT" — top line
    name_baseline = card_h - margin_top - name_size * cap_frac;
    translate([margin_l, name_baseline])
        bold_text("LLOYD MERCHANT", size = name_size);

    // divider line under the name
    divider_y = name_baseline - name_size * 0.35 - 1.8;
    translate([margin_l, divider_y])
        square([26, 0.6]);

    // "RESET" wordmark, bottom-left
    reset_baseline = margin_bottom + 1.0;
    translate([margin_l, reset_baseline])
        bold_text("RESET", size = logo_size);
}

module white_shape_2d() {
    name_baseline = card_h - margin_top - name_size * cap_frac;
    divider_y = name_baseline - name_size * 0.35 - 1.8;

    // job title, two lines
    line1_baseline = divider_y - 2.6 - title_size * cap_frac;
    translate([margin_l, line1_baseline])
        bold_text("COMMUNITY MITIGATION &", size = title_size);
    line2_baseline = line1_baseline - title_size * 1.45;
    translate([margin_l, line2_baseline])
        bold_text("VOLUNTEER COORDINATOR", size = title_size);

    org_baseline = line2_baseline - title_size * 0.9 - org_size * cap_frac;
    translate([margin_l, org_baseline])
        bold_text("ROANOKE POLICE DEPARTMENT", size = org_size);
    phone_baseline = org_baseline - org_size * 1.55;
    translate([margin_l, phone_baseline])
        bold_text("(540) 853-5304", size = org_size);

    // QR code
    translate([qr_x, qr_y])
        qr_shape(qr_size);

    // caption under QR, centered under the QR block
    cap_cx = qr_x + qr_size / 2;
    cap_line1_baseline = qr_y - 2.2 - caption_size * cap_frac;
    translate([cap_cx, cap_line1_baseline])
        bold_text("SCAN TO SAVE", size = caption_size, halign = "center");
    cap_line2_baseline = cap_line1_baseline - caption_size * 1.45;
    translate([cap_cx, cap_line2_baseline])
        bold_text("CONTACT", size = caption_size, halign = "center");
}

// ---------- solid bodies ----------

module base_outline_2d() {
    rounded_rect(card_w, card_h, corner_r);
}

module black_part() {
    difference() {
        linear_extrude(height = card_t) base_outline_2d();
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

// ---------- output selection ----------

if (part == "base") {
    color("black") black_part();
} else if (part == "red") {
    color("red") red_part();
} else if (part == "white") {
    color("white") white_part();
} else {
    color("black") black_part();
    color("#c81e2c") red_part();
    color("white") white_part();
}
