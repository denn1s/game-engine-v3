-- The title screen. A scene file is a FACTORY: it returns a function
-- that builds the scene fresh every time the Game switches to it.

local Scene = require("src.ecs.Scene")
local SaveFile = require("src.state.SaveFile")

local MenuSystem = require("src.systems.MenuSystem")
local MenuRenderSystem = require("src.systems.MenuRenderSystem")

return function(payload)
    local scene = Scene.new("menu")

    -- the save file is the only thing that survives between scenes (and
    -- between runs of the game). The title screen reads it fresh every
    -- time it's built — nothing on screen is ever "remembered", it's
    -- all rebuilt from data.
    local data = SaveFile.load()
    if data and data.bestVictory then
        scene.registry:setResource("highscore", data.bestVictory)
    end

    scene:addSystem(MenuSystem)
    scene:addSystem(MenuRenderSystem)

    return scene
end
