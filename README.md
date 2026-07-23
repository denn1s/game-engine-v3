# Lesson 04.5 — The editor window: the game in a viewport

> PIA week 5 · Branch `04.5-GameViewport` · Previous: `04-DebugTools`
>
> **Optional lesson.** Everything after this builds on `04-DebugTools`,
> not on this branch. Skip it freely; come back when you wonder how Unity
> puts a running game *inside* the editor.

```sh
love . --debug     # the editor: big window, game in a viewport
love .             # the plain game, exactly as in lesson 04 (F1 works)
```

**F1** toggles the tool panels (the viewport stays — it's the game) ·
**F9** pauses · **F10** steps one frame.

```sh
git diff 04-DebugTools..04.5-GameViewport
```

## 1. The one idea: a render target

Unity's Game view looks like magic — a whole game running inside a panel —
but it is one primitive doing all the work: the game doesn't draw to the
screen, it draws into a **texture** (a *render target*), and the editor UI
displays that texture like it would display any image.

LÖVE's render target is `love.graphics.Canvas`:

```lua
gameCanvas = love.graphics.newCanvas(960, 540)

love.graphics.setCanvas(gameCanvas) -- everything now lands in the texture
Game.draw()
love.graphics.setCanvas()           -- back to the real screen
```

The draw wrapper in `src/debug/attach.lua` brackets the game's draw with
exactly that (via `DebugOverlay.beginGameDraw`/`endGameDraw`, no-ops
outside editor mode) — main.lua doesn't change at all:

```lua
love.draw = function()
    DebugOverlay.beginGameDraw() -- editor mode: redirect into the canvas
    draw()                       -- the wrapped Game.draw
    DebugOverlay.endGameDraw()   -- back to the real screen
    DebugOverlay.draw()          -- UI on top (incl. the viewport)
end
```

The scenes keep drawing at 960×540 like they always did, and can't tell
whether the "screen" is real or a texture inside a bigger window.

At least, that was the theory.

## 2. The first thing the editor did was find a bug

The very first `--debug` launch drew PONG's title well right of the
viewport's center. Nothing in the viewport code was wrong — the *game*
was. Every system asked the platform for the playfield size:

```lua
local screenW = love.graphics.getWidth()
```

and `getWidth()` answers for the **OS window** — 1440 in the editor —
while the canvas the game actually draws into is 960 wide. Menus centered
themselves 240px too far right; balls would spawn off-center; paddles
clamped against a floor that isn't where the screen ends. The assumption
"the window IS the game" had been in every system since lesson 01. It was
never wrong before — window and game were always the same 960×540 — so it
never detonated. The editor made them differ, and the bug walked right
out. (Same shape as lesson 04's war story: tools don't create these bugs,
they *reveal* them.)

The fix is `src/Screen.lua`, all of one line of data:

```lua
return { w = 960, h = 540 }
```

The game's logical resolution, written down exactly once. `conf.lua` reads
it to size the real window, every system reads it instead of asking
`love.graphics`, and the editor reads it to size the canvas. The window
belongs to the platform; the **resolution belongs to the game**. Unity
draws the same line: `Screen.width` in game code reports the game's
resolution, never the editor window's.

## 3. Entering the editor

`--debug` used to just show the overlay; now it calls
`DebugOverlay.enterEditor()`, which does five small things:

1. grows the OS window to 1.5× the game's resolution,
2. creates the canvas at `Screen.w × Screen.h`,
3. repaints the backdrop: the editor's background is gray, so the black
   belongs to the game — the viewport visibly *owns* its pixels (the
   canvas clears to black in `beginGameDraw`),
4. points imlove at its own layout file, `imlove-editor.ini` — positions
   saved in a 1440-wide editor make no sense in the 960-wide plain game,
   so the two modes must never share one,
5. shows the overlay.

There is no way back at runtime, and that's fine: editor vs. game is a
decision you make when you launch, not a mode to toggle mid-match.

## 4. The viewport is just a widget

imlove grew one widget for this, `Image` — the equivalent of
`ImGui::Image()`, and the same widget real engines use for their viewports:

```lua
imlove.SetNextWindowPos((sw - gw) / 2 - pad, (sh - gh) / 2 - pad)
if imlove.Begin("viewport", nil, { "NoTitleBar", "AlwaysAutoResize" }) then
    imlove.Image(gameCanvas)
end
imlove.End()
```

Three details worth reading twice in `DebugOverlay.lua`:

- **`NoTitleBar` + repositioned every frame** — the viewport is furniture,
  like the transport bar: always centered, not draggable, no chrome
  competing with the game.
- **It is not gated on `visible`.** F1 hides the *tools*; hiding the game
  itself would just be a broken screen.
- The Inspector and Engine panels now start **snapped** to the left and
  right edges (`SetNextWindowSnap(..., "once")`) — full-height side rails
  around the centered viewport. `"once"` means it's a default layout, not
  a law: drag them free if you prefer floating windows.

## 5. What this costs: input got more interesting

The keyboard path is unchanged — key events don't care where pixels land.
The mouse is another story, and it's worth understanding *before* our card
game makes the mouse matter:

- Screen coordinates no longer equal game coordinates. A click at (600,
  400) in the editor window is somewhere else entirely inside the 960×540
  canvas — the viewport's offset (and scale, if you ever scale it) must be
  undone first.
- Clicks on the viewport are currently swallowed by the UI (`imlove`
  reports the viewport window like any other window — correct, but the
  game never hears them).

We didn't solve this today because pong doesn't use the mouse. Unity did
have to: its Game view remaps every mouse event into game coordinates
before the game sees it. That's exercise 1.

## Exercises (for your own game repo)

1. **Mouse remapping.** Add `DebugOverlay.gameMouse()` returning the mouse
   position in *game* coordinates (or `nil` when the cursor is outside the
   viewport). You'll need the viewport's rectangle — where does the
   overlay already know it?
2. **Viewport scale.** Add a small combo (0.5× / 1× / 1.5×) to the Engine
   panel that changes the *displayed* size of the canvas —
   `imlove.Image(gameCanvas, gw * s, gh * s)` — without touching the
   game's resolution. What must the exercise-1 remap learn?
3. **Own the resolution.** The editor window is hardcoded to 1.5×. Make it
   resizable (`t.window.resizable`) and keep the viewport centered. What
   should happen when the window gets *smaller* than the game?
4. **A second view.** Unity has a Game view *and* a Scene view. Render the
   same registry a second time into a second canvas with a debug-only
   camera (say, zoomed out 2×) and show it in a second window. What does
   that force your render systems to parameterize?

## Next class

Back on the main line: `05` — the card game begins: the real title screen,
images from files, and the asset cache that finally kills the font smell
from lesson 03.
