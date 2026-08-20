-- Converts card data into a deterministic visual recipe. This module draws
-- nothing and calls no global random function, so its design rules can be
-- tested from the command line without opening LÖVE.

local CardArt = {}

CardArt.STATS = { "int", "charm", "sense" }

-- Hues are the familiar stat colors. Saturation and lightness stay fixed when
-- the background moves from the primary toward the strongest off-stat: hue is
-- the information, not murky RGB arithmetic.
local HUES = {
    int = 218 / 360,
    charm = 354 / 360,
    sense = 142 / 360,
}

local PRIMARY_INDEX = { int = 1, charm = 2, sense = 3 }

local function clamp(value, low, high)
    return math.max(low, math.min(value, high))
end

function CardArt.hsl(hue, saturation, lightness)
    hue = hue % 1
    saturation = clamp(saturation, 0, 1)
    lightness = clamp(lightness, 0, 1)

    local chroma = (1 - math.abs(2 * lightness - 1)) * saturation
    local sector = hue * 6
    local x = chroma * (1 - math.abs(sector % 2 - 1))
    local red, green, blue

    if sector < 1 then
        red, green, blue = chroma, x, 0
    elseif sector < 2 then
        red, green, blue = x, chroma, 0
    elseif sector < 3 then
        red, green, blue = 0, chroma, x
    elseif sector < 4 then
        red, green, blue = 0, x, chroma
    elseif sector < 5 then
        red, green, blue = x, 0, chroma
    else
        red, green, blue = chroma, 0, x
    end

    local match = lightness - chroma / 2
    return { red + match, green + match, blue + match }
end

-- Hue is circular: red at 354 degrees is close to blue through violet, not by
-- taking the long trip through yellow and green.
local function mixHue(from, to, amount)
    local shortest = (to - from + 0.5) % 1 - 0.5
    return (from + shortest * amount) % 1
end

-- The visual seed belongs to the card's values, not to the frame or the global
-- gameplay RNG. Equal cards therefore keep their composition after a reload.
function CardArt.seed(card)
    local stats = assert(card.stats, "card art needs card.stats")
    local primary = assert(PRIMARY_INDEX[card.primary], "unknown primary stat")
    return (stats.int * 73856093
        + stats.charm * 19349663
        + stats.sense * 83492791
        + primary * 26544357) % 2147483646 + 1
end

local function rankedStats(card)
    local ranked = {}
    for order, name in ipairs(CardArt.STATS) do
        local value = assert(card.stats[name], "missing card stat: " .. name)
        assert(value >= 0, "card art cannot represent a negative stat")
        ranked[#ranked + 1] = { name = name, value = value, order = order }
    end
    table.sort(ranked, function(a, b)
        if a.value == b.value then return a.order < b.order end
        return a.value > b.value
    end)
    return ranked
end

-- `random` is injected. In the game it comes from a local RandomGenerator;
-- tests supply a tiny deterministic replacement.
function CardArt.describe(card, random)
    assert(type(random) == "function", "card art needs a local random function")
    local ranked = rankedStats(card)
    local maximum = ranked[1].value
    assert(maximum > 0, "cannot draw a card with zero total stats")

    local secondary
    for _, entry in ipairs(ranked) do
        if entry.name ~= card.primary then
            secondary = entry
            break
        end
    end

    local primaryValue = card.stats[card.primary]
    local pairTotal = primaryValue + secondary.value
    -- The secondary can tint nearly half the distance, but never steals the
    -- primary's color identity. This is a design constant, not a game rule.
    local influence = pairTotal > 0
        and math.min(secondary.value / pairTotal, 0.45) or 0
    local hue = mixHue(HUES[card.primary], HUES[secondary.name], influence)

    local symbols = {}
    for _, entry in ipairs(ranked) do
        if entry.value > 0 then
            local proportion = entry.value / maximum
            -- Area, not diameter, represents value; hence the square root.
            -- A small floor keeps a non-zero off-stat legible at card size.
            local size = math.max(0.15, 0.46 * math.sqrt(proportion))
            symbols[#symbols + 1] = {
                stat = entry.name,
                value = entry.value,
                size = size,
                x = random(),
                y = random(),
            }
        end
    end

    return {
        seed = CardArt.seed(card),
        background = CardArt.hsl(hue, 0.48, 0.72),
        secondary = secondary.name,
        influence = influence,
        symbols = symbols, -- largest first; smaller marks remain visible on top
    }
end

return CardArt
