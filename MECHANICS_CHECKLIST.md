# puffpuff mechanics checklist

Ideas from play on October 24, 2026. Consult this checklist when considering new tile types, power-ups, or ways to vary level difficulty. Unchecked items are ideas awaiting implementation; check them off when they are in the app.

## Tile types

- [ ] **Tiles that only turn off.** They can change from glowing to sleepy, but cannot turn back on through their normal rule.
  - Settle how these tiles fit the win condition before using them: the current goal is to make every coral glow.
- [ ] **Linked tiles.** A tile does the same as a designated tile above, below, or in another direction.
  - Settle whether it copies that tile's glowing/sleepy state or mirrors its changes.
  - Define what happens when links form a chain or point outside the board.

- [x] **Up/down coral.** Tapping a ↕ tile flips itself and existing coral immediately above/below, with no side or diagonal changes. Gaps and pebbles block that neighbor; no skipping. Ordinary neighboring taps can affect the tile normally. Levels 36–38 introduce one, one and two such tiles. It returns at 45 and stays available for later combinations indefinitely; keep selecting it only on some boards. Hints use the same rule. Saved attempts retain their existing tiles until Restart.
- [x] **Unnumbered practices.** Before the first up/down board, a short skippable practice demonstrates the rule without spending moves/hints, granting rewards or advancing a level. Store dismissal locally. Use these separate teaching moments at key introductions; regular level numbers do not need to serve as tutorials.

- [x] **Directional mixes from 46.** 46–48, 50–51 mix up/down and left/right coral; 49 is a plain square breather. Existing 1–45 boards stay unchanged.
- [x] **Diagonals from 52.** Tapping flips itself and its immediate four diagonal neighbors. 52 introduces it on a smaller square; 53–54 combine only diagonals and pebbles before 55+ selected combinations. Squares and plain reefs continue to recur. First-time unnumbered practice uses the real rule.
- [x] **Whole lines from 60.** Repeatable row/column coral flips every coral in its row/column, including itself, across gaps and pebbles. Empty slots and pebbles never change. Held-on lighters stay lit. Both orientations have distinct centered end-stop glyphs and one unnumbered practice. Save format 19 preserves these rules and active/checkpoint attempts.

## Power-ups

Power-ups are single-use items. Placement can be reversible before an item is used.

- [x] **Hint.** Spend one collected hint to reveal one useful next tap with a bright gold ring, pale core and breathing halo. Only the suggested coral is highlighted; no dotted outlines on neighbors. Hint controls wrap to a second row when needed instead of truncating. Reduce Motion keeps the glow steady. It does not use a tap or change any tiles.
  - Start with 3 hints. Collect 1 on the first completion of patches 5, 10, 15…100, and 1 with each newly found trail treasure. Earlier completed milestones and treasures are credited once when upgrading an existing save.
  - Replays do not award the same hint milestone again. Glow replay rewards remain; shots now follow the first-clear milestone rule below.
  - Buy 3 hints or watch an ad for 1. Both are explicitly **free previews** for now: no payment, ad network, or real purchase is performed. Production grants must wait for verified purchase or ad reward confirmation.
  - Opening tutorial patches 1–4 retain free guidance. No hint is consumed if the board is complete, out of taps, or cannot be solved with the taps remaining.
  - The same revealed hint remains available until a tap or restart changes the board. Reopening the app or resuming the latest checkpoint preserves it without spending another hint. Restart does not refund consumed hints.
  - The inventory, free refill records and active reveal are saved locally in format 4. Hint debits and preview grants roll back if saving fails. iCloud and real consumable purchase recovery are not implemented yet.
  - The visible Hint count spends one; the adjacent + opens an inline refill panel that leaves the board visible. A zero balance also opens this panel when a useful hint is requested.
