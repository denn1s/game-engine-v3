-- The parts of the lesson you can't see by looking at the sprite alone.
-- It draws AFTER the character (added last), so its overlays sit on top.
--
-- Three readouts, each aimed at a claim this lesson makes:
--
--   1. The velocity arrow.  The literal vector being integrated. Watch
--      it stay the SAME LENGTH whether you walk straight or diagonal
--      (normalized) — that constant length IS the lesson.
--   2. The ghost arrow.  Where you WOULD go with no normalization:
--      longer on diagonals. The gap between the two arrows is the
--      sqrt(2) bug, made physical. Toggle it away with N and they merge.
--   3. Numbers.  Raw input magnitude vs the px/sec actually applied.
--
-- This is DebugTools (lesson 04) applied to a NEW subject: not "what
-- entities exist" but "what is my code deciding every frame." A vector
-- you can draw is a vector you can reason about.

local Screen = require("src.Screen")
local Movement = require("src.world.Movement")

local MapHudRenderSystem = { name = "mapHud" }

local ROW_NAMES = { [1] = "down", [2] = "left", [3] = "right", [4] = "up" }
local cream = { 0.94, 0.89, 0.76 }
local faint = { 0.94, 0.89, 0.76, 0.45 }
local bright = { 0.31, 0.83, 0.55 }   -- applied velocity
local ghost = { 1.0, 0.31, 0.38 }     -- unnormalized (the bug)

local arrowLen = 0.18                 -- seconds of travel to draw an arrow

local smallFont

function MapHudRenderSystem.setup(scene)
    smallFont = love.graphics.newFont(10)
end

function MapHudRenderSystem.unload(scene)
    smallFont = nil
end

local function arrow(x, y, vx, vy, color)
    love.graphics.setColor(color)
    love.graphics.setLineWidth(2)
    love.graphics.line(x, y, x + vx, y + vy)
    love.graphics.circle("fill", x + vx, y + vy, 2.5)
    love.graphics.setLineWidth(1)
end

function MapHudRenderSystem.draw(scene)
    local registry = scene.registry
    local map = registry:resource("map")

    for _, pos, intent, velocity, sprite in
        registry:each("position", "moveIntent", "velocity", "sprite") do

        local cell = sprite.w * (sprite.scale or 1)
        local cx, cy = pos.x + cell / 2, pos.y + cell / 2

        -- applied velocity (this is what actually integrated position)
        arrow(cx, cy, velocity.x * arrowLen, velocity.y * arrowLen, bright)

        -- ghost: the SAME input with normalization forced off, so on a
        -- diagonal the red arrow outruns the green one
        local gx, gy = Movement.direction(intent.dx, intent.dy, false)
        arrow(cx, cy, gx * map.speed * arrowLen, gy * map.speed * arrowLen, ghost)
    end

    love.graphics.setFont(smallFont)
    love.graphics.setColor(cream)
    love.graphics.print("ARROWS/WASD  walk", 12, Screen.h - 40)
    love.graphics.setColor(faint)
    love.graphics.print("N  normalization " .. (map.normalize and "ON" or "OFF"),
        12, Screen.h - 26)

    for _, intent, sprite in registry:each("moveIntent", "sprite") do
        local rawMag = math.sqrt(intent.dx * intent.dx + intent.dy * intent.dy)
        love.graphics.setColor(cream)
        love.graphics.print(
            ("facing %s   |input|=%.2f   %d px/s"):format(
                ROW_NAMES[sprite.row] or "?", rawMag,
                math.floor((map.normalize and map.speed or map.speed * rawMag) + 0.5)),
            Screen.w - 250, 12)
    end
end

return MapHudRenderSystem
