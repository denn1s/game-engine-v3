-- Draws the results screen from the `finalScore` resource the scene
-- factory made out of the switch payload, plus the `highscore` resource
-- the HighscoreSystem publishes (absent on a first-ever run).

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
    local finalScore = scene.registry:resource("finalScore")
    local screenW = Screen.w
    local screenH = Screen.h

    local winner = finalScore.left > finalScore.right and "Left" or "Right"

    love.graphics.setFont(bigFont)
    love.graphics.printf(winner .. " player wins!",
        0, screenH * 0.25, screenW, "center")
    love.graphics.printf(("%d - %d"):format(finalScore.left, finalScore.right),
        0, screenH * 0.42, screenW, "center")

    love.graphics.setFont(smallFont)
    local highscore = scene.registry:resource("highscore")
    if highscore and highscore.isNew then
        love.graphics.printf("a new best victory!",
            0, screenH * 0.58, screenW, "center")
    elseif highscore then
        love.graphics.printf(
            ("best victory: %d - %d"):format(highscore.winner, highscore.loser),
            0, screenH * 0.58, screenW, "center")
    end

    love.graphics.printf("press SPACE for the menu",
        0, screenH * 0.7, screenW, "center")
end

return GameOverRenderSystem
