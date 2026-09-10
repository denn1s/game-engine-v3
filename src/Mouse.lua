-- The pointer, in GAME coordinates.
--
-- love.mouse.getPosition() answers "where is the mouse in the OS window,"
-- and that is the wrong question for a game system. The window belongs to
-- the platform; the game has its own resolution (src.Screen). In the plain
-- game the two coincide — the window IS the 640x400 screen — so the raw
-- position is already correct and the offset below is (0,0).
--
-- The editor breaks that coincidence on purpose: the game renders into a
-- canvas shown inside a viewport at an offset, the very situation Screen.lua
-- warns about for draw ("the editor broke it on purpose"). So the mouse
-- needs the same fix draw already has: something maps window pixels back
-- into game space, and the scene never learns it is being watched. This is
-- the input twin of attach.lua wrapping love.draw into a canvas.
--
-- Game code therefore asks Mouse for a position and never touches
-- love.mouse directly; only the editor installs a mapping (see
-- DebugOverlay.buildGameViewport). With the offset at its default the
-- math is identity, so the plain game behaves exactly as if it had read
-- love.mouse itself — which is why this bug only ever showed up under
-- --debug.

local Screen = require("src.Screen")

local Mouse = {}

-- The game canvas's top-left, in window pixels. Identity (0,0) is the
-- plain game; the editor overwrites it every frame it shows the viewport.
local originX, originY = 0, 0

-- The viewport's upscale factor. 1 in the plain game and at unscaled size;
-- the editor installs Screen.scale so the window-pixel gap between the
-- cursor and the viewport origin is turned back into GAME pixels by
-- dividing — the exact inverse of the scale imlove.Image draws the canvas at.
local scale = 1

-- Install where the game sits in the window. Not game API — only the
-- editor calls it. Passing nil restores the plain-mode identity.
function Mouse.setOrigin(x, y)
    if x then
        originX, originY = x, y
    else
        originX, originY = 0, 0
    end
end

-- Install the viewport upscale. Not game API — only the editor calls it.
-- Passing nil restores the 1:1 identity.
function Mouse.setScale(s)
    scale = (s and s > 0) and s or 1
end

-- The pointer in game pixels, plus whether it is over the game at all.
-- The inside flag is what lets a scene ignore a cursor that is actually
-- over an editor panel rather than the world — the game coordinate could
-- land anywhere once you subtract the viewport, so bounded-by-screen,
-- not bounded-by-window, is the honest test.
function Mouse.position()
    local mx, my = love.mouse.getPosition()
    local gx, gy = (mx - originX) / scale, (my - originY) / scale
    local inside = gx >= 0 and gx < Screen.w and gy >= 0 and gy < Screen.h
    return gx, gy, inside
end

return Mouse
