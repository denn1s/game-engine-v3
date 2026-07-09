----------------------------------------------------------------------
-- A game loop with NO engine at all. Run it in a terminal:
--
--   lua loop.lua      (or: luajit loop.lua)
--
-- A "ball" bounces across one line of text for 15 seconds.
-- This file is the whole point of the lesson: every game you have ever
-- played is this loop, with better update() and render() functions.
----------------------------------------------------------------------

local FPS_CAP = 30
local DURATION = 15 -- seconds; we have no input, so we quit on a timer
local WIDTH = 60    -- columns of our "screen"
local SPEED = 25    -- columns per SECOND (note: dt-based, like always)

local now = os.clock

----------------------------------------------------------------------
-- 1. INIT: create the world
----------------------------------------------------------------------
local ball = { x = 1, dir = 1 }
io.write("\27[?25l") -- ANSI escape code: hide the terminal cursor

local function update(dt)
    ball.x = ball.x + ball.dir * SPEED * dt
    if ball.x >= WIDTH then ball.x, ball.dir = WIDTH, -1 end
    if ball.x <= 1 then ball.x, ball.dir = 1, 1 end
end

local function render(fps)
    local col = math.floor(ball.x + 0.5)
    local line = string.rep(".", col - 1) .. "@" .. string.rep(".", WIDTH - col)
    io.write(("\r[%s] %3d FPS"):format(line, fps)) -- \r = redraw same line
    io.flush()
end

----------------------------------------------------------------------
-- 2. THE GAME LOOP
----------------------------------------------------------------------
local startTime = now()
local last = startTime

while now() - startTime < DURATION do
    local frameStart = now()

    -- HANDLE EVENTS: a real engine reads keyboard/mouse/window events
    -- here. A plain terminal can't do non-blocking input portably —
    -- reason #1 why game engines exist.

    -- UPDATE: how long did the last frame take? Simulate that much time.
    local dt = frameStart - last
    last = frameStart
    update(dt)

    -- RENDER: draw the new state of the world.
    render(dt > 0 and math.floor(1 / dt + 0.5) or 0)

    -- FRAME END: wait out the rest of the frame so we run at FPS_CAP.
    -- Plain Lua has no sleep() either (reason #2 engines exist), so we
    -- busy-wait: this burns 100% of a CPU core doing nothing. Engines
    -- ask the OS to sleep instead (LÖVE: love.timer.sleep).
    while now() - frameStart < 1 / FPS_CAP do end
end

----------------------------------------------------------------------
-- 3. CLEANUP: release what we took (here: restore the cursor)
----------------------------------------------------------------------
io.write("\27[?25h\nDone. That was a game loop.\n")
