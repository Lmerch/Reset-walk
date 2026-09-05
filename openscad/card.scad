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

// The QR itself is not part of this model — see the qr_shape() comment
// below for why, and sticker.py for the separately-printed QR graphic
// that gets applied into the pocket qr_shape() leaves for it.

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

// QR pocket, drawn with lower-left corner at [0,0], size x size mm.
//
// An earlier version punched every individual dark module as a hole in
// this square, i.e. tried to print the actual QR pattern in two colors.
// That doesn't work on an AMS: a 53x53-module code needs ~2800 filament
// swaps within one small area, most of them between diagonally-touching
// modules that leave slivers of material far thinner than a nozzle width.
// The slicer can't resolve that and drops most of it — confirmed on a
// real print (sparse white noise instead of a dense QR pattern).
//
// So this is now a plain solid pocket: one flat color-swap region like
// the text, fully AMS-friendly. The actual QR pattern is printed
// separately as an adhesive sticker (see sticker.py) sized to this
// pocket and applied after printing — see the README.
module qr_shape(size) {
    square([size, size]);
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

qr_size = 24.0; // sticker pocket size in mm — see sticker.py for the matching printable QR graphic
qr_x = card_w - margin_r - qr_size;
qr_y = card_h - margin_top - qr_size;
sticker_depth = 0.15; // recess depth for the QR pocket, ~1 sheet of adhesive label stock, so the applied sticker sits flush

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
        // color-swap band: name/title/org/phone/RESET/caption
        translate([0, 0, card_t - top_layer])
            linear_extrude(height = top_layer + 0.02)
                union() {
                    red_shape_2d();
                    white_shape_2d();
                }
        // separate, shallower QR sticker pocket (left bare — a printed
        // adhesive label goes here after printing, see sticker.py)
        translate([qr_x, qr_y, card_t - sticker_depth])
            linear_extrude(height = sticker_depth + 0.02)
                qr_shape(qr_size);
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
// provided to separate two possible causes of stray specks:
//   - swatch1: "RESET" in red — large letters, few islands/travels
//   - swatch2: title/org/phone in white — small letters, many islands
// If specks show up on both equally, it's a general travel/retraction
// setting, not specific to the fine text. Print each swatch's base +
// color pair together (same as the full card: same position, one AMS
// slot each).

module crop_box_3d(x0, y0, x1, y1) {
    translate([x0, y0, -1])
        cube([x1 - x0, y1 - y0, card_t + 2]);
}

swatch1_box = [3.5, 2, 42, 15];   // around "RESET"
swatch2_box = [2, 24, 50, 42];    // around title/org/phone

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
