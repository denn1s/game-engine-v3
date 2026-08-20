-- Owns the lab's stat controls. Presets make repeatable classroom comparisons;
-- fine adjustments let the class tune the design instead of only observing it.

local CardGenerator = require("src.generation.CardGenerator")

local StatTuningSystem = { name = "statTuning" }

local PRESETS = {
    [1] = { int = 1, charm = 1, sense = 1 },   -- first Monday
    [2] = { int = 6, charm = 1, sense = 1 },   -- studied all week
    [3] = { int = 20, charm = 5, sense = 10 }, -- a mature specialist
}

local function copyStats(target, source)
    for _, name in ipairs(CardGenerator.STATS) do target[name] = source[name] end
end

function StatTuningSystem.update(scene, dt)
    local registry = scene.registry
    local lab = registry:resource("packLab")
    local stats = registry:resource("runState").stats

    for _, request in registry:each("statSelectionRequested") do
        lab.selectedStat = (lab.selectedStat - 1 + request.direction)
            % #CardGenerator.STATS + 1
    end

    for _, request in registry:each("statAdjustmentRequested") do
        local name = CardGenerator.STATS[lab.selectedStat]
        stats[name] = math.max(0, math.min(99, stats[name] + request.amount))
        lab.message = ("Tuned %s to %d. New packs use the new weights.")
            :format(name, stats[name])
    end

    for _, request in registry:each("statPresetRequested") do
        copyStats(stats, PRESETS[request.preset])
        lab.message = ({
            "Preset 1: first Monday -- no specialization yet.",
            "Preset 2: studied all week -- will the pack remember?",
            "Preset 3: 20 / 5 / 10 -- a weighted-generation stress test.",
        })[request.preset]
    end
end

return StatTuningSystem
