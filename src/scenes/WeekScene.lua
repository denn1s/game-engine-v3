-- The Week scene: the raising sim. Princess Maker composition — her
-- room in the background, portrait center, the date as a big numeral
-- upper-right, the activity menu on the right, a text box along the
-- bottom. The day loop lives here: pick an activity, a vignette
-- plays, the day fades over — twelve weeks of it.

local Scene = require("src.ecs.Scene")
local SaveFile = require("src.state.SaveFile")

local MenuInputSystem = require("src.systems.MenuInputSystem")
local StatsSystem = require("src.systems.StatsSystem")
local VignetteSystem = require("src.systems.VignetteSystem")
local DayLoopSystem = require("src.systems.DayLoopSystem")
local TextboxSystem = require("src.systems.TextboxSystem")
local MenuRenderSystem = require("src.systems.MenuRenderSystem")
local TextboxRenderSystem = require("src.systems.TextboxRenderSystem")
local DateRenderSystem = require("src.systems.DateRenderSystem")
local FadeRenderSystem = require("src.systems.FadeRenderSystem")

return function(payload)
    local scene = Scene.new("week")

    -- RUN state: the one table every scene of the game reads and
    -- writes (GDD §10) — and the thing the save file persists. Loaded
    -- fresh from disk every time the scene is built; defaults are what
    -- week 1, Monday morning looks like. (Saving it back is the recap
    -- lesson's job.)
    local data = SaveFile.load()
    scene.registry:setResource("runState",
        data and data.runState or {
            week = 1,
            day = 1, -- 1..5, Mon-Fri
            stats = { int = 0, charm = 0, sense = 0 },
        })

    -- SCENE state, by contrast: the day loop's phase machine lives and
    -- dies with the scene and is never saved. Compare with runState
    -- above — that split is the whole lesson-05 distinction, in code.
    scene.registry:setResource("dayloop", {
        phase = "choosing", -- choosing -> vignette -> fade -> choosing
        timer = 0,
        flipped = false, -- has this fade already advanced the day?
    })

    -- the activity menu: one entity, pure data
    scene.registry:spawn({
        position = { x = 440, y = 96 },
        menu = {
            options = { "study", "grooming", "hobbies" },
            cursor  = 1,
            spacing = 64, -- horizontal distance between icon origins
        },
    })

    -- the text box: the bottom strip. Pure output — the vignette and
    -- the day loop write into it, the typewriter does the rest.
    scene.registry:spawn({
        position = { x = 12, y = 316 },
        size = { w = 616, h = 72 },
        textbox = {
            text = "What are you doing today?",
            visibleChars = 0,
            speed = 40, -- characters per second
        },
    })

    -- input first, then the three reactions to activityPicked, then
    -- presentation — fade LAST, it paints over everyone
    scene:addSystem(MenuInputSystem)
    scene:addSystem(StatsSystem)
    scene:addSystem(VignetteSystem)
    scene:addSystem(DayLoopSystem)
    scene:addSystem(TextboxSystem)
    scene:addSystem(MenuRenderSystem)
    scene:addSystem(TextboxRenderSystem)
    scene:addSystem(DateRenderSystem)
    scene:addSystem(FadeRenderSystem)

    return scene
end
