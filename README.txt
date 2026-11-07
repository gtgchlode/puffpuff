puffpuff — first native SwiftUI chapter

APP NAMES
Selected App Store listing name: PuffPuff: Golf & Glow
Home Screen name: puffpuff
The listing name is set separately in App Store Connect. Keep the Xcode
bundle display name lowercase, with no spaces.

OPEN AND RUN
Open puffpuff.xcodeproj in Xcode. Select the puffpuff scheme and
an iPhone simulator, then Run. The target also supports My Mac for a native
desktop preview. Minimum deployment targets: iOS 17 and macOS 14.
No third-party packages, accounts, network calls, or package installation.
Running on a physical iPhone requires your Apple signing team in Xcode.

BUILD STATUS — 2026-10-27
The renamed puffpuff scheme builds successfully for iOS Simulator and
macOS. The iPhone hardware build also compiles with signing disabled.
The simulator app was installed and launched successfully.
Physical-device signing was not used for these preview builds. In Xcode, choose an iPhone simulator as the run destination.
The compiled puffpuff.app beside this file is the native Mac preview.

For command-line Mac previews, run bash scripts/build-mac-preview.sh.
This uses local ad-hoc signing and verifies the enabled sandbox. No Apple
account or certificate is needed. Never disable signing for Mac previews:
an unsigned Mac build uses a different save location from the Xcode app.
The script builds in a temporary directory to avoid cloud-folder metadata
interfering with signing. It prints the signed app path without replacing
the running preview or changing save files.

THE LOOP
Trail is now Home: launch into the saved cove and tap Bloom to resume.
Lives appear only in Bloom/Settings. Debug levels and refills are in Settings.
Hints can be refilled only at zero; their + disappears while any remain.
Power-up controls use the editable Design/Powerups/Powerups.af artwork.
Lit corals are brighter throughout, with no lit tile outline. Gold hints remain.

Coral Bloom is the main game. Tap a coral to flip it and its neighbors.
Wake the whole patch within its tap budget to earn 3 Glow and 1 shot.
The counter shows taps remaining / total before the first move. An
unfinished patch at zero taps offers five extra taps or Restart. A failed
attempt loses one life, once; starting and winning never spend lives.
Restart asks for confirmation and shows your lives. At zero lives,
Watch an ad grants 3 lives (free offline preview for now).
"Buy 5 more taps" and "Watch an ad" both grant five taps instantly for
free in this prototype. No payment, ad playback, SDK, or network call is
involved. Extra taps preserve the current board and persist across app
launches. At zero taps the board stays visible, with compact refill
controls beneath it. Adding taps keeps the board in view and resumes
the same pattern. They can be claimed again when the player runs out; restarting
or advancing clears the added allowance. Glow and shots are kept.
Winning on the final tap still counts. Restart replaces Undo. Hints
consume collected inventory, never taps. Optional pearl targets
earn 1 additional Glow. Hints follow a shortest solution and warn when
the current pattern cannot be solved with the remaining taps.

The first trail is Sunbeam Bay. Follow branching paths, collect three snacks,
and find home. Unknown branches reveal themselves as you explore; backtracking
is free. Tap a revealed blockage again to spend Glow: kelp 3, sand 4, fish 5.
Sand also opens a central shortcut. Three optional chests grant one-time hints
or shots and support further exploration.

Exploration now takes place inside close-up reef areas. Tap a nearby bubble
arrow and the camera follows Puff Puff into the next cove. Sandy shallows,
kelp groves, coral gardens and treasure pockets use the existing native art
at a larger scale. Unknown exits say Explore; known exits name the area.
Tap a blockage's artwork and Glow cost to clear it. Returning to Trail resumes
the saved area. Pause settles travel and Reduce Motion skips the camera move.
The familiar scrollable course overview is kept for bonus golf only. Bonus
putt resumes an existing attempt; Retry starts a fresh one.

The little folded map in the upper-left corner charts only places already
explored and marks Puff Puff's position in gold. Tap it to expand. In the large
map, tap a discovered landmark to see its name and status. Unknown places stay
hidden; viewing the map never travels or spends resources. Opening pauses the
scene (any swim settles at its saved destination); closing resumes exploration.
Its zigzag outline, paper folds and cream/teal colors make it read as a chart.