- [x] **Collectible lighters.** Existing Trail sources remain, plus one lighter on the first clear of every seventh Bloom (7, 14, 21…). No replay farming or retroactive grants. It joins the floating reward bubbles and first-pickup explanation, then stays in the Bloom bag.
- [x] **Lighter.** One collected lighter turns a chosen sleepy coral on without changing its neighbors or spending a tap. It stays lit for this attempt; normal taps can still originate there and affect its neighbors. This preserves solvability and hints use the same held-on rule. Canceling selection spends nothing; tapping a lit coral/pebble/gap spends nothing. Can rescue an out-of-taps board. Restart clears the held-on tiles without refunding spent lighters. Debit, tile and any win rewards save atomically; checkpoints preserve them.
- [ ] **Required protective cover levels (after level 100).** A board supplies one permanent cover; it is not a collectible, prize, purchase or inventory item. The cover must always sit on one coral and can move between coral without a tap cost. It blocks that coral's flips for as long as it is there; never consume it. Design the board around needing the cover, with a verified solution including cover placements/moves. Hints can mark the required cover destination with × before giving the next coral tap. Teach it in a short unnumbered practice. Keep it out of levels 1–100 and the current prize pool.
  - A one-flip collectible was rejected: an audit of current 1–60 found 46 boards with unsafe positions (605 of 888 coral positions). After a blocked flip these positions cannot recover using normal taps alone. This is a mathematical placement audit, not a player failure rate. Do not restore that collectible implementation.

## Level difficulty

- [x] **Playable through 60.** Levels 1–60 are playable; 61–100 remain drafts. Stop progression at 60 and offer an explicit replay or Home. Never erase older progress beyond the current limit.


- [x] **Room to experiment.** Tap-budget revision 4 gives patches 1–4 6/10/12/14 taps; 5–9 get 18; 10–19 get 24; 20–40 get 30; 41–60 get 34; 61–80 get 38; 81–100 get 42. Existing attempts and latest replay checkpoints receive the increase while keeping their moves, coral arrangement, hint reveal and extra taps. Pearl targets remain optional efficiency bonuses.
- [x] **Restart instead of Undo.** Restart recreates the current patch with its full base budget. Added taps belong to the old attempt; collected hints, Glow, shots, trail progress and completed patches stay saved. Legacy undo history is retained for save compatibility but no longer records new moves or exposes an action.
- [x] **Distinct lit state.** Glowing tiles have a watery interior, sparkle marker, full-color coral, visible detail and gentle movement; no circular perimeter outline. Unlit tiles have still dark water and a smaller muted silhouette. Pebbles keep their separate matte grey appearance.

- [x] **Vary the number of tiles.** Playable levels 27–45 have 10–21 coral tiles across square and shaped footprints, with the existing generous tap budgets. Levels 1–26 remain unchanged.
- [x] **Vary the arrangement of tiles.** Level 27 begins with a round reef and a gentle three-tap solution. Playable levels 27–45 mix 2 familiar squares with 17 shaped boards, including fans, shelves, coves, loops, a ribbon and a diamond. Levels 28–35 are all shaped; 28, 34 and 35 introduce interior water gaps. Gaps are noninteractive open water; orthogonal/horizontal/vertical/star rules apply to adjacent existing coral only. Visible pebbles remain separate. All authored boards have legal solutions within their tap/pearl budgets. Save format 10 and content revision 8 preserve active/checkpoint attempts; untouched boards, Restart and fresh visits use the new layouts.

- [x] **Mix ingredients instead of accumulating them.** Board shape and tile types vary independently. After each introduction, plain coral-only boards still appear, pebbles/currents/stars recur selectively, and some boards combine two or three. A newly introduced mechanic is an option for level design, not a requirement on every later level. Preserve existing attempts when changing authored tile selections.

## Trail direction — October 25, 2026

Build only the first playable reef before creating further courses. Use the user's paper mockup: Puff Puff starts at the bottom, explores for food and optional treasure, and returns to the small home entrance near the top. Keep the official Affinity character.

