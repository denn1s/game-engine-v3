-- The Week scene: the raising sim. Princess Maker composition — her
-- room in the background, portrait center, the date as a big numeral
-- upper-right, the activity menu on the right, a text box along the
-- bottom. Built one system at a time; today: the menu.

local Scene = require("src.ecs.Scene")

local MenuInputSystem = require("src.systems.MenuInputSystem")
local MenuRenderSystem = require("src.systems.MenuRenderSystem")

return function(payload)
    local scene = Scene.new("week")

    -- the activity menu: one entity, pure data. The systems below give
    -- it behavior (input) and a body (render).
    scene.registry:spawn({
        position = { x = 440, y = 96 },
        menu = {
            options = { "study", "grooming", "hobbies" },
            cursor  = 1,
            spacing = 64, -- horizontal distance between icon origins
        },
    })

    scene:addSystem(MenuInputSystem) -- input first: it writes what render reads
    scene:addSystem(MenuRenderSystem)

    return scene
end
