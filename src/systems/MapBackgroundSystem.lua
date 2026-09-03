-- Clears the frame to the map's floor color and draws its boundary.
--
-- "Why is a plain background its own system?" — because ordering is the
-- whole game of ECS. Something has to run BEFORE SpriteRenderSystem or
-- the character is painted over. Making the floor a system puts that
-- dependency in the system list where students can SEE it, instead of
-- hiding a love.graphics.clear at the top of some catch-all render
-- function. One responsibility, one system.
--
-- It is also where the flat-color art policy lives (docs/LESSON_PLAN.md):
-- a dark, intentional floor already reads as "a place," not a demo.
-- Real tile floors replace exactly this system in lesson 14.

local Screen = require("src.Screen")

local MapBackgroundSystem = { name = "mapBackground" }

local floor = { 0.13, 0.13, 0.17 }
local edge = { 0.20, 0.20, 0.26 }

function MapBackgroundSystem.draw(scene)
    love.graphics.setColor(floor)
    love.graphics.rectangle("fill", 0, 0, Screen.w, Screen.h)

    love.graphics.setColor(edge)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 1, 1, Screen.w - 2, Screen.h - 2)
    love.graphics.setLineWidth(1)
end

return MapBackgroundSystem