- [x] **Branching exploration.** Reveal adjacent choices, choose unknown paths, collect three snacks, backtrack and find home. Only the first reef is playable.
- [x] **Close-up quest areas.** Swim through sandy shallows, kelp groves, coral gardens and hidden coves with a following camera. Only local connected exits appear; unknown paths hide their destination. Tap a blockage's artwork/cost to clear it. Reuse the saved course graph, current location and official vector art. The full course overview remains exclusive to the golf bonus. Pause settles travel; Reduce Motion skips camera motion.
- [x] **Explored-area map.** A folded nautical chart in the upper-left corner has a zigzag paper outline and fold creases. It charts visited places and their known active connections, with the official happy Puff Puff as the current-location marker in both sizes. Tap to expand; select discovered landmarks to read their names/status. Unknown places stay hidden. The map pauses exploration, uses existing save data and never moves the fish or grants/spends resources.
- [x] **Glow wakes the reef.** Paid local reveals each light their own water and coral pool; unopened pockets stay dark. Puff Puff carries a small temporary halo while swimming. Paid lighting persists through coveSearches and the map reflects paid reveals. Pause and Reduce Motion settle to the saved result.
- [x] **Tap to clear the way.** First arrival reveals kelp, sand or enemy fish; the second tap spends 3/4/5 Glow to clear. Retreat is always possible. Sand opens an additional central shortcut.
- [x] **Exploration improves bonus golf.** Three accent-color chests grant one-time power-ups (mint: +1 hint/+2 lives; coral: +2 shots/+1 lighter; gold: +2 hints/one 15-minute unlimited-lives boost) while optional side excursions open easier putting routes. Cleared obstacles remain absent. Explore more before deciding on the final reward.
- [x] **Small bonus round after home.** Pull back from Puff Puff opposite the intended direction; longer drags give more strength. Release to putt, with bank shots and a six-putt cap. Par four. Deflate through the doorway after landing.
- [x] **One best reward set.** Retry freely; keep the best successful score. Collect once after the current round reaches home within six putts to grant its best rewards and unlock the next reef. A failed or unfinished retry cannot collect, even with a saved earlier best. No stacking or farming. World two is recorded as unlocked but is not built yet.
- [x] **Prototype bonus tiers.** Hole in one: 12 Glow/3 shots/3 hints; eagle: 10/3/2; birdie: 8/2/1; par: 5/1/1; five or six putts: 3/1/0. Tune through play. Each valid putt now spends one collected shot; each attempt is capped at six putts.
- [x] **Persistent first reef.** Save format 10 retains layout revision 3, visited stops, current location, bonus strokes/position, best score and claim status. Save action outcomes before playback and roll back on failure. Migration preserves the existing Bloom attempts, resources, collected objects and paid clearances.
- [x] **Coral cottage and Trail artwork.** Editable Affinity masters and matching native vectors for the cottage, kelp forest, sandpit, enemy school, food and three chest accents with open/closed versions.
- [x] **Continuous inflation.** Official happy/puffed contours interpolate geometrically; never crossfade the poses.
- [x] **Subtle living plants.** Lit coral sways/bends gently at its anchored foot. Kelp fronds sway separately with staggered phases while roots stay planted. The shared clock pauses and respects Reduce Motion; unlit coral and pebbles remain still.

### Bloom lives and timed treasure boosts

The latest life rules were selected by the user on October 27, 2026; these supersede the earlier upfront charge.

- [x] **Lives are lost on failure/abandonment only.** Start and win freely; lose one for exhausting taps, restarting or discarding an unfinished attempt. A saved `lifeLossHandled` flag prevents charging twice for the same attempt after more moves/restart/relaunch. Pause and Trail preserve the board without a charge. New attempts require a positive balance or boost. Refill one every 5 minutes to 5; gifts can exceed 5. Format 12 retains balances and grandfathers prepaid format-11 attempts.
- [x] **Restart confirmation.** The button says Restart. Its confirmation shows lives and the applicable one-life cost. At zero, Watch an ad in Restart gives 1 life and restarts atomically; the separate lives sheet gives 3 lives and keeps the current board. Free offline previews for now, no real ad/payment calls.
- [x] **Refill lives gift.** The mint chest grants 2 lives. Gifts may exceed the natural cap of 5; regeneration pauses at or above 5.
- [x] **Unlimited lives boost.** Normal pickups activate immediately, refill lives to at least five and give 15 real-time minutes. Preserve overflow lives. The gold chest guarantees this type; first Bloom clears above level 4 and one-time Trail finds have a 3% chance; a separate 5% reward refills lives without unlimited time. A separate 0.5% chance grants a rare saved boost, activated from Bloom/Settings → Lives & boosts. Stable saved-seed/event rolls prevent rerolling. Expiry persists across relaunch/backgrounding, activations extend remaining time and protected attempts stay protected until finished. Preserve old stored items. Only the saved variant is fully gold and sparkly; the normal heart stays mint.
- [ ] **Unlimited taps boost.** Treasure can temporarily let Bloom levels be played without a tap limit.
- [ ] Decide activation/expiry rules for the still-unimplemented unlimited-taps boost. Proposed behavior: an attempt started during it retains unlimited taps until it ends.

## Prototype navigation and presentation

