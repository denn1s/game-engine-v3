-- Samples the cards the player would actually have to make decisions with.
-- Pack quality and hand quality are different questions once old cards dilute
-- the collection, so this owns a separate request and a separate result.

local HandGenerator = require("src.generation.HandGenerator")
local rules = require("src.data.card_rules")

local HandGenerationSystem = { name = "handGeneration" }

function HandGenerationSystem.update(scene, dt)
    local registry = scene.registry
    local lab = registry:resource("packLab")
    local collection = registry:resource("runState").collection

    for _ in registry:each("handRequested") do
        if #collection < rules.handSize then
            lab.message = "The collection needs five cards. Press P first."
        else
            local seed = lab.nextSeed
            local rng = love.math.newRandomGenerator(seed)
            lab.hand = HandGenerator.draw(collection, rules.handSize,
                function(...) return rng:random(...) end)
            lab.handSeed = seed
            lab.nextSeed = seed + 1
            local counts = { int = 0, charm = 0, sense = 0 }
            for _, card in ipairs(lab.hand) do
                counts[card.primary] = counts[card.primary] + 1
            end
            lab.message = ("Hand %d: I%d C%d S%d -- pre-luck for the next decision.")
                :format(seed, counts.int, counts.charm, counts.sense)

            print(("\nHAND (seed %d, collection %d)"):format(seed, #collection))
            for i, card in ipairs(lab.hand) do
                local s = card.stats
                print(("  %d. %-5s  I:%d C:%d S:%d  %s"):format(
                    i, card.primary, s.int, s.charm, s.sense, card.phrase))
            end
        end
    end
end

return HandGenerationSystem
