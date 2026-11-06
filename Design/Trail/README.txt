First reef artwork

First-Reef-Art.af is the editable Affinity master. First-Reef-Art.svg and
First-Reef-Art.png are the matching portable sheet and preview. Individual
SVGs have transparent backgrounds; chest accents are mint, coral and gold,
each with closed/open poses. Named vector layers match Art/TrailArt.swift.

Gentle-Current.gif previews the subtle live coral and kelp motion. The app
animates the original vector paths, with each kelp frond rooted separately;
there are no raster sprite animations. Reduce Motion holds them still.
Bonus-Course-Preview.png shows the same reef used for the post-exploration putt.

Do not regenerate over later user edits to the Affinity master. The creation
script is scripts/make-trail-art.py; future edits must be reconciled into the
native paths before shipping.

Reef-All-Clear.af is the editable Affinity master for the sea-glass completion sign and matching map checkbox. The combined SVG includes a preview-water layer; Reef-All-Clear-Sign.svg and Reef-All-Clear-Check.svg have transparent backgrounds. ReefClearArt.swift uses the same vector contours. Preserve later edits to the Affinity master.

November 2, 2026: First-Reef-Affinity-Export.svg is the direct export of the
user-edited Affinity master. scripts/import-trail-art.py imports all ten named
assets, preserving inner transforms (including the corrected wood grain and
vertical bands). It generates the native TrailArt geometry, individual SVGs,
and the portable sheet. It intentionally excludes only the five placeholder
pearls in each open chest; actual saved supplies are drawn by ReefTreasureArt
with a finite rising-bubble animation. The .af master and raw export retain the
user's editable artwork intact. Do not run make-trail-art.py over this revision.