- [x] **Trail is Home.** Open the saved close-up cove. A Bloom button resumes the current puzzle directly. Pause → Home returns to Trail. Lives appear only in Bloom/Settings; currencies stay in Pause. No separate game-choice screen or bottom toolbar.
- [x] **Temporary level picker in Settings.** Debug levels retains beginning/typed level 1–45. Same level resumes; jumps preserve the original checkpoint. Release builds omit these controls.
- [x] **Custom Affinity power-up icons.** Matching editable vectors for lives, unlimited lives, hints, lighter, extra taps, Glow and shots across controls and rewards.
- [x] **Lit coral without outlines.** Remove only the circular tile perimeter. Preserve the original coral color/detail contrast, veins, dots, water texture, glow and lit sparkle. Keep the targeted gold hint halo.
- [x] **Debug refills in Settings.** From Home or Pause, open Settings → Debug refills to add 25 Glow, 5 shots, 3 hints, 5 lives, 3 lighters or one 15-minute unlimited-lives boost on demand, repeatedly and for free. Keep gameplay free of debug refill controls. Balances remain visible, and each addition saves immediately with rollback on failure. Both controls and grant API are DEBUG-only. No quest items, discoveries, clearances, bonus results or Bloom boards change; these grants are not purchase/ad records.
- [x] **Quiet completion.** Coral color/animation and happy Puff Puff mark completion. Only extra power-ups receive a reward message. Routine Glow and shot balances update without a completion tally; keep Next patch and Home.

- [x] **Difficulty-based victory swims.** Four small swims (wiggle/swoop/bob/drift) vary simpler patches. Stone/current or 5×5 boards get a lap; star/mixed or high pearl-target boards get a figure-eight and spin. One fish leaves its actual header slot and returns to its exact resting position and size, with no fade or view swap. The original timings are halved: wiggle/swoop/lap/spin take 2.05/2.25/2.65/3.25 seconds; bob/drift take 2.1/2.15 seconds. Pause freezes the finite clock; Reduce Motion keeps the fish at rest. Loading a completed patch never replays the swim.
- [x] **Gentle puff after Next.** If the full swim finished, Next inflates the resting happy fish into its playing pose over 1.1 seconds. Skipping an unfinished swim changes directly to the puffed pose. This is presentation state only; no save schema or reward changes.
- [x] **Celebration preference.** Settings → Celebration animations is on by default and stored locally. Off skips the fish swim and subsequent slow inflation; coral completion and earned bonus feedback remain. Turning it back on does not replay an existing win.
- [x] **Tap Puff Puff for bubbles.** During Bloom play, the header fish releases five small bubbles on tap. No tap budget, power-up, resource or board changes. Pause freezes the finite burst; Reduce Motion suppresses it.
- [x] **Earned extras float up.** Remove the pearl-target footer. On a win, earned pearls (+1 Glow), milestone hints/shots and life boosts rise in translucent bubbles over the board during the swim, then stay beside the taps-left counter. Read existing earned flags only; never re-grant rewards through animation. Reduce Motion and reopened wins show the labels immediately.

## Before adding a mechanic

- [ ] Consult these ideas and choose the mechanic that fits the level's teaching or difficulty needs.
- [ ] Resolve its open rules, including interactions with other tile types and power-ups.
- [ ] Introduce it in an easy teaching level before combining it with other mechanics.
- [ ] Account for it in puzzle generation, solvability, hints, tap budgets, restart, and saved progress.
- [ ] Keep unused movable covers distinct from consumed power-ups.
- [ ] Update this checklist with the implementation status and the rules chosen.

### Trail reward presentation — October 27, 2026

- [x] **Named spending.** Idle obstacles show only the Glow key and cost; hidden supplies use a mint treasure chest. Tap for Clear kelp, Sweep sand, Scare off fish or Open, then explicitly confirm N Glow. Supply chests cost 8–12 Glow after the November 3 rebalance. Inspection and cancel are free; existing saved rewards and atomic payment rules remain.
- [x] **Pickup progress.** Food artwork and +1 float into a small progress bar and its count pops when the swim arrives. Chest pickups use a sparkle. Replay/reopening does not re-grant rewards. Reduce Motion updates immediately; Pause settles to saved progress. Tap either bar for the snack goal, chest contents/costs, optional putting shortcuts and inventory explanations. Unknown routes stay hidden.

### Bloom reward tuning and celebration finish

