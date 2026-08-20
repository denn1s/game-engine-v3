package.path = "./?.lua;" .. package.path

local CardArt = require("src.cards.CardArt")

local function seededRandom(seed)
    return function()
        seed = (1103515245 * seed + 12345) % 2147483648
        return seed / 2147483648
    end
end

local function describe(card)
    return CardArt.describe(card, seededRandom(CardArt.seed(card)))
end

local specialist = {
    primary = "int",
    stats = { int = 10, charm = 2, sense = 0 },
}
local sameValues = {
    primary = "int",
    stats = { int = 10, charm = 2, sense = 0 },
}
local hybrid = {
    primary = "charm",
    stats = { int = 4, charm = 10, sense = 8 },
}

local first = describe(specialist)
local replay = describe(sameValues)
assert(first.seed == replay.seed, "equal cards changed visual seed")
assert(#first.symbols == #replay.symbols, "equal cards changed symbol count")
for i, symbol in ipairs(first.symbols) do
    local other = replay.symbols[i]
    assert(symbol.stat == other.stat and symbol.size == other.size
        and symbol.x == other.x and symbol.y == other.y,
        "equal cards changed visual composition")
end

assert(#first.symbols == 2, "a zero-valued stat should leave no mark")
assert(first.symbols[1].stat == "int", "largest symbol was not drawn first")
assert(first.symbols[1].size > first.symbols[2].size,
    "symbol size stopped representing value")

local mixed = describe(hybrid)
assert(mixed.secondary == "sense", "wrong secondary stat tinted the card")
assert(mixed.influence > 0 and mixed.influence <= 0.45,
    "secondary color stole the primary identity")
for _, channel in ipairs(mixed.background) do
    assert(channel >= 0 and channel <= 1, "HSL conversion escaped RGB range")
end

local ok = pcall(describe, {
    primary = "int",
    stats = { int = 0, charm = 0, sense = 0 },
})
assert(not ok, "zero-total art should fail loudly")

print("card art tests passed -- same data, same picture")
