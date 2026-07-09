# Lesson 01 — Pong from scratch (Lab 1)

> PIA weeks 2–3 · Branch `01-Pong` · Previous: `00-GameLoops`

```sh
love .
```

**W/S** and **UP/DOWN** move the paddles, **SPACE** serves. First to 5 wins.

See exactly what we wrote this class:

```sh
git diff 00-GameLoops..01-Pong
```

## What this lesson covers

We go from "a loop that moves squares" to a **complete game**: input,
movement, collision, scoring, win condition, and restart. Everything the rest
of the course does is a more organized version of what's in these ~200 lines.

### 1. Splitting code into modules

`main.lua` was getting crowded, so the paddle and ball live in their own files:

```lua
local Paddle = require("src.paddle")
```

`require("src.paddle")` runs `src/paddle.lua` **once**, caches it, and returns
whatever that file `return`s. Our modules return a table of functions — that
table is the module's public API.

### 2. Lua "classes" with metatables

Lua doesn't have classes; it has tables and metatables. The idiom:

```lua
local Paddle = {}
Paddle.__index = Paddle           -- "if you don't find a key, look in Paddle"

function Paddle.new(x, y)
    local self = setmetatable({}, Paddle)
    self.x, self.y = x, y
    return self
end

function Paddle:update(dt) ... end -- colon = hidden `self` parameter
```

Every paddle instance is its own table with its own `x, y`, but they all share
the same `update`/`draw` functions through the metatable. This pattern carries
us until lesson 02, where ECS replaces it for game objects.

### 3. Input: polling vs events

- **Polling** (`love.keyboard.isDown("w")`) — asked every frame. Right for
  *continuous* actions: holding a key to move.
- **Events** (`love.keypressed(key)`) — fired once per press. Right for
  *discrete* actions: serving, pausing, restarting.

Using the wrong one is a classic beginner bug (a "jump" that repeats every
frame while held, or movement that only steps once per press).

### 4. AABB collision

Two axis-aligned rectangles overlap unless one is fully to the left of or
above the other:

```lua
a.x < b.x + b.w and b.x < a.x + a.w and
a.y < b.y + b.h and b.y < a.y + a.h
```

Two details that separate "works" from "feels right":

- **Push the ball out** of the paddle before reflecting it, or it can get
  stuck inside, re-colliding every frame.
- **"English":** the bounce angle depends on where the ball hits the paddle.
  That single line is what makes Pong a game of skill instead of a screensaver.

### 5. Game states

`state` is `"serve"`, `"play"` or `"gameover"`, and both `update` and `draw`
branch on it. This is the embryo of the **scene system** we'll build properly
in a few weeks (menu → overworld → card battle → date scene...).

## Exercises (for your own game repo)

1. The ball can tunnel through a paddle if it's fast enough (it moves more
   than a paddle-width in one frame). Why? What are two ways to fix it?
2. Add a single-player mode: the right paddle follows the ball. Then make it
   beatable (cap its speed, add reaction delay).
3. Add a "juice" touch: screen flash on score, or paddles that stretch on hit.

## Next class

`02-ECS` — same Pong, but rebuilt on an Entity-Component-System architecture.
The game looks identical; the code becomes an engine.