- [x] **Rarer shots.** One shot on the first clear of each fifth level, replacing the old every-win shot. Replays do not repeat this reward; existing balances, treasure and golf bonuses remain. Optional earnedShot is saved with the reward transaction.
- [x] **Shiny completion water.** Pearly warm/cyan illumination, light ribbons and twinkles behind completed coral. No new coral outlines or routine reward totals. Pause freezes the shared clock; Reduce Motion keeps the light still.
- [x] **Fixed pearl targets.** Originally construction-solution taps +2, not necessarily minimum taps +2. Current playable targets: 11–12 =4, 13–20 =5, 30 =6, 40 =7. Shaped boards retain reachable targets. Winning at/below the target grants +1 Glow.
- [x] **Save format 13.** Retain all balances/checkpoints; persist the reward seed and optional earned gift/shot flags. No retroactive shot reductions or rerolls.

### Bonus putt clarity — October 28, 2026

- [x] **Finish within the allowance.** Collection requires a successful current round within 1–6 putts. A miss at the limit gives no bonus and shows Retry, with no Collect. Store and view share the eligibility rule; invalid score tiers grant zero. Best successful scores are preserved across attempts.
- [x] **Meaningful starting distance.** New rounds start at the opposite end of a separate compact fairway. Optional clearance changes improve the approach; chest counts never move the tee. The whole course fits on screen.
- [x] **Visible home target.** Bright entrance rim, soft glow, larger flag, Home label and a Find home control that scrolls to the hole. Existing cottage artwork and capture location remain aligned.

### Optional course advantages

- [x] **Three optional excursions.** Ribbon cove/Tangled channel, Shell shelf/Hidden sandbank and Fin lookout/Homeward current. None has a required snack or home. Existing main paths remain available.
- [x] **Course changes matter.** Four Glow clears kelp to open a straighter lane; four clears the upper sandbank; five scares off a fish school and opens more water near home. Each has its own discovered/cleared/light state and a brief putting benefit at the stop. Reuse custom Affinity artwork.
- [x] **Fixed tee, skill still matters.** The far end of the bonus fairway is the fixed tee, independent of chests. Optional clearances provide easier aim/power windows; they do not auto-complete a shot. The base course retains a difficult banked hole in one.
- [x] **Format 14 preserves progress.** New optional areas start unexplored. All existing resources, quest items, claimed rewards, Bloom progress and already-played bonus positions remain.


### Compact mini golf and regional finds — October 29, 2026

- [x] **Separate fairway.** Tee (80,490), home (260,100), 340×570 water course. Share quest clearance IDs/artwork while authoring golf geometry independently. Whole course visible, rewards initially collapsed.
- [x] **Small released Puff Puff.** 0.62 visual scale, 7-unit collision radius, generous invisible input area. Charge smoothly increases his size; release contracts him over 0.18 seconds. Keep doorway deflation.
- [x] **More forgiving shots.** Wider fairway, livelier rebounds and a 17-unit capture target. Baseline hole-in-one bank shots remain possible; optional kelp/sand/fish clearances create more viable settings.
- [x] **Regional paid discoveries.** Frond hollow: kelp/3 Glow/+2 lives. Buried lantern: sand/4 Glow/+1 lighter. Pearl hideaway: fish/4 Glow/+2 hints. Original chests stay unchanged. Unknown contents remain hidden; pay once to uncover and grant atomically. Dynamic total is six finds.
- [x] **Format 15.** Preserve inventory, Bloom, quest, best score and claimed rewards. Course revision 2 migrates only bonus geometry; Retry starts at the far tee. New caches start unvisited.


### Design playground — October 30, 2026

- [x] **Eight golf alternatives:** Soft putt, Slingshot, Bubble stop, Aim + puff, Bank builder, Current gates, Draw a route, Tap to send. Each playable with exploration comparison and trial rewards.
- [x] **Eight path alternatives:** Cove doors, Fog islands, Side swim, Reef garden, Depth dive, Home + spokes, Sonar hunt, Current forks. Local blockers, Glow costs, three snacks and three optional finds; transfer finds into golf after home.
- [x] **Safe comparison:** DEBUG settings entry, memory-only trial progress and resources, separate favorite preference. No production progression/economy/save changes. Guide explains every exploration advantage and reward rule.

### Current hybrids and illustrated local uncovering — October 30, 2026

