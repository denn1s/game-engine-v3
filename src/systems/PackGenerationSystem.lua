-- Reacts to one request by generating one pack and adding its cards to the
-- persistent collection. A local seeded RNG makes every surprising result
-- reproducible without storing an unserializable RandomGenerator in RunState.

local CardGenerator = require("src.generation.CardGenerator")
local rules = require("src.data.card_rules")

local PackGenerationSystem = { name = "packGeneration" }

local function primarySummary(counts)
    local total = counts.int + counts.charm + counts.sense
    if total == 0 then return "no samples yet" end
    return ("seen I:%d%% C:%d%% S:%d%%"):format(
        counts.int / total * 100 + 0.5,
        counts.charm / total * 100 + 0.5,
        counts.sense / total * 100 + 0.5)
end

local function printCards(label, seed, cards)
    print(("\n%s (seed %d)"):format(label, seed))
    for i, card in ipairs(cards) do
        local s = card.stats
        print(("  %d. %-5s  I:%d C:%d S:%d  %s"):format(
            i, card.primary, s.int, s.charm, s.sense, card.phrase))
    end
end

function PackGenerationSystem.update(scene, dt)
    local registry = scene.registry
    local lab = registry:resource("packLab")
    local runState = registry:resource("runState")

    for _ in registry:each("collectionClearRequested") do
        runState.collection = {}
        lab.lastPack, lab.hand = {}, {}
        lab.primaryCounts = { int = 0, charm = 0, sense = 0 }
        lab.message = "Collection cleared. Generate a new history with P."
    end

    local function generate(seed, addToCollection)
        local rng = love.math.newRandomGenerator(seed)
        local ok, pack = pcall(CardGenerator.pack,
            runState.stats, rules.packSize,
            function(...) return rng:random(...) end)

        if ok then
            lab.lastPack, lab.lastPackSeed = pack, seed
            if addToCollection then
                lab.nextSeed = seed + 1
                for _, card in ipairs(pack) do
                    runState.collection[#runState.collection + 1] = card
                    lab.primaryCounts[card.primary] =
                        lab.primaryCounts[card.primary] + 1
                end
                lab.message = ("Pack %d added. %s. Does that feel earned?")
                    :format(seed, primarySummary(lab.primaryCounts))
            else
                lab.message = ("Replayed seed %d. Same inputs, same pack.")
                    :format(seed)
            end
            printCards(addToCollection and "PACK" or "REPLAY", seed, pack)
        else
            lab.message = "Cannot generate: " .. tostring(pack)
        end
    end

    for _ in registry:each("packRequested") do
        generate(lab.nextSeed, true)
    end

    for _ in registry:each("packReplayRequested") do
        if lab.lastPackSeed then
            generate(lab.lastPackSeed, false)
        else
            lab.message = "Nothing to replay. Generate a pack with P first."
        end
    end
end

return PackGenerationSystem
