-- Shows the final score. The payload travels here inside the
-- switchRequest emitted by WinCheckSystem; the factory's job is to turn
-- that payload into DATA in the registry, where systems can query it.

local Scene = require("src.ecs.Scene")

local GameOverSystem = require("src.systems.GameOverSystem")
local HighscoreSystem = require("src.systems.HighscoreSystem")
local GameOverRenderSystem = require("src.systems.GameOverRenderSystem")

return function(payload)
    -- the debug scene switcher can jump here directly, with no payload.
    -- A scene you can't enter directly is a scene you can't test
    -- directly, so factories default their payloads instead of assuming.
    payload = payload or {}

    local scene = Scene.new("gameover")

    scene.registry:setResource("finalScore", {
        left = payload.left or 0,
        right = payload.right or 0,
    })

    scene:addSystem(GameOverSystem)
    scene:addSystem(HighscoreSystem) -- reads finalScore: after the factory set it
    scene:addSystem(GameOverRenderSystem)

    return scene
end