- [x] **Eight slingshot/current variants in Playground.** Soft streams, Jet relay, Two ways home, One tide dial, Pocket current, Pulse tide, Soft landing, Live currents. Preserve original golf demos in a separate collection. Every variant has exploration comparison and disposable trial reward tiers.
- [x] **Illustrated path comparisons.** Existing official reef artwork replaces generic node icons; rooms contain multiple paid discoveries. Fog, garden, horizontal scenes, depth shelves, hub regions, sonar search and current loops demonstrate different ways to explore.
- [x] **Scroll-safe controls.** Aiming drag starts on Puff Puff only; water scrolls. Visible scrollbars and a fresh scroll position on each trial selection.
- [x] **Choose a hybrid and a path treatment.** Selected path #1 local cove searches and slingshot + adjustable currents; production implementation authorized November 1.


### Production coves and consumable current changers — November 1, 2026

- [x] Four local hiding places in each of the existing 24 coves. Spend Glow to uncover a passage, coral or supply; finding the passage reveals onward arrows, and known neighbors remain available for retreat.
- [x] All six original chests and three snacks move into local searches. Costs, rewards, new finds and reveals save atomically; duplicate taps cannot farm rewards.
- [x] Six paid obstacle clearances permanently simplify golf. Five side-cove current changers are collectible one-time inventory items.
- [x] Pull back and release to putt; three currents give directional pushes. Eight-way direction picker with explicit Use 1 changer; cancelled/unchanged selections cost nothing. Directions survive retries, exploration and relaunches.
- [x] Six-putt rounds retry freely; successful current round required to collect one best bonus set. Collection locks the section and unlocks the next reef; next reef content remains unbuilt.
- [x] Hole in one remains achievable without exploring everything. Tested 13,206 angle/power combinations: clearances and helpful current choices broaden winning windows, but misses remain after full exploration.
- [x] Format 16 preserves existing Bloom boards/checkpoints, currencies, quest rewards, best scores and positions. Verified real Mac and simulator migrations independently.
- [x] Custom current-changer Affinity/SVG/native vector art; +3 debug refill in Settings only. Both Lagoon and Deep Sea checked in the running Mac app.

### Living Trail interactions — November 1, 2026

- [x] Sea-glass Glow bulb and matching Glow key saved in an editable Affinity master, used natively throughout the app. Rim glints appear in different positions on the shared clock.
- [x] Tap open water to swim locally for free; paying is a separate explicit action.
- [x] Puff and scare away enemy schools; reveal food, bring it to the mouth and chew before the snack counter animation. Official fish geometry is preserved.
- [x] Puff Puff marks You are here on both map sizes.


## Collected inventory — November 1, 2026

- [x] Every valid bonus-golf putt spends one collected shot. Six-putt attempt limit remains; a miss pays nothing. Retry is free but does not refund used shots or changers. Zero stock keeps the unfinished round available while the player explores for more.
- [x] Eight easy shot chests on the Trail: 3 shots for 1 Glow, refillable after first discovery. Existing chest/milestone/bonus shots remain.
- [x] Personal treasure chest with custom icons, counts and explanations, grouped into Bloom and Bonus golf. Reach it from Trail, Bloom and Pause. Activate rare saved unlimited-life boosts there.
- [x] First-time pickup explanations persist until acknowledged and appear only once per item type. No grants from displaying an explanation.
- [x] Debug Restart everything in Settings, with confirmation and an archived save. Fresh gameplay and tutorials, preserved purchase entitlements and appearance preferences. Verified only with isolated test saves.
- [x] Save format 17 migration preserves Bloom boards, inventories, Trail discoveries and the current golf attempt.


## Life-gift tuning — November 1, 2026

First-time eligible Bloom/Trail reward rolls are exclusive: 3% refill + immediate 15-minute unlimited lives, 5% life-only refill, 0.5% rare stored boost, 91.5% no life gift. Keep the original deterministic seed/event hash and stored bucket 100–104; never reroll completed events. The life-only refill raises lives to at least five, preserves overflow and existing boost expiry, and neither starts nor extends unlimited time. Its completion bubble and Trail banner use the custom life heart and “Life refill”, never an infinity icon or “15 min”. The guaranteed golden chest retains its fixed boost. Format 18 adds the refill reward case; upgrading preserves existing gifts, timers, supplies and progress.


### Cove completion and navigation — November 1, 2026

