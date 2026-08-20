-- A playable balancing instrument. It exposes the two random stages that
-- matter before dates exist: packs enter the collection, then hands sample
-- that accumulated history. Everything displayed is plain data.

local Scene = require("src.ecs.Scene")

local PackLabInputSystem = require("src.systems.PackLabInputSystem")
local StatTuningSystem = require("src.systems.StatTuningSystem")
local PackGenerationSystem = require("src.systems.PackGenerationSystem")
local HandGenerationSystem = require("src.systems.HandGenerationSystem")
local PackLabRenderSystem = require("src.systems.PackLabRenderSystem")

return function(payload)
    local scene = Scene.new("packLab")

    scene.registry:setResource("runState", {
        week = 1,
        day = 1,
        stats = { int = 1, charm = 1, sense = 1 },
        collection = {},
    })
    scene.registry:setResource("packLab", {
        selectedStat = 1,
        nextSeed = 1001,
        lastPack = {},
        hand = {},
        primaryCounts = { int = 0, charm = 0, sense = 0 },
        message = "Choose a history, generate packs, then ask whether they feel earned.",
    })

    -- Input announces intent; four atomic reactions follow; rendering only reads.
    scene:addSystem(PackLabInputSystem)
    scene:addSystem(StatTuningSystem)
    scene:addSystem(PackGenerationSystem)
    scene:addSystem(HandGenerationSystem)
    scene:addSystem(PackLabRenderSystem)

    return scene
end