Bloom-earned Glow now wakes the reef when clearing passages. Uncleared areas
stay deeply shadowed; Puff Puff carries a small visibility halo. Pay the usual
clearance cost and a warm ripple wakes the nearby coral colors, glow and sway,
opening pools of light. Lighting persists with your saved clearances, and the
map reflects dark versus lit routes. No extra resource cost or save migration.
The opening lagoon starts lit; Reduce Motion shows the final light immediately.

In debug builds, open Settings from Home or Pause, then expand Debug refills
for repeatable +25 Glow, +5 shots or +3 hints. Each free top-up saves immediately;
the controls show current balances. Gameplay stays free of debug refill controls. Release builds omit
these controls and their grant API. Quest progress and Bloom boards stay intact.

After the goal and home, choose Bonus putt or keep exploring. Drag from Puff
Puff in the direction you want him to go; longer drags add power. Release to
putt. The same map supports bank shots and retains cleared obstacles.
Par 4, six putts per attempt. Reach home in four putts or fewer on the current
round to unlock the next reef and collect. One to three putts earn higher
optional rewards; a five- or six-putt finish earns no reward or progress.
Retries are free. The best qualifying score is saved, not accumulated, and a
failed or over-par retry cannot collect an earlier result. Only this first reef
is implemented; the next reef is coming later. The gift icon shows all five tiers.
Home entry always includes the deflation animation.

Save format 8 migrates earlier Trail layouts while preserving Bloom progress,
balances, claimed treasure and paid clearances. Bonus position, attempts,
best score and reward collection persist. Mac previews explicitly retain the
original com.puffpuffreef.prototype bundle ID; current Xcode signing settings
are left as configured. Use the same ID override for existing simulator saves.

Matching editable illustrations: Design/Trail/First-Reef-Art.af, with SVG,
PNG and native SwiftUI paths. Kelp fronds sway separately around planted roots;
lit corals bend gently with the current. All use the shared ocean clock and
respect pause and Reduce Motion. Unlit corals and pebbles remain still.

CONTENT
100 authored Bloom boards live in Resources/BloomLevels.json. All 100 are playable; burst coral starts at 85 with a free practice.
The first 10 boards are authored as a gentler introduction. The remaining
boards are generated from legal moves and saved as data. Every tap budget
covers a solution, with room for mistakes beyond the first one-tap lesson.
Tap budgets give room to experiment: 6/10/12/14 for patches 1–4,
18 for 5–9, 24 for 10–19, 30 for 20–40, 34 for 41–60,
38 for 61–80 and 42 for 81–100. Existing attempts and replay checkpoints
receive increases without losing their pattern, moves or added taps.
Later difficulty still needs play tuning. Candidate additions are
data-controlled and can be moved, mixed, or disabled while tuning:

  1:      one sleepy coral; one tap to learn the goal
  2:      a 2x2 patch; a tap reaches side neighbors, not diagonals
  3:      two guided taps; glowing coral can go sleepy and wake again
  4:      a guided 3x3 plus-shaped ripple
  5–9:    independent 3x3 practice, building from one to three taps
  10:     first 4x4 patch, still solvable in two taps
  11–20:  optional pearl targets (extra Glow for a tap goal)
  21:     resting pebbles introduced; later levels use them selectively
  27:     shaped reefs join the mix alongside familiar squares
  36–38:  up/down coral (self + above/below); one, one and two vertical tiles
  41–42:  horizontal current coral introduced; 5x5 boards
  43–45:  plain, pebble and up/down variations
  46–51: up/down + left/right mixes
  52–59: diagonals, pebbles and selected directional mixes
  60–70: whole rows/columns mixed with earlier tiles; 63/67 have no whole lines
  71–84: mixed line/directional/diagonal boards and breathers
  85–88: burst coral introduction, overlap practice and pebbles
  89–100: selective mixes and breathers; 100 ends this chapter

