PUFFPUFF / CORAL GARDEN

Coral-Garden.af is the native Affinity master, saved in Affinity with editable
vector layers. Coral-Garden.svg is the portable master and Coral-Garden.png
is the exported design sheet. The three individual SVGs have transparent
backgrounds and separate body, branch, highlight and polyp elements. No faces.
Honey Puffs is a low, wide cluster of ruffled lobes, with no tall central stalk.
The internal honeyCups file/key remains stable for existing art references.

PALETTE
Lagoon        #AADED0     sunlit water
Sea glass     #D3EBCE     wet translucent surfaces
Peach         #F49B87     Peach Sprig / primary coral accent
Rose          #EB8196     Rosy Fan
Honey         #F2BA76     Honey Puffs / rewards
Bloom         #FFD6A0     completed patch
Sand          #EDDFB0     warm shoreline
Ink           #143F42     readable dark teal text
Sleepy        #507477     unlit coral

ANIMATION IN SWIFT
The original curves are mirrored in Art/CoralPaths.swift. Art/CoralArt.swift
draws them as native SwiftUI vectors, using the existing Rossark-derived
ReefMotion helpers and the shared ocean clock. No animation dependency.

Awake: a base-anchored 1.15-degree sway on a six-second cycle, with a smaller
opposing branch movement. Sleepy: still and muted. Completion:
a warm golden wave spreads from the final tap, with up to 7% vertical
stretch, two thin water rings and a short burst of rising bubbles. The
celebration clock stops after 1.9 seconds; the golden finish remains.
Reopening an already completed patch shows the finish without replaying
the celebration or granting rewards. Reduce Motion shows the final colour
without sway, stretch, rings or particles.

The three species are decorative. They do not add new tile rules. Resting
pebbles and current/star badges retain their meanings. Taps, hints, rewards,
budgets and existing saved boards are unchanged by the artwork.

RESTING PEBBLE
restingPebble.svg is the editable source for the inactive stone tile. Its
matte grey circle and smooth stone use muted Lagoon greys. The native
RestingPebbleTile in CoralArt.swift draws matching stone curves without
caustics, motion or interactive highlights.

DIRECTIONAL CORALS
Directional-Corals.af is the editable native Affinity master for Tide Spires
(up/down, seafoam #70C7B5) and Drift Shelf (left/right, apricot #E9A279).
Directional-Corals.svg is the matching portable sheet; tideSpires.svg and
driftShelf.svg are individual transparent vectors. Directional-Corals-Preview.png
shows the native app rendering. Both are faceless.

The special tiles use these distinct vertical/horizontal silhouettes and centered
arrow icons. They retain the existing root-anchored sway and completion colors.
Ordinary tiles keep the original three species; game rules and saves are unchanged.
The new paths come from scripts/make-directional-corals.py. Preserve later edits
to the Affinity master; the script does not overwrite any .af document.
