# The Day Loop & The Stat Triangle

Run sheet for one 2-hour class, building from the state of
`/UVG/card-game` toward `08-DayLoop` + `09-StatTriangle`.

One class, two features: the week starts passing, and the player can
finally see the shape of who they're becoming. The hard part isn't
either feature — it's the four things standing in front of them.

There is an HTML version of this page next to it
(`08-09-dayloop-triangle.html`) for projecting.

---

## What's in the way

Read from the class repo as it stands. The engine is in good shape —
`setResource`, the `setup/update/draw/unload` hooks, `switchRequest`,
`Screen` at 640×400 are all there. These four are what the day loop
actually needs and doesn't have.

**`src/engine/state/SaveFile.lua` — written, never called.**
Nothing outside `src/engine/state/` references it. The engine half of
lesson 05 landed; the game half — a `runState` resource that gets loaded
and saved — never got wired.

**`src/game/systems/MenuInputSystem.lua` — no confirm branch.**
Only left/right. Nothing ever spawns `activityPicked`, the event the
entire day loop hangs off.

**`src/engine/Game.lua` — the sweep is too narrow.**
`Game.update` destroys `keyPressed` entities specifically. An
`activityPicked` event would never be swept — it would sit in the
registry and re-fire every frame, forever.

**`src/game/systems/TextboxSystem.lua` — the typewriter is framerate-bound.**
Progress is derived from `#textbox.visibleText` — an integer — so
`#visibleText + speed*dt` floors straight back to `#visibleText` and it
advances exactly one character per frame no matter what. `speed = 1`
reads as one char per second and delivers sixty. Worth six minutes
today, because the vignette needs its line to finish inside a fixed
window.

---

## The shape of the day

```
choosing --activityPicked--> vignette --2.5s--> fade --1.6s--> choosing
```

One system owns every transition. The day advances at the fade's
*midpoint*, when the screen is fully black — the oldest trick in
transitions: change the world while nobody can see it. That midpoint is
also where the autosave goes, because it's the one moment the world is
consistent and the player can't act.

---

## Run sheet

### 0:00 — Run it, and name the three lies (8 min)

Launch the game. Pick an activity — nothing happens. The text box says
*"Hello world this is a very long text…"*. Quit, relaunch, nothing was
remembered. Frame the class: today the week actually passes, and it
survives quitting.

### 0:08 — Any event, one update (8 min)

*edit* `src/engine/Game.lua`

Generalize the sweep from `keyPressed` to an `event` marker component.

> **Teaching point:** events are broadcasts — writers spawn, readers
> poll, the runtime clears. Bevy's `Events<T>` work exactly this way.

```lua
-- Game.update: was query("keyPressed")
for _, entity in ipairs(current.registry:query("event")) do
    current.registry:destroy(entity)
end

-- Game.keypressed: tag it like everything else
current.registry:spawn({ event = true, keyPressed = { key = key } })
```

### 0:16 — Confirm spawns a pick (7 min)

*edit* `src/game/systems/MenuInputSystem.lua`

> **Teaching point:** the input system doesn't know what an activity
> *is*, what happens when one is picked, or even that this menu is about
> activities. It announces and stops.

```lua
elseif event.key == "return" or event.key == "space" then
    scene.registry:spawn({
        event = true,
        activityPicked = { option = menu.options[menu.cursor] },
    })
end
```

### 0:23 — Fix the typewriter (6 min)

*edit* `TextboxSystem.lua`, `TextboxSetupSystem.lua`, `TextboxRenderSystem.lua`

**The bug.** `speed` currently does nothing:

```lua
local count = #textbox.visibleText + textbox.speed * dt
local cut   = math.floor(count)
textbox.visibleText = textbox.text:sub(1, cut + 1)
```

At `speed = 1`, `dt ≈ 0.0167`:

| frame | `#visibleText` | `count` | `cut` | result |
|-------|----------------|---------|-------|--------|
| 1     | 0              | 0.0167  | 0     | 1 char |
| 2     | 1              | 1.0167  | 1     | 2 chars |
| 3     | 2              | 2.0167  | 2     | 3 chars |

`speed * dt` is 0.0167 and `math.floor` discards it *every frame*, so
`cut` always lands back on `#visibleText` and `cut + 1` is always exactly
one more character. One char per frame, whatever `speed` says.

> **Teaching point:** the accumulator is being read back out of the
> output. A string length is an integer — it cannot hold "2.7 characters
> revealed," so the fraction has nowhere to live between frames.
> Progress is a number that happens to *produce* a string.

It's not quite inert, it's quantized: chars per frame is
`floor(speed * dt) + 1`, so `speed` **selects from a ladder of multiples
of the framerate** rather than scaling the rate. Everything below ~60 is
identical; at 61 it jumps to 120 chars/sec. And because the ladder is
built from `dt`, a student on a 144Hz laptop gets a typewriter 2.4×
faster than yours.

