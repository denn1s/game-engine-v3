-- Plays the vignette's THEATER: on a pick, choose a flavor line from
-- the activity's pool and hand it to the textbox. That's all — the
-- stat bump is StatsSystem's job, and the phase flip is the
-- DayLoopSystem's. Three systems react to one `activityPicked` event,
-- and none of them knows the others exist.

local activities = require("src.data.activities")

local VignetteSystem = { name = "vignette" }

function VignetteSystem.update(scene, dt)
    for _, pick in scene.registry:each("activityPicked") do
        local pool = activities[pick.option].lines
        local line = pool[love.math.random(#pool)]

        -- the typewriter's contract (see TextboxSystem): new text,
        -- progress to zero, and it starts over on its own
        local _, textbox = scene.registry:first("textbox")
        textbox.text = line
        textbox.visibleChars = 0
    end
end

return VignetteSystem
