# Lesson 00 — Game Loops

> PIA week 2 · Branch `00-GameLoops` · Previous: `main`

## Part A — a game loop with no engine

Every game engine, from Pong to Unreal, is built around the same loop:

```
init
while running:
    frame start      (measure time)
    handle events    (input, window events)
    update           (simulate the world)
    render           (draw the world)
    frame end        (wait / limit frame rate)
cleanup
```

A game is a simulation that redraws itself 30–144+ times per second. Each
pass through the loop is a **frame**. To prove there's no magic, we write one
in plain Lua, in a terminal, with no engine at all:

```sh
lua loop.lua
```

A ball bounces across a line of text at 30 FPS. Read `loop.lua` top to bottom
— it's the diagram above, literally.

Writing it raw also shows exactly **why engines exist**. Twice we hit a wall:

1. **No input.** A terminal can't portably read keys without blocking the
   loop. An engine talks to the OS and hands you an event queue.
2. **No sleep.** Plain Lua can't wait efficiently, so we busy-wait and burn
   100% of a CPU core to animate one character. Watch `htop` while it runs.
   An engine asks the OS to sleep the leftover frame time.

(Also missing: a window, graphics, sound, controllers... all of it is "stuff
around the same loop".)

## Part B — the same loop, inside LÖVE

```sh
love .
```

In LÖVE we don't write the `while` loop — LÖVE runs it for us, in a function
called `love.run`, and calls **our** functions at each stage:

| Loop stage | loop.lua | LÖVE callback |
|---|---|---|
| init | top of file | `love.load()` |
| handle events | *(impossible!)* | `love.keypressed`, `love.mousepressed`, ... |
| update | `update(dt)` | `love.update(dt)` |
| render | `render()` | `love.draw()` |
| frame end | busy-wait | vsync / `love.timer.sleep` |
| cleanup | bottom of file | `love.quit()` |

This is LÖVE's actual background loop, lightly simplified — compare it with
`loop.lua`, stage by stage:

```lua
function love.run()
    love.load()
    love.timer.step()
    return function()                       -- called once per frame, forever
        love.event.pump()                   -- HANDLE EVENTS
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" then return a or 0 end
            love.handlers[name](a, b, c, d, e, f)
        end
        local dt = love.timer.step()        -- FRAME START: measure dt
        love.update(dt)                     -- UPDATE
        love.graphics.clear()               -- RENDER
        love.draw()
        love.graphics.present()
        love.timer.sleep(0.001)             -- FRAME END
    end
end
```

(It's replaceable — you can define your own `love.run` — but we won't need to.)

## Part C — `dt`, the most important variable in the course

`dt` (delta time) is how many **seconds** the previous frame took. At 60 FPS,
`dt ≈ 0.0167`. The LÖVE demo has two squares:

- **Green:** `x = x + SPEED * dt` → moves `SPEED` pixels per **second**,
  no matter the frame rate.
- **Red:** `x = x + PIXELS_PER_FRAME` → moves per **frame**, so its
  real-world speed changes with the FPS.

Press SPACE and cycle the cap: uncapped → 30 → 60 → 144. The green square
never changes speed. The red one crawls at 30 FPS and rockets when uncapped.
That red square is a real bug that shipped in real games (it's why some old
games go crazy on modern PCs).

**Rule for the whole semester: anything that moves or changes over time gets
multiplied by `dt`.**

Note `conf.lua` turns **vsync** off for this demo. With vsync on (LÖVE's
default), the GPU driver blocks each frame until the monitor refreshes — a
built-in frame cap at the refresh rate, which would hide the experiment.

## Exercises (for your own game repo)

1. In `loop.lua`: make the ball bounce in 2D (an X and Y position on a grid
   of lines). Hint: ANSI code `\27[2J\27[H` clears the terminal.
2. Print `dt` on screen in the LÖVE demo. How stable is it at each cap?
3. **Challenge — fixed timestep:** make updates run in fixed `1/60` steps
   using an accumulator (`accum = accum + dt; while accum >= STEP do
   update(STEP); accum = accum - STEP end`). This is how physics engines stay
   deterministic. We'll come back to this idea later in the course.

## Next class

`01-Pong` — we use this loop to build a complete game from scratch.