*Demo before fixing (2 keystrokes):* set `speed = 1`, then `speed = 50` —
identical. Then `speed = 200` — suddenly fast **and** visibly chunky.

**Fix 1 — the typewriter.** Keep progress as a float that persists, and
let the render system derive the string. Drop `visibleText` from the
component entirely.

```lua
-- TextboxSetupSystem.setup
textbox = { text = "...", visibleChars = 0, speed = 30 }

-- TextboxSystem.update
for _, textbox in scene.registry:each("textbox") do
    textbox.visibleChars = math.min(
        textbox.visibleChars + textbox.speed * dt,
        #textbox.text)
end

-- TextboxRenderSystem.draw
love.graphics.printf(
    textbox.text:sub(1, math.floor(textbox.visibleChars)),
    pos.x + 10, pos.y + 10, size.w - 20, "left")
```

This is what the file split buys: the update system owns *time*, the
render system owns *presentation*, and the component holds only state.
No second field claiming the same truth — which is what caused the bug.
`speed` now reads honestly as characters per second, framerate-independent.

*Smaller live diff, if you prefer:* keep `visibleText` as a cached field
and assign it from `visibleChars` — never the reverse.

```lua
textbox.visibleChars = math.min(
    textbox.visibleChars + textbox.speed * dt, #textbox.text)
textbox.visibleText = textbox.text:sub(1, math.floor(textbox.visibleChars))
```

**Fix 2 — the missing key.** The system table is an array entry, not a
named field, so `system.name` is `nil` and it shows up blank in the
debug overlay's system list.

```lua
-- src/game/systems/TextboxRenderSystem.lua, line 1
local TextBoxRenderSystem = { "textBoxRender" }        -- before
local TextBoxRenderSystem = { name = "textBoxRender" } -- after
```

### 0:29 — Content, state, and the save file finally used (13 min)

*new* `src/game/data/activities.lua`, `RunStateSystem.lua`, `StatsSystem.lua`

Three small pieces at once. `activities.lua` is *only a table* —
designers tune it, systems read it, nothing in it can have a bug that
isn't a typo. `RunStateSystem` is where lesson 05 gets closed.

> **Teaching point:** run state is plain data precisely so saving is
> trivial.

```lua
-- RunStateSystem.setup
local data = SaveFile.load()
scene.registry:setResource("runState", data and data.runState or {
    week = 1, day = 1,
    stats = { int = 0, charm = 0, sense = 0 },
})

-- StatsSystem.update
for _, pick in scene.registry:each("activityPicked") do
    local runState = scene.registry:resource("runState")
    local stat = activities[pick.option].stat
    runState.stats[stat] = runState.stats[stat] + 1
end
```

`activities.lua` keys must match the menu options already in
`MenuSetupSystem`: `study` → int, `grooming` → charm, `hobbies` → sense.
Five flavor lines each for now.

### 0:42 — The vignette speaks (8 min)

*new* `src/game/systems/VignetteSystem.lua`

> **Teaching point — the one to spend time on:** three systems now react
> to one `activityPicked` event, and none of them knows the others
> exist. Stats bumps a number, the vignette writes text, the day loop
> flips a phase.

```lua
for _, pick in scene.registry:each("activityPicked") do
    local pool = activities[pick.option].lines
    local _, textbox = scene.registry:first("textbox")
    textbox.text = pool[love.math.random(#pool)]
    textbox.visibleChars = 0   -- the typewriter's whole API
end
```

### 0:50 — Checkpoint · breathe (5 min)

Pick an activity: a real line types out. Open the overlay (F1) and watch
`runState.stats` move. Nothing is on screen yet that shows them — that's
deliberate, the stats are hidden by design.

### 0:55 — The day loop (22 min)

*new* `DayLoopSystem.lua` · *edit* `MenuInputSystem.lua` (choosing guard)

The conceptual heart of the class.

> **Teaching point:** one system owns the phase and every transition.
> Smear a state machine across five files and nobody can say what state
> the day is in, or why.

The guard going back into `MenuInputSystem` — the menu goes inert
outside `choosing` — is what makes one confirm key safe to share with
every future listener.

```lua
elseif day.phase == "fade" then
    if not day.flipped and day.timer >= FADE_TIME / 2 then
        day.flipped = true    -- screen is black: change the world
        runState.day = runState.day + 1
        if runState.day > 5 then
            runState.day, runState.week = 1, runState.week + 1
        end
        SaveFile.save({ runState = runState })   -- autosave here
        textbox.text, textbox.visibleChars = PROMPT, 0
    end
    if day.timer >= FADE_TIME then
        day.phase, day.timer, day.flipped = "choosing", 0, false
    end
end
```

