-- Bumps the hidden stat an activity trains. Note how little it knows:
-- not what a vignette is, not what's on screen — it reads the same
-- `activityPicked` event the vignette does and touches only RunState.
--
-- The stats are HIDDEN by design (GDD §5): nothing in the game renders
-- them yet. Watch them move in the debug inspector — the radar
-- triangle that shows the player their SHAPE is a later lesson.

local activities = require("src.data.activities")

local StatsSystem = { name = "stats" }

function StatsSystem.update(scene, dt)
    for _, pick in scene.registry:each("activityPicked") do
        local runState = scene.registry:resource("runState")
        local stat = activities[pick.option].stat
        runState.stats[stat] = runState.stats[stat] + 1
    end
end

return StatsSystem
