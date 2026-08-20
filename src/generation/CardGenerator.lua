-- Turns the player's training into a SPACE of possible cards, then samples
-- from it. Randomness never gets to break the promises made by the stats:
-- primary values stay between 50-100%, off-stats between 0-50%, and the
-- primary itself is weighted by the player's stat distribution (GDD section 6).

local phrases = require("src.data.card_phrases")
local rules = require("src.data.card_rules")

local CardGenerator = {}

CardGenerator.STATS = { "int", "charm", "sense" }

local function defaultRandom(...)
    return love.math.random(...)
end

-- Debug tools are intentionally allowed to put RunState into strange states.
-- Treat a negative stat as zero at this boundary, but never "repair" the input
-- table behind the inspector's back: the invalid value should remain visible.
local function effectiveStats(stats)
    assert(type(stats) == "table", "card generation needs a stats table")
    local effective = {}
    for _, name in ipairs(CardGenerator.STATS) do
        local value = stats[name]
        assert(type(value) == "number", name .. " must be a number")
        effective[name] = math.max(0, value)
    end
    return effective
end

function CardGenerator.weights(stats)
    local effective = effectiveStats(stats)
    local weights, total = {}, 0
    for _, name in ipairs(CardGenerator.STATS) do
        weights[name] = effective[name] ^ rules.weightPower
        total = total + weights[name]
    end
    return weights, total, effective
end

-- Imagine each stat as a strip of raffle tickets. A 20/5/10 build owns
-- 20 of the first 35 tickets, then 5, then 10. One roll lands on one strip.
local function weightedPrimary(weights, random, total)
    local target = random() * total
    local cumulative = 0
    for _, name in ipairs(CardGenerator.STATS) do
        cumulative = cumulative + weights[name]
        if target < cumulative then return name end
    end
    return CardGenerator.STATS[#CardGenerator.STATS] -- defensive: random() == 1
end

local function rollValue(hidden, isPrimary, random)
    local low, high
    if isPrimary then
        low, high = math.ceil(hidden * rules.primaryMin), math.floor(hidden)
    else
        low, high = 0, math.floor(hidden * rules.offStatMax)
    end
    if low == high then return low end
    return random(low, high)
end

function CardGenerator.card(stats, random)
    random = random or defaultRandom
    local weights, total, effective = CardGenerator.weights(stats)
    assert(total > 0, "cannot generate a card from zero total stats")
    local primary = weightedPrimary(weights, random, total)
    local values = {}

    for _, name in ipairs(CardGenerator.STATS) do
        values[name] = rollValue(effective[name], name == primary, random)
    end

    local pool = assert(phrases[primary], "missing phrase pool: " .. primary)
    return {
        primary = primary,
        phrase = pool[random(1, #pool)],
        stats = values,
    }
end

function CardGenerator.pack(stats, count, random)
    count = count or 5
    assert(count >= 0 and count == math.floor(count),
        "pack size must be a non-negative integer")
    local cards = {}
    for i = 1, count do
        cards[i] = CardGenerator.card(stats, random)
    end
    return cards
end

return CardGenerator
