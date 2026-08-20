package.path = "./?.lua;" .. package.path

local CardGenerator = require("src.generation.CardGenerator")
local HandGenerator = require("src.generation.HandGenerator")
local rules = require("src.data.card_rules")

-- Tiny deterministic RNG for tests: reproducible without opening a LÖVE window.
local function seededRandom(seed)
    return function(low, high)
        seed = (1103515245 * seed + 12345) % 2147483648
        local unit = seed / 2147483648
        if low == nil then return unit end
        if high == nil then return math.floor(unit * low) + 1 end
        return low + math.floor(unit * (high - low + 1))
    end
end

local function assertCardBounds(card, hidden)
    for _, name in ipairs(CardGenerator.STATS) do
        local value = card.stats[name]
        assert(value >= 0 and value <= hidden[name], name .. " escaped its ceiling")
        if name == card.primary then
            assert(value >= math.ceil(hidden[name] * rules.primaryMin),
                name .. " missed its primary floor")
        else
            assert(value <= math.floor(hidden[name] * rules.offStatMax),
                name .. " escaped its off-stat ceiling")
        end
    end
end

local hidden = { int = 20, charm = 5, sense = 10 }
local random = seededRandom(3096)
local counts = { int = 0, charm = 0, sense = 0 }
local sampleSize = 10000

for _ = 1, sampleSize do
    local card = CardGenerator.card(hidden, random)
    assertCardBounds(card, hidden)
    counts[card.primary] = counts[card.primary] + 1
end

local weights, total = CardGenerator.weights(hidden)
for _, name in ipairs(CardGenerator.STATS) do
    local observed = counts[name] / sampleSize
    local expected = weights[name] / total
    assert(math.abs(observed - expected) < 0.02,
        ("%s distribution drifted: %.3f vs %.3f"):format(
            name, observed, expected))
end

local collection = {}
for i = 1, 12 do collection[i] = { id = i } end
local hand = HandGenerator.draw(collection, 5, seededRandom(96))
local seen = {}
for _, card in ipairs(hand) do
    assert(not seen[card.id], "a hand drew the same card twice")
    seen[card.id] = true
end
assert(#collection == 12, "drawing a hand mutated the collection")

-- The debug inspector may temporarily push a stat below zero. Generation and
-- weight display clamp it at their boundary without hiding the bad source data.
local debugStats = { int = -12, charm = 4, sense = -2 }
local safeWeights, safeTotal = CardGenerator.weights(debugStats)
assert(safeWeights.int == 0 and safeWeights.charm == 4
    and safeWeights.sense == 0 and safeTotal == 4,
    "negative debug stats were not treated as zero")
local safeCard = CardGenerator.card(debugStats, seededRandom(5))
assert(safeCard.primary == "charm" and safeCard.stats.int == 0
    and safeCard.stats.sense == 0,
    "a negative debug stat leaked into a generated card")
assert(debugStats.int == -12 and debugStats.sense == -2,
    "generation silently mutated the inspected RunState")

local ok = pcall(CardGenerator.card,
    { int = 0, charm = 0, sense = 0 }, seededRandom(1))
assert(not ok, "zero-total stats should fail loudly")

print(("generation tests passed -- I:%d C:%d S:%d"):format(
    counts.int, counts.charm, counts.sense))
