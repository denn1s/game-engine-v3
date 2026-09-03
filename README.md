# Lesson 13 — The map, part 1: a sprite that moves

Phase 3 begins. Over three classes we build the world the characters walk
between dates:

| Lesson | The question | Adds a system that… |
|---|---|---|
| **13 (today)** | what makes a thing move? | turns held keys into position + facing + animation |
| 14 | what makes a place? | draws a tile grid (with autotiling) under the feet |
| 15 | what makes a wall and a door? | pushes back on solid tiles, launches a date |

Today the map is a floor and one character. No tiles, no walls. That is the
point: every system here answers exactly one question, and nothing is in the
way of seeing that.

Last class (12) the Animation Lab asked *how does a sprite come alive?* and
answered it with a clock on a demo wall. Today the player drives that clock.
The lab paid off — `SpriteRenderSystem` and `SpriteAnimationSystem` are the
lab's systems, promoted into the engine and stripped of every demo.

## Run it

```bash
love .
luajit tests/movement.lua
```

The game opens on the map. **Arrows or WASD** walk the protagonist. **N**
toggles diagonal normalization so you can feel the difference. The debug
scene switcher (`love . --debug`) still reaches the raising sim and the card
scenes.

## Instructor preparation

This is a full build from the Animation Lab base — no scaffold to hand out,
the whole thing is live-codeable in ninety minutes because each file is small.
If you want a head start, pre-place `MapScene.lua` and the two *reused*
systems (`SpriteRenderSystem`, `SpriteAnimationSystem`) and live-code only
the three NEW movement files. Do not type the HUD — it is readout plumbing.

The one genuinely non-obvious idea is why movement **polls** `love.keyboard.isDown`
while every other input in the game reads `keyPressed` events. That contrast
is a learning goal, not an oversight — see "Two kinds of input" below.

## Learning goals

By the end, students should be able to explain:

- why walking can't ride the `keyPressed` event pipeline the menus use
  (continuous state vs. discrete action);
- where `dt` first becomes load-bearing: **speed is authored in px/sec**;
- why a diagonal is `sqrt(2)` too fast, and normalizing the vector fixes it;
- how **two systems write one entity** without talking (movement picks the
  row, animation picks the frame);
- why the pure `Movement` module is testable without a window while the
  systems around it are not.

The code is done when the character walks on all eight headings at equal
speed, faces the way it travels, animates while moving and idles while still.

## The 90-minute class

### 0–10 min — Spawn something you can look at

Write the `player` entity: `position`, `moveIntent`, `velocity`, `sprite`,
`clipAnim` — five plain tables, no "Player" class. Reuse the lab's
`SpriteRenderSystem` to draw it, `MapBackgroundSystem` to give it a floor. It
just sits there, facing down.

Say the quiet thing out loud: **an entity is not a thing, it is a row of
components.** The "character" is whatever the systems downstream agree to
read. That's why we can drive it by data.

### 10–25 min — Two kinds of input, and why they differ

The engine has one input rule so far (MenuInputSystem, lesson 06): a key press
arrives as a `keyPressed` event entity, and systems read it once. Ask the
room: *can I walk by pressing a key?* No — an event says "it happened," not
"it's still happening." You **hold** a key.

So `MapInputSystem` breaks the pattern deliberately: it **polls**
`love.keyboard.isDown` every frame and writes raw `-1/0/1` axes into
`moveIntent`. Establish the rule that will outlive this lesson:

```text
discrete action   confirm, jump, pick a menu   -> keyPressed event entity
continuous state  walk, steer, aim             -> poll the device
```

Reinforce the budget: an input system only **fills components** (intent, and
one resource flag). It never touches position.

### 25–45 min — Intent becomes a place (the math beat)

`MovementSystem` spends the intent. The integration is two lines:

```lua
pos.x = pos.x + velocity.x * dt
pos.y = pos.y + velocity.y * dt
```

Stop and make the claim: `speed` is `150`, which means **pixels per second**,
and that sentence only means something because of `dt`. This is the first
number in the game written in real units — at 60fps you move 2.5px a frame,
at 30fps 5px a frame, and the same 150px a second.

Then hold **right + down**. Watch the HUD arrow grow. Walk into a corner and
you cover `sqrt(2) ≈ 1.41`× the ground you do on one axis. This is a **bug**,
and every engine ships it until someone normalizes the vector:

```lua
-- Movement.direction, pure:
local rawMag = math.sqrt(dx*dx + dy*dy)
return dx / rawMag, dy / rawMag, rawMag   -- unit length, same distance every way
```