Legacy ten-stage data is retained for save compatibility; only the new
first reef is exposed through Home → Trail.
Bloom stops at 100. Replay lets you practice the just-won level for free, without rewards;
Home returns to the saved Trail cove. Shots are first-clear milestones only. Later saved progress is preserved.
Saved native progress is independent of the earlier browser demo.
Existing unfinished levels 1–10 migrate to the new lesson at the same
level. Currency, completed puzzles, and treasure-trail progress are kept.
Gold rings guide the first four levels. Only the coral to tap is highlighted.

SAVING AND PURCHASES
From Home or Pause, choose Saved reef. The game writes a
versioned progress.json in its Application Support/puffpuff directory
after each game action, navigation change, and background transition.
Atomic writes and progress-backup.json retain a previous valid snapshot.
Unreadable saves are preserved; the app recovers a backup or stops play
instead of silently replacing a damaged save with a fresh game.

Saved data includes the current board, moves and undo history, extra taps,
completed patches and best move counts, Glow, shots, cleared obstacles,
treasures, first-reef position/food/completion, legacy shot distances,
selected screen, and open cove. Save format 10 preserves earlier fields, debug checkpoints and the exploration/bonus round. Free purchase
and ad refills are recorded as prototype rewards, not paid transactions.
Earlier UserDefaults progress is imported and its original data is kept.
The Mac preview uses the same sandbox and bundle ID as the Xcode Mac app.
Its save lives in Library/Containers/com.puffpuffreef.prototype/Data/
Library/Application Support/puffpuff within the user's home directory.

The Restore purchases button has a StoreKit 2 path for verified permanent
purchases. Its product catalog is empty, so today's prototype makes no
App Store call or charge. Real products require App Store Connect setup.
Consumed tap packs must never be re-granted by Restore purchases.

iCloud sync is not enabled. Mac and iPhone simulator saves remain separate;
deleting the app may remove its local save. Cross-device sync and a durable
consumable purchase ledger are described in SAVE_AND_PURCHASE_PLAN.md.

PIP / ROSSARK MOTION
Pip's official Affinity/SVG contours are native SwiftUI Paths. Inflation
now changes the geometry continuously, including the mouth, spines and fins;
there is no pose crossfade. Exact official endpoint poses are preserved.
A rendered preview is in Design/PuffPuff/PuffPuff-Inflation.gif. There is
no web view or raster animation. The Rossark Motion Skill's SwiftUI
engine is adapted in Art/ReefMotion.swift, with attribution and MIT
license in THIRD_PARTY_NOTICES.txt.

An eight-second clock drives the whole fish: subtle float/breathing,
tail motion with a 110ms delay, offset fin motions, gliding pupils,
and asymmetric eyelid blinks. The trail's action clock drives swimming and the final putt's puff. Idle periods divide the loop length exactly.
Reduce Motion disables decorative fish/water motion and wake trails;
travel and the functional inflation cue remain. Background/offscreen
clocks pause and an action resumes at its saved destination. Tokens live in
PipChoreography.

FILES
  App/                 native entry point, Home, pause and temporary debug picker
  Game/CoralPuzzle     pulse rules, level loading, current-board hint solver
  Game/ReefStore       economy, persistent progress, obstacles and treasures
  Game/ReefSaveFile    versioned local saves, migration and recovery backup
  Game/ReefPurchases   StoreKit permanent-purchase restore foundation
  Views/               Bloom, trail map, treasure stages and shared styling
  Art/                 native Pip vectors and Rossark-derived motion
  Resources/           editable 100-level content pack

LIVING OCEAN INTERFACE
The native UI uses dark abyssal teal, sea glass, peach, rose, and honey gold.
Procedural caustics, soft moving light shafts, and seeded plankton are drawn
in SwiftUI Canvas. Irregular sea-glass polyps replace rectangular tiles;
translucent membranes and flowing lips replace floating white cards.
All controls use a shared bubble-shimmer hover/press treatment. Ambient
effects share a 30Hz clock and stop with Reduce Motion or app inactivity.
Sheets pause the ambient scene beneath them. No downloaded textures,
font packages, or additional dependencies are required.

