-- The Week scene: the raising sim. Princess Maker composition — her
-- room in the background, portrait center, the date as a big numeral
-- upper-right, the activity menu on the right, a text box along the
-- bottom. Built one system at a time; today: the menu.

local Scene = require("src.ecs.Scene")

local MenuInputSystem = require("src.systems.MenuInputSystem")
local MenuRenderSystem = require("src.systems.MenuRenderSystem")
local TextboxSystem = require("src.systems.TextboxSystem")
local TextboxRenderSystem = require("src.systems.TextboxRenderSystem")

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

    -- the text box: the bottom strip. Pure output — no input system.
    -- It types its line and sits there until someone (the vignette,
    -- next lesson) writes new text + visibleChars = 0 into it.
    scene.registry:spawn({
        position = { x = 12, y = 316 },
        size = { w = 616, h = 72 },
        textbox = {
            text = "What are you doing today?",
            visibleChars = 0,
            speed = 40, -- characters per second
        },
    })

    scene:addSystem(MenuInputSystem) -- input first: it writes what render reads
    scene:addSystem(TextboxSystem)
    scene:addSystem(MenuRenderSystem)
    scene:addSystem(TextboxRenderSystem)

    return scene
end
