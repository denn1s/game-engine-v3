# Lesson 04 — Debug tools: the entity inspector

> PIA week 5 · Branch `04-DebugTools` · Previous: `03-Scenes`

```sh
love . --debug     # start with the inspector open
love .             # or press F1 in game
```

**F1** toggles the inspector · **F9** pauses · **F10** steps one frame.

```sh
git diff 03-Scenes..04-DebugTools
```

## 1. Our first (and only) dependency

Everything in this course is written from scratch — except this. Today we
**vendor** a library: [imlove](../imlove), an immediate-mode UI for LÖVE,
written in pure Lua, whose API deliberately mirrors
[Dear ImGui](https://github.com/ocornut/imgui) — the tool used for debug UIs
in a huge share of real engines (and what the C++/Odin people among you
would use directly).

Vendoring means: copy `imlove.lua` into `lib/`, commit it, done. No package
manager, no version drift, and the file is right there when you're curious.
That's how game studios actually consume small dependencies. Read its README
before class — integrating a library *from its docs* is the skill being
practiced; we will not study its internals (building UI is its own lesson,
later, when your game needs menus and card hands).

## 2. Immediate-mode UI, the 5-minute version

There are two ways to build UIs:

- **Retained mode** (the DOM, Qt, Unity's UI Toolkit): you *create* widget
  objects, they persist, you mutate them, and callbacks fire back at you.
- **Immediate mode** (Dear ImGui, and now imlove): there are no widget
  objects. Every frame you *call functions* — and the call is the widget:

```lua
if imlove.Button("step (F10)") then
    stepOnce = true
end
```

The button "exists" only because that line runs this frame. State lives in
*your* variables, not in the UI; the `if` handles the click right where the
button is declared. For tools that visualize rapidly-changing game state,
this is dramatically less code — the UI is redeclared from the current truth
every frame, so it can never be stale. (Sound familiar? Our `RenderSystem`
redraws the world from the registry every frame. Same philosophy.)

The cost: the UI must actually run every frame, and identity needs care —
two widgets with the same label are the same widget, which is why lists use
`PushID`/`PopID` (see the entity loop in `DebugOverlay.lua`).

## 3. The overlay is engine, not game

`src/debug/DebugOverlay.lua` is **not a system** and belongs to no scene. It
sits *next to* the Game, watching whatever `Game.current()` returns, and it
survives scene switches. Scenes never know it's there. That's the right
altitude for tools: they observe the game from outside, like a debugger
observes a process.

And the wiring lives in its own file too: `src/debug/attach.lua` *wraps*
the LÖVE callbacks that main.lua defined, so main.lua stays pure game
bootstrap — it never mentions how the overlay hooks in. Self-installing
tools are the idiomatic LÖVE pattern (lovebird, lurker and lovedebug all
work this way). Inside the wrappers you'll find the standard imgui
integration dance:

```lua
DebugOverlay.beginFrame(game.current())   -- top of love.update
if DebugOverlay.shouldUpdate() then       -- the pause gate
    update(dt)                            -- the wrapped Game.update
end
...
draw()                                    -- the wrapped Game.draw
DebugOverlay.draw()                       -- last: UI on top
```

and every input event asks the overlay first:

```lua
love[event] = function(...)
    if DebugOverlay[event](...) then return end -- UI consumed it
    if original then original(...) end
end
```

That "ask the UI first" pattern is `WantCaptureMouse` from real ImGui, and it
matters *now* because our card game will be mouse-driven: without it,
clicking a debug button would also click whatever card is under the cursor.

## 4. Tools need reflection: two new Registry queries

The game never asks "which entities exist?" — systems always know which
components they want. But the inspector must display *everything, without
knowing any component names up front*. So the Registry gains two
tool-oriented queries:

```lua
registry:entities()           -- every entity, sorted
registry:componentsOf(entity) -- its component names, sorted
```

This is reflection, engine-flavored, and it's a pattern worth noticing:
building a tool often forces the engine to grow an introspection API that
gameplay code never needed.

## 5. Pause and frame-step

Pause is one boolean in the right place. `DebugOverlay.shouldUpdate()` gates
`Game.update` — and *only* `Game.update`: drawing continues (you're looking
at the frozen frame) and the overlay continues (a paused game with a dead UI
would be useless). "Step" grants exactly one update while paused.

Details that make it trustworthy:

- Hiding the overlay lifts the pause — a game frozen by an invisible tool is
  a bug report waiting to happen.
- The selected entity is validated every frame (it may have been destroyed)
  and the selection resets on scene switches (entity numbers restart with
  each registry).

## 6. The class demo: catching an event in the act

The payoff for everything this course has built so far:

1. Start a match, press **F9** to pause.
2. Select the ball; drag its `position.x` slider — you're editing the
   simulation mid-frame, and the render system draws whatever you set,
   because the registry *is* the game state and everything else just reads it.
3. Now nudge `position.x` past the right edge and press **F10** once.
   Look at the entity list: the ball is **gone**, the score went up, and a
   brand-new entity holding only a `serveRequest` component sits in the list
   — the event, frozen in the one frame of its life.
4. Press **F10** again: the request is gone, a new ball exists (new entity
   number — check it), and the serve is in flight.

You just *watched* the events-as-entities pattern from lesson 02 execute,
frame by frame. Also fun: pause on the menu, press SPACE, and find the
lingering `switchRequest` — it executes the moment you unpause.

## 7. A war story: the tool found a real bug

The first time this lesson ran, starting a match crashed the game:
`Cannot use object after it has been released`. The chain: our render
systems called `font:release()` in `unload`; the released font was still
`love.graphics`' *current* font; and imlove v1.0.0 adopted the current font
as its UI font at `NewFrame` — so that same frame's `Render` drew with a
dead object. A **use-after-free, in Lua.**

Two fixes shipped:

- **imlove v1.0.1** creates and owns its font. A tool must not depend on
  objects whose lifetime the game controls.
- Our `unload` hooks now just **drop references** and let the garbage
  collector free them. `release()` reclaims GPU memory immediately, which
  sounds responsible — but calling it on something that shared state still
  references trades a little memory for a crash. In a GC language, dropping
  the reference *is* the cleanup; reach for `release()` only on big assets
  you can prove nothing else holds.

Note the shape of the event: the bug has existed since lesson 03 — it just
never detonated, because nothing *used* the released font before something
replaced it. It worked by luck. The inspector didn't create the bug; it
revealed it. Good tools do that, and it's also why you integrate tools
early instead of "when we need them".

## Exercises (for your own game repo)

1. Add a **spawn ball** button to the inspector. (One `Button` call plus one
   `spawn` — but *which* registry, and what happens if you press it on the
   menu scene? Make it behave sensibly.)
2. Add a **time scale** slider (0.1×–3×) that multiplies the `dt` passed to
   `Game.update`. Slow motion for free — where's the right place to apply it?
3. Show the scene's systems in the inspector, in order. What's missing from
   our system tables to display them nicely, and what's the least invasive
   way to add it?
4. The number sliders are hard-coded to ±960, which is clumsy for `winScore`
   and useless for very large values. Real ImGui solves this with `DragFloat`
   (unbounded, drag to change). Read imlove's README: what would you propose
   for its v1.1?

## Next class

`05` — the card game begins: the real title screen, images from files, and
the asset cache that finally kills the font smell from lesson 03.
