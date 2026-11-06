Puff Puff — official character artwork

OFFICIAL MASTER: PuffPuff-Official.af
The user's own Affinity edits, approved October 25, 2026. Preserve these exact poses, proportions, tail, side fins, cheeks, eyes and smile. Previous numbered .af files are concept history.

PuffPuff-Official.svg is the direct vector export from that master. PuffPuff-Official.png is the direct Affinity preview. Neither is generated from app code.

PuffPuff-Puffed and PuffPuff-Happy are individual SVG/PNG exports from the imported native artwork. PuffPuff-Poses is the native comparison sheet. The large unlined fan is the tail; the two smaller ribbed fans are the side fins.

Updating the app after an approved artwork edit:
1. Edit the official Affinity master and export the whole document to PuffPuff-Official.svg, preserving named layers and the two pose groups.
2. Run python3 scripts/import-puffpuff-art.py from the project directory. It imports exact paths, transforms, styles and opacity into Art/PipPaths.swift without a package dependency. Unsupported SVG constructs stop the import for review.
3. Rebuild the app. PipView adds gentle bobbing, tail/fin motion and blinks using the existing Rossark-derived clock. Matching contours morph over 0.7 seconds; unique details fade in or out. Reduce Motion displays the approved resting pose immediately.

Never overwrite the official Affinity/SVG master from the older procedural character generator. Keep earlier versions when revising the design.
