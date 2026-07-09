-- Shows the final score. The payload travels here inside the
-- switchRequest emitted by WinCheckSystem; the factory's job is to turn
-- that payload into DATA in the registry, where systems can query it.

local Scene = require("src.ecs.Scene")

local GameOverSystem = require("src.systems.GameOverSystem")
local GameOverRenderSystem = require("src.systems.GameOverRenderSystem")

return function(payload)
    local scene = Scene.new("gameover")

    scene.registry:spawn({
        finalScore = { left = payload.left, right = payload.right },
    })

    scene:addSystem(GameOverSystem)
    scene:addSystem(GameOverRenderSystem)

    return scene
end
