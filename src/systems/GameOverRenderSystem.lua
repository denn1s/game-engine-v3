-- Draws the results screen from the `finalScore` data the scene factory
-- spawned out of the switch payload.

local Screen = require("src.Screen")

local GameOverRenderSystem = { name = "gameOverRender" }

local bigFont, smallFont

function GameOverRenderSystem.setup(scene)
    bigFont = love.graphics.newFont(48)
    smallFont = love.graphics.newFont(16)
end

function GameOverRenderSystem.unload(scene)
    -- drop the references; the GC collects them. See RenderSystem.unload
    -- for why we never release() fonts.
    bigFont, smallFont = nil, nil
end

function GameOverRenderSystem.draw(scene)
    local _, finalScore = scene.registry:first("finalScore")
    local screenW = Screen.w
    local screenH = Screen.h

    local winner = finalScore.left > finalScore.right and "Left" or "Right"

    love.graphics.setFont(bigFont)
    love.graphics.printf(winner .. " player wins!",
        0, screenH * 0.25, screenW, "center")
    love.graphics.printf(("%d - %d"):format(finalScore.left, finalScore.right),
        0, screenH * 0.42, screenW, "center")

    love.graphics.setFont(smallFont)
    love.graphics.printf("press SPACE for the menu",
        0, screenH * 0.7, screenW, "center")
end

return GameOverRenderSystem