- [x] Affinity sea-glass All clear sign at the foot of a fully uncovered area, plus a matching map checkbox. Requires every local discovery; repeatable shot chest needs one opening. Completion persists through existing saved discoveries.
- [x] Screen-edge exits agree with the authored map directions, including backtracking. Multiple exits share an edge without overlapping buttons; unseen destinations stay anonymous.
- [x] Supply finds use treasure chests, Open and the current area-based Glow price. Center short popup copy and leave generous padding. Keep original obstacle-backed treasure costs/rewards unchanged.


### Fixed typography, pacing and first-pickup timing — November 1, 2026

- [x] Fixed Chalkboard SE typography throughout the app; remove font choices from Settings and ignore old font selections. Preserve scaled readable type.
- [x] Required-path pacing updated November 2: cheapest snacks/home route 201 Glow (51–67 Bloom wins); representative route 231 (58–77). Optional uncovering adds costs; full clear is 607. All optional supply chests remain 1 Glow. Heavier costs belong to deeper passages, clearances and required snack chests; no retroactive charge for paid discoveries.
- [x] Explain only the current newly earned item at its reveal, without a global delay. No stale popup after relaunch, unrelated navigation, debug refills or ad refills. Save acknowledgements atomically; inventory keeps descriptions available.
- [x] Some easy Bloom celebrations are a single hop or two little hops in the header. No horizontal travel, exact landing, existing animation settings respected.

- [x] Center the custom hint icon in its refill panel, with a padded 44-point close button and more space around the membrane edge. Keep the board visible.


Buying the three-hint preview bundle during a playable non-tutorial Bloom immediately reveals the next useful coral and spends one of the three, leaving two. Save grant, refill history, consumption and revealed target atomically. Preserve moves/cells. If the same hint is already active or no useful legal move can be shown, keep all three; never double-charge a reveal. Failed saves restore the exact prior state. The existing gold glow highlights the selected coral; the supply panel closes. Ad refills retain their one-hint grant behavior.

- [x] Earned bonus bubbles rise and stay beside Bloom taps left; compact wrapping and immediate settled state for Reduce Motion/reopened wins.
- [x] Trail header shows the current available Glow balance.
- [x] Refillable shot chests open visibly with a +3 pickup, then close for the next paid opening; Puff Puff swims in front of obstacle/chest art.
- [x] Path has no footer; All clear remains on the maps. Header goals show three snacks and home, with no mandatory chest total. Required snacks can be hidden inside chests; optional finds never gate bonus golf. Finding home before the last snack counts.


## Bonus putt balance — November 1, 2026

- [x] The fairway is a four-leg zigzag with one current along the outgoing leg after each major turn. Current pushes steer the ball through the route; cleared Trail obstacles make it easier.
- [x] Reach home in four putts or fewer to unlock the next reef and collect. A five- or six-putt finish earns no progress or reward; one to three putts earn optional higher rewards. Par remains the baseline reward.
- [x] Course revision 4 safely migrates old tee, home and in-progress ball positions while retaining strokes, best scores, claims, balances and custom current directions. Old default current directions adapt to the new course.
- [x] Puff Puff is drawn above fairway art and current controls, with the overlay excluded from hit testing.


## November 3 updates

- [x] **Short first-visit introductions.** Three illustrated slides explain snacks/home, Bloom Glow and bonus golf. Two more appear only on the first eligible Bonus putt launch. Finish/Skip are remembered separately; no resources spent; debug reset restores them.
- [x] **One-time shot chests.** All paid finds grant once. Paid/open state and previous inventory are preserved.
- [x] **Renewable Bloom shots.** Every five wins (including fresh replays) grant one shot; each win also has a 10% chance of another. Deterministic saved roll, atomic completion and a two-shot bubble when both coincide. This supersedes first-clear-only shot milestones. Fifth-level hint rules stay unchanged.
- [x] **Chest presentation.** No Bloom celebration at treasure openings. Short prize bubbles only, with legible count badges. Trail art fills the bottom safe area without lowering exit buttons into the home indicator.

- [x] **Even local prices (November 3).** All paid finds cost 8–24 Glow, with no 1/28-style split. Required route minimum 200 Glow, representative route 222; 50–74 Bloom wins. Full optional clear 1268 (317–423 wins). Paid objects/balances unchanged.
- [x] **Spatial exits and scrolling travel.** Arrows show actual map bearings and sit toward those directions. One fish swims continuously as both cove scenes scroll through shared water lighting. Soft sandy paths hint at local discoveries/available exits. Preserve dark unpaid areas, Reduce Motion, pause, map and atomic saved destinations.
