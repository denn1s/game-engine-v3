-- The title screen. A scene file is a FACTORY: it returns a function
-- that builds the scene fresh every time the Game switches to it.

local Scene = require("src.ecs.Scene")

local MenuSystem = require("src.systems.MenuSystem")
local MenuRenderSystem = require("src.systems.MenuRenderSystem")

return function(payload)
    local scene = Scene.new("menu")

    scene:addSystem(MenuSystem)
    scene:addSystem(MenuRenderSystem)

    return scene
end