CORAL GARDEN ART AND COMPLETION
Design/Corals/Coral-Garden.af is the editable native Affinity master.
It includes Peach Sprig, Rosy Fan and Honey Cups, a colour palette, and
sleepy/awake/finished states. Portable SVGs and a PNG design sheet accompany
it. The same curves are native SwiftUI vectors in Art/CoralPaths.swift.
Awake coral sways gently. Completing a patch sends a golden ripple from
the final tap, with a small stretch and rising bubbles, then leaves the
whole patch gold. The coral ripple resolves in 1.9 seconds; the shared one-shot clock stops
after the selected 2.05–3.25 second victory swim including its return. Reduce Motion
keeps the final colour without movement. No extra rewards are granted by
the animation, and reopening a completed patch does not replay it.

NEXT DESIGN WORK
Consult MECHANICS_CHECKLIST.md before adding tile types, power-ups, or
difficulty features. It records the user's ideas from play and the rule
details to settle when implementing them. AGENTS.md directs future work
in this project to consult and maintain that checklist.

Tune puzzle difficulty, object prices, exploration rewards, and the frequency
of new tiles through play. The first chapter uses matching editable Affinity course artwork. No purchases, backend, or App Store
packaging are implemented.

LAGOON & FONTS
Lagoon is the selected visual direction: mint water, sea-glass pebbles, sand
and dark teal text. Chalkboard SE is now the fixed font throughout the app,
with regular and bold weights. Font options are removed; older saved font
choices are ignored. No additional font dependency is needed.
Honey Puffs now uses a low, ruffled silhouette in both Affinity and Swift.

HOME, PAUSE & DEBUG START OPTIONS
Home offers Bloom and Trail. Gameplay has a Pause button with Resume and
Home; the bottom toolbar is removed. Bloom's heading is just the patch.

Choosing Bloom opens Start from beginning or Start from level. Type any
number from 1–100. The field starts at the current patch; starting that
level resumes its board. A different level starts a fresh board and keeps
the original checkpoint. The saved checkpoint level is shown when it
differs; type that number to restore it. Beginning replays patch 1 while
keeping resources, Trail progress and the original board. Invalid input
cannot start a game. This level picker is temporary and available in local Debug/simulator builds and
verified TestFlight installations. Public App Store builds hide testing tools.
The normal Bloom button resumes the current board directly from the Trail.
Save format 8 supports jumping above or below the checkpoint, preserves it
across launches, and prevents older builds from overwriting the newer save.

HINT LIGHT & COMPLETION
The suggested coral now has a thicker bright gold ring, pale inner light,
soft halo and a slow four-second brightness pulse. The amber edge keeps it
readable in Lagoon; it also glows in Deep Sea. Reduce Motion keeps it still.
Neighbors have no hint outlines. Controls use two rows when needed so Hint never becomes an ellipsis.

Completion uses the golden coral animation and happy Puff Puff. No Bloomed
heading, routine Glow/shot tally, or separate completion card. Only extra
power-ups such as +1 hint get a reward message. Next patch and Home remain.
The actual reward amounts and saved balances are unchanged.

A fresh win adds a victory swim over the corals: four gentle variations
(wiggle, swoop, bob and drift), a lap or a bubble spin according to difficulty.
The fish returns seamlessly to the same header position, size and happy pose.
The original swims are 50% shorter: 2.05/2.25/2.65/3.25 seconds for
wiggle/swoop/lap/spin. Bob and drift take 2.1 and 2.15 seconds.
After watching the whole swim, Next slowly puffs him up in place over 1.1 seconds.
Skipping ahead changes directly to his playing pose. Settings has a persistent
Celebration animations switch; coral completion and reward feedback still work
when it is off. Pause freezes playback; Reduce Motion skips the fish motion.
Reopening a completed patch does not replay the swim.
Tap Puff Puff during Bloom play for a little bubble burst, with no gameplay cost.
Pearl targets no longer occupy a footer. Earned pearl, hint, milestone shot and life-boost rewards rise in bubbles
over the board on completion and stay readable above centered Next. Rewards are still granted only by
the game logic. Preview: Design/PuffPuff/Bloom-Celebrations.gif.

