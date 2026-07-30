# Small Talk — Lesson Plan

A phase-by-phase plan for building the game from the `04.5-GameViewport`
base (scenes, ECS, debug overlay, fixed-resolution viewport). Each lesson
adds a *system in the loop* rather than a thing on screen — unlike last
year's action game, this project is UI-, data-, and state-machine-heavy.

No week numbers on purpose: timing gets assigned once each lesson's real
difficulty is visible.

## Art policy (applies to every phase)

Placeholders first, but **intentional, not gray**:

- Commit to the palette immediately: Int blue, Cha red, Sen green, one
  background tone, cream text box. Flat-color geometry in the real 640×400
  layout reads as minimalist retro, not unfinished.
- Card art is **generated from day one** (Phase 2) — cards never need
  placeholder art at all.
- Real art (backgrounds, portraits) rides a parallel track — teacher
  drawing time or student homework — and drops in as a file swap because
  every lesson is built against the final layout and palette. Draw the
  protagonist portrait early: one real sprite changes the project's mood
  for cheap.

## Asset list

Everything hand-drawn in the game, at 640×400 native. Ordered by priority —
each tier is only needed once its phase starts, and every item has a
flat-color placeholder until then. Card art, the triangle radar, fades, and
the pack-back design are **generated/drawn in code — never on this list**.

**Tier 1 — the raising sim (Phase 1):**
- Protagonist portrait, ~256px tall — the one early real-art investment.
- Her room background, 640×400.
- Text box frame + activity menu frames (9-patch style panels; one drawing
  reused everywhere).
- Cursor / selection marker, ≤32px.
- Big date numerals (or pick a chunky pixel font instead of drawing).
- (If time) 3 tiny vignette animations, 2–3 frames each: book, comb, hobby.

**Tier 2 — cards & map (Phases 2–3):**
- World map tileset: ground, paths, a few building/prop tiles, 32px grid —
  the map is tiny, so this is one small sheet.
- Protagonist overworld sprite, ~32px, 4-direction walk (2 frames per
  direction is enough).
- 3 location-entrance markers (or just labeled doors in the tileset).

**Tier 3 — the dates (Phase 3):**
- 3 love-interest busts, 128px: Nerdy Girl, Pretty Boy, the voted Sense
  character. Ideally 3 expressions each (neutral / pleased / awkward — one
  per battle outcome); neutral-only is an acceptable v1.
- 3 date backgrounds, 640×400 (library + the two voted/TBD locations).
  Can be heavily reused crops of the map's palette.
- Heart icons for fuzzy affection display, ≤32px (full / faded variants).

**Tier 4 — framing (Phase 4):**
- Title screen art (can be the protagonist portrait recomposed + logo text).
- Graduation/confession background: the old tree behind the school, 640×400.
- One 256px love-interest sprite for the confession scene (stretch — only
  for whoever the player earned).
- Ending card for the alone ending (can be the tree background, empty —
  that emptiness *is* the art).

Rough count: ~6 backgrounds, 1 large + 3 medium + 1 tiny character, one
tileset, one UI sheet. Everything else is code.

## Phase 1 — The raising sim

### 1.1 Run state, resources & the save file
The shared `RunState`: week, day, hidden stats, card collection, affection
per love interest. Scenes never talk to each other — they all read and
write this one value; scene transitions carry no payload.

Where it lives: a **resource** — a singleton value stored in the Registry
(Bevy's answer to "where does global state go in ECS?"). Add
`Registry:setResource(name, value)` / `Registry:resource(name)` (~10 lines;
can be a hidden singleton entity under the hood). Lesson beat: *we just hit
the limit of "everything is an entity" — here's how real engines solve it,
and escape hatches get designed too.*

Persistence, same lesson: resources hold **plain data only** (no functions,
no images, no scene references) precisely so saving is trivial. Hand-roll a
~30-line Lua table→string serializer (Lua tables serialize to Lua source;
load back with `load()`), write it via `love.filesystem` (per-game save
directory — teach why you never write next to the executable), include a
`version` field for future migration. The save file **is** the run state;
everything on screen is rebuilt from it on scene enter. (Contrast with
scene-local state — cursor position, fade alpha — which lives and dies
inside a scene and is never saved.)
- **Teaches:** run state vs. scene state, ECS resources, plain-data rule,
  serialization, `love.filesystem`.
- **Done when:** `RunState` survives a save/load round-trip and the debug
  overlay shows it live.

### 1.2 UI toolkit: menu & text box
Cursor-driven 3-option activity menu; bottom text box with typewriter
effect. Reused in every scene of the game.
- **Teaches:** reusable UI components, input handling, text rendering.
- **Done when:** menu + text box run inside the Week scene layout at
  640×400.

### 1.3 The day loop
`CHOOSING → VIGNETTE → FADE → next day (or → Saturday)` state machine.
Fade transitions, per-activity flavor-text pools, stats actually increment.
- **Teaches:** scene-internal state machines, transitions, data-driven
  flavor text.
- **Done when:** a full Mon–Fri plays end to end and hands off to Saturday.

### 1.4 The triangle radar
Normalized triangle chart ("shape, not magnitude") drawn from live stats.
- **Teaches:** custom vector drawing from data, normalization.
- **Done when:** picks visibly nudge the triangle. (Small on purpose —
  buffer lesson for overruns.)

## Phase 2 — Cards

### 2.1 Pack generation
Weighted primary-stat pick, stat-bounded rolls, phrase pools per stat
(GDD §6).
- **Teaches:** weighted RNG, data-driven design, tuning invariants.
- **Done when:** debug command prints 5 rolled cards consistent with the
  hidden stats.

### 2.2 Generated card art
Proportional stat symbols, seeded placement, HSL hue blending.
- **Teaches:** procedural generation, color spaces (why HSL, not RGB
  averaging), deterministic seeding.
- **Done when:** any card renders itself; same card always looks the same.

### 2.3 Pack opening & collection
One scene, two entry modes: grid + detail panel; pack mode plays the
face-down slide-in and one-by-one flip first.
- **Teaches:** scrolling grid UI, tweening, animation & juice.
- **Done when:** Saturday morning flows from Week scene → reveal → browse.

## Phase 3 — Map & battle

### 3.1 World map
Small tilemap, top-down movement, collision, three location triggers,
scene transitions.
- **Teaches:** tilemaps, collision, triggers. (One lesson — the map is
  tiny; three doors.)
- **Done when:** walking into a location launches its date.

### 3.2 The date, part 1: turn structure
The exchange state machine: she plays face-up → you pick a card → resolve
via the triangle lookup table → outcome.
- **Teaches:** turn-based state machines, lookup-table design.
- **Done when:** 5 exchanges resolve with correct hit/stall/fumble logic.

### 3.3 The date, part 2: the hand
Draw 5 from collection, per-date discard, stall's replacement draw, the
mulligan, distinct outcome animations.
- **Teaches:** card-game data flow, more juice (the three outcomes are the
  game's vocabulary).
- **Done when:** a full date plays with real packs and affection applies.

## Phase 4 — Closing the loop & polish

### 4.1 The full loop
Recap/Sunday scene, autosave, affection thresholds (off-stat mixing),
week-12 graduation endings, title screen.
- **Teaches:** scene-flow architecture, endings, serialization for real.
- **Done when:** a complete 12-week run plays start to finish.

### 4.2 Sound & tuning
Simple sound system; full-run playtest; live tuning of pack curves and
affection numbers with the debug overlay (GDD §12 knobs).
- **Teaches:** audio, playtesting as a discipline, tuning with tools.
- **Done when:** the game ships to the class.