### 1:17 — The fade (8 min)

*new* `src/game/systems/FadeRenderSystem.lua` — add **last** in WeekScene

> **Teaching point:** no scene switch, no canvas — the last render
> system in the list simply paints over everyone before it. Dumb on
> purpose: alpha is a pure function of the day loop's clock, and this
> system advances nothing.

```lua
local half = FADE_TIME / 2
local alpha = day.timer < half
    and day.timer / half
    or 1 - (day.timer - half) / half
```

Keep `FADE_TIME` on the `DayLoopSystem` module, not local — the fade
derives its alpha from the same clock, so the duration needs exactly one
home.

### 1:25 — The date, upper-left (7 min)

*new* `src/game/systems/DateRenderSystem.lua`

Proof the clock moved.

> **Teaching point:** pure presentation owns no state — when the day
> loop flips the day behind the fade, the new date is simply what this
> system finds the next time it looks.

Left column is status (date, then the triangle below it); right column
is the menu.

### 1:32 — Checkpoint · the feature is done (6 min)

Play Mon→Fri end to end. Then quit and relaunch: it should come back on
the day you left. If this works, the class has already succeeded.

---

> ### ✂ Cut line
>
> Everything above is the day loop, complete and saving. If you reach
> 1:38 and it isn't running clean, **stop here** and make the triangle
> homework — the course plan already calls it the buffer lesson. Never
> ship a half-working state machine to thirty people's laptops.

---

### 1:38 — The stat triangle (20 min)

*new* `src/game/systems/RadarRenderSystem.lua`

Zero dependencies on the day loop — it's pure presentation over
`runState`.

> **Teaching point:** shape, not magnitude. The exact numbers stay
> hidden; the player reads that they're Int-heavy and Sense-lagging, and
> the fixed display ceiling makes the shape visibly fill toward the rim.
> Nothing in the game reads `DISPLAY_MAX` — the rim is representation,
> not rules.

`palette.lua` earns its keep here: color each spoke by its stat.

```lua
local CX, CY, R = 76, 230, 44   -- above the textbox at y=300
local DISPLAY_MAX = 30          -- half a 60-pick run: heavy spec

local AXES = {
  { stat = "int",   color = palette.int, angle = -math.pi / 2 },
  { stat = "charm", color = palette.cha, angle = math.pi - math.pi / 6 },
  { stat = "sense", color = palette.sen, angle = math.pi / 6 },
}

local function point(axis, f)
  return CX + math.cos(axis.angle) * R * f,
         CY + math.sin(axis.angle) * R * f
end
```

One gotcha worth naming out loud: skip the fill while all three stats
are zero — three corners on the center is a zero-area polygon, and LÖVE
will not thank you.

### 1:58 — Wrap (2 min)

Hand out homework, name what's next.

---

## System order in WeekScene

Worth putting on the projector — the order *is* the frame.

```lua
RunStateSystem      -- setup: the resource everything reads
MenuSetupSystem
TextboxSetupSystem

MenuInputSystem     -- input FIRST: it spawns the event
StatsSystem         -- three readers of activityPicked,
VignetteSystem      --   none aware of the others
DayLoopSystem
TextboxSystem

MenuRenderSystem    -- presentation
TextboxRenderSystem
DateRenderSystem
RadarRenderSystem
FadeRenderSystem    -- LAST: it paints over everyone
```

---

## Pack generation — doesn't fit today

Not close, and it's worth being honest about why rather than starting it
and abandoning it at 1:55.

- There's **no reference implementation to work from** — the
  `10-PackGeneration` branch contains one commit, and it's an art asset.
- It's a fresh design, not a transcription: weighted primary-stat pick,
  stat-bounded rolls, phrase pools per stat. **60–90 minutes minimum**,
  and live design goes slower than live typing.
- It needs the **card data model decided first**. That decision made
  under time pressure at the end of a class is a decision you'll be
  unwinding for the rest of the semester.

**Prep instead:** settle the card schema before next class — what fields
a card has, and which of them are rolled versus derived. Then pack
generation is a transcription lesson too, and it fits comfortably in its
own slot.

---

## Homework

- **Fill the pools.** `activities.lua` ships with 5 lines each; the GDD
  asks for 5–8 so repeats feel alive. Pure content — no code, no
  excuses.
- **Tune `DISPLAY_MAX`.** Play a week, then argue for a different
  ceiling. There's no right answer, which is the point.
- **Add a fourth activity** — rest, or a job. Notice what breaks: the
  menu layout is hardcoded to three, and the triangle has exactly three
  axes. That's a real lesson about where "data-driven" stopped.
- **If the triangle got cut:** build it from this run sheet.