Press **N** to flip it off live and feel diagonals zoom. The green arrow is
what you actually move; the red ghost is what an unnormalized engine would.
On an axis they overlap; on a diagonal the red outruns. Let two students drive
it and describe what they see before you name `sqrt(2)`.

### 45–60 min — Which way does it face, and is it walking?

`MovementSystem` also picks the sprite **row** from the dominant axis
(`Movement.facing`), and sets one boolean: `clipAnim.playing = moving`.

It does **not** touch `frame`. Point at `SpriteAnimationSystem` and show that
it reads `playing`: while true it advances `t` and picks a walk frame; while
false it shows the idle frame and rewinds `t` so the next step starts on the
plant, not mid-stride.

```text
MovementSystem   -> position, sprite.row, clipAnim.playing   (WHERE, WHICH WAY, WALKING?)
SpriteAnimation  -> sprite.frame                             (WHICH FOOT IS DOWN)
```

Two systems, one `sprite` component, neither knows the other exists. This is
the lab's demo-5 combo ("a clip and a tween on one entity, neither aware of
the other") showing up as real architecture. Teleporting the player would run
one and not the other — and you'll be glad they're separate at lesson 15 when
collision *stops* movement but the idle animation keeps running.

### 60–75 min — The wrap, and what it's pretending to be

The character walks off the edge and pops back on the other side. Say plainly
that this is a **placeholder** chosen so a wandering student can't get lost —
and that it **becomes collision in two classes.** The last thing today wants
is to make walls real; today only wants the door for them installed.

Tour the final system list. Note draw-only and update-only systems share one
ordered list safely, because `Scene` runs `update()` and `draw()` as two
passes: floor, then sprite, then HUD readouts on top.

### 75–85 min — Refactor toward the pure core

Pull the normalization and facing math **out** of the system and into
`src/world/Movement.lua`, leaving `MovementSystem` as a thin adapter. Ask
why: a system needs a registry, a scene, and a window; a *decision* needs
only its inputs. This mirrors CardArt last class — transformation vs. system.

Run the test.

```bash
luajit tests/movement.lua
```

It checks promises, not pixels: every direction is unit speed, un-normalized
diagonals really are `sqrt(2)`, the four cardinals map to the four rows,
ties prefer horizontal, standing still invents no facing.

### 85–90 min — Exit ticket (Discord)

1. Why can't walking use the same `keyPressed` events that the menu uses?
2. A player holds up-left. Name the three components that change and which
   system changes each.
3. If we deleted `dt` from the integration, what would break — and would the
   test still pass?

## Architecture underneath the movement

```text
love.keyboard (held)        MapInputSystem
    arrows / WASD          -> moveIntent {dx,dy}        (poll, not event)
                                    |
                                    v
                             Movement.direction  (pure)   <- the sqrt(2) fix
                             Movement.facing     (pure)   <- dominant axis
                                    |
                                    v
                             MovementSystem
        moveIntent + map.speed  -> position, velocity, sprite.row,
                                   clipAnim.playing
                                    |                    \
                                    v                     v
                          SpriteAnimationSystem     (position+sprite)
                            playing + t -> sprite.frame   SpriteRenderSystem
                                                            path->quad->blit
```

The three boxes on the left of the fold are **today's new code**; the two
below it are the Animation Lab, promoted. `Movement.lua` is the only file the
test imports — the rest needs a window.

## Deliberate limitations

- **Wrap, not walls.** Walking off-screen is undefined behavior papered over
  with a torus. Lesson 15 replaces the whole `-- placeholder wrap` block with
  collision against solid tiles.
- **Facing is instantaneous.** Real characters turn over a step or two, and
  prefer the *last* direction over a fixed horizontal tie-break. Both are
  polish; the memory-free dominant-axis rule is honest about what it is.
- **`clipAnim.playing` is one boolean.** The moment we want idle, walk, run,
  and hurt clips per row we need an animation **state** — and where those
  transitions live is the lesson-15 conversation, not today's.
- **One player, hardcoded.** Nothing says `moveIntent` can't drive three
  characters — but who owns "which entity is the player" is a scene-flow
  question we defer.

## Next class

Lesson 14 puts the floor under those feet: a tile grid, a `TileMapRenderSystem`
in place of the flat-color `MapBackgroundSystem`, and **autotiling** — a
`ground`/`edge`/`corner` lookup that decides each tile's art from its
neighbors, so painting one tile updates four. The character walks across it
unchanged, which is the reward for keeping movement independent of what it
stands on.
