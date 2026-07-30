-- Draws the day transition: a fullscreen black rectangle whose alpha
-- ramps to opaque and back. That is the ENTIRE trick — no scene
-- switch, no canvas: the last render system in the list simply paints
-- over everyone before it.
--
-- Dumb on purpose: alpha is a pure function of the dayloop's phase
-- and timer. This system advances nothing — the DayLoopSystem is the
-- clock, and it flips the day at the midpoint, exactly when this
-- rectangle is fully opaque.

local Screen = require("src.Screen")
local FADE_TIME = require("src.systems.DayLoopSystem").FADE_TIME

local FadeRenderSystem = { name = "fadeRender" }

function FadeRenderSystem.draw(scene)
    local day = scene.registry:resource("dayloop")
    if day.phase ~= "fade" then return end

    local half = FADE_TIME / 2
    local alpha
    if day.timer < half then
        alpha = day.timer / half -- fading out
    else
        alpha = 1 - (day.timer - half) / half -- fading back in
    end

    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, Screen.w, Screen.h)
    love.graphics.setColor(1, 1, 1)
end

return FadeRenderSystem