Resting pebble tiles are completely matte grey, with an original rounded
stone illustration and no shimmer, glow or hover response. Their editable
vector source is Design/Corals/restingPebble.svg.

DEEP SEA MODE
Choose Lagoon or Deep Sea on the start menu, or open Settings from Pause.
Settings contains the appearance choices. Appearance is
remembered on this device separately from the saved game. Deep Sea uses
dark teal water, dim caustics, cyan plankton and a dark seabed; the corals
stay warm and readable, and resting pebbles remain matte grey.

QUIET GAMEPLAY HEADER
Bloom shows just the level number, Puff Puff and Pause. The puffpuff title,
Glow and shot balances live in Pause. Trail has a local pause control too.

SHAPED BLOOM REEFS
Playable levels 27–45 mix 6 square boards with 13 shaped reefs: round reefs, clipped
shores, fans, shelves, coves, ribbons, diamonds and arches. Levels 1–26 are unchanged.
Shapes and tile types vary independently. Plain boards keep returning; pebbles,
currents and stars appear selectively, with occasional combinations. New mechanics
join the mix instead of becoming requirements on every later board.
Level 27 starts gently with a three-tap solution; all existing tap budgets stay.
Gaps are empty, untappable water. They never light, need a hint or count toward
completion. Ripples affect existing adjacent coral without skipping a gap.
Pebbles remain visible and separate. The water bed follows the planted footprint.

The pack is authored reproducibly by scripts/make-bloom-shapes.py using legal
reverse taps and shortest solutions, including checks against pearl targets.
There are 10–25 coral per board in this mixed set. Save format 10 protects the new geometry
from older app versions. Content revision 7 lets untouched boards adopt the new layout or tile mix; a board already
played or holding a hint/extra taps keeps its exact state until Restart or a
fresh visit. Original checkpoint attempts, resources and Trail progress remain.

UP/DOWN CORAL
The ↕ badge marks a coral that flips itself and its immediate upper/lower
neighbors. No side, diagonal or across-gap changes. Other tiles can still flip
it normally. Levels 36–38 introduce it; level 45 brings it back. It stays in
the palette for later levels, alongside simple boards and other mechanics.

A short free practice opens before the first vertical board. It is not a
numbered level and never changes progress, moves, inventory or rewards. Tap
the center to see the rule, then Play; Skip also dismisses it. The local
tutorial preference remembers dismissal. Existing board attempts stay intact.

Reward update — October 27, 2026
Win: 3 Glow, plus 1 for meeting an optional pearl target. First clears of levels
5, 10, 15... award one hint and one shot; shots no longer drop on every win.
After first clears above level 4 and one-time Trail finds, a stable roll gives
10% instant life boosts or 0.5% saved boosts. Instant boosts fill lives to at
least five and start 15 minutes immediately. Saved boosts stay in inventory
until used. The gold Trail chest guarantees the instant type. Old inventory
and progress are preserved in save format 13. Mint is instant; gold is saved.
New editable master: Design/Powerups/Boost-Pickups.af.
Completed reef water has pearly lighting, light ribbons and little sparkles.

Bonus putt update — October 28, 2026
The bonus tee stays at Coral garden, independent of chest count. An already played round keeps its position;
Retry uses the new tee. The home entrance has a bright rim, glow and larger
flag. Tap the Home flag above the course to scroll directly to the hole.

Optional excursions — October 28, 2026
The three-food/home goal can be completed without the new side paths. Explore
Ribbon cove to clear a kelp shortcut (4 Glow), Shell shelf to remove an upper
sandbank (4 Glow), or Fin lookout to clear the home approach (5 Glow). These
change the same bonus course and make a hole in one easier while keeping
aiming and power important. The tee stays at Coral garden for every attempt.
Save format 14 preserves old progress and adds the new places as unexplored.


OCTOBER 29 — COMPACT BONUS COURSE + REGIONAL FINDS
The bonus round now uses its own broad mini-golf fairway, with Puff Puff at the
opposite end from home. Both ends fit on screen. Quest clearances remove the
matching kelp, sand and fish here; quest path geometry no longer dictates golf.
Released Puff Puff is smaller, collisions are slimmer, rebounds livelier and
the capture window more forgiving. Six putts and the existing reward rules remain.

