#!/usr/bin/env bash
# Regenerates the three STL bodies for the Lloyd Merchant RESET WALK
# business card from card.scad. Requires OpenSCAD on PATH.
#
# Usage: ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

for part in base red white; do
    echo "Exporting card_${part}.stl ..."
    openscad -D "part=\"${part}\"" -o "card_${part}.stl" --export-format=binstl card.scad
done

echo "Done. Import card_base.stl, card_red.stl, card_white.stl together into" \
     "Bambu Studio (same position, do not move them) and assign each to its" \
     "own AMS filament slot."