Three optional hidden caches join the original three chests: search kelp for
lives (3 Glow), uncover sand for a lighter (4), or chase guards for hints (4).
They branch from Ribbon cove, Shell shelf and Fin lookout. Contents remain hidden
until uncovered. Payment, opening and rewards save together once.

Save format 15 retains all progress and migrates bonus positions to the new
fairway only as needed. A played round retains its putts; Retry begins at the far
tee. The previous app and saves are preserved before preview replacement.


OCTOBER 30 — PLAYGROUND
Pause → Settings → Playground opens 8 native golf trials and 8 path trials.
Use numbered choices, Retry/Reset and Keep (heart). Everything uses disposable
trial resources. The real game remains unchanged. PLAYGROUND_GUIDE.txt explains
all controls, exploration advantages, and how to compare rewards.


November 1 gameplay update
Trail: each cove contains four places to uncover. Spend Glow to search; finding the passage opens onward arrows. Keep exploring for food, supplies, permanent golf clearances and current changers.
Bonus putt: follow the four-leg fairway and use currents to steer around its bends. Reach home in four putts or fewer to unlock the next reef; one to three earn higher rewards. Five or six putts are practice only. Tap a current, choose a direction and use one changer; changes stay through retries.
Debug current changers: Pause > Settings > Debug refills. Existing saves and the separate design playground are preserved.

NOVEMBER 1 PACING & PRESENTATION UPDATE
Pricing was revised November 2: the required snacks/home path now needs
at least 201 Glow (51–67 Bloom wins). A representative route costs 231
(58–77 wins); exploring extras costs more. Fully uncovering all 104 objects
costs 607 Glow (152–203 wins), before repeat shot refills. Optional supply
chests still cost 1 Glow; snack chests cost 12/24/36. Previously paid
discoveries remain unlocked, without a retroactive charge.
First-item explanations appear at their actual reward reveal; old queued
records no longer pop up after navigation or launch. Some easy Bloom wins
use a little hop or double hop in place. The hint refill panel has a centered
shell icon and a padded 44-point close button. Bloom currently ends at 100.

NOVEMBER 2 PATH GOALS & CLOSED CHESTS
The path has no footer. Goals show snacks and home; optional chests do not
block Bonus putt. Required snacks can be hidden in closed chests, revealed
only on payment. Refillable shot chests close after their pickup animation.
Run bash scripts/check-path-goals.sh for isolated pacing and payment checks.

November 3 update: first-visit 3-slide intro + first Bonus putt 2-slide guide, remembered separately. One-time shot chests; every five Bloom wins + a separate 10% chance per win grant shots. Short chest reveals, readable multipliers, full-height Trail scenery. Save format 20 preserves all existing progress; no signing changes.

November 3 Trail refinement: local prices are now 8–24 Glow (small finds 8–12), with required routes 200/222 Glow, or roughly 50–74 Bloom wins. Clearing all 104 optional/required finds costs 1268 Glow (317–423 wins). Arrows follow the map diagonally, coves scroll around one swimming fish, and faint sandy routes guide exploration. Already paid discoveries and inventory stay unchanged.

November 6: Burst coral flips its 3×3 neighborhood, excluding water, pebbles and lighter-held coral. All 100 boards are solvable with native rules. Existing started/completed attempts and checkpoints survive the format-27 upgrade. Current-Adder.af/SVG and the runtime icon place the plus at (50,50).


TESTFLIGHT TESTING TOOLS (November 6, 2026)
Archive the normal puffpuff scheme in Release and upload a new build to TestFlight.
Settings includes Debug refills, Debug levels, Playground and Restart everything
in Xcode/simulator and verified TestFlight installations. Cleared Trail challenges
also show Replay. Public App Store installations hide and reject testing actions.
StoreKit checks the signed app environment; no extra scheme or DEBUG flag is needed.
An initial environment check may need connectivity; reopening Settings retries it.
Existing TestFlight uploads cannot change; install the newly uploaded build.
