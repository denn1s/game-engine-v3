-- The reusable drawing primitive for one card. A screen-level render system
-- decides WHICH cards go WHERE; this module only turns one card into pixels.

local CardArt = require("src.cards.CardArt")

local CardRenderer = {}

local COLORS = {
    border = { 0.075, 0.080, 0.115 },
    paper = { 0.955, 0.915, 0.805 },
    int = { 0.15, 0.43, 0.84 },
    charm = { 0.86, 0.19, 0.29 },
    sense = { 0.14, 0.61, 0.34 },
}

local function randomFor(card)
    local rng = love.math.newRandomGenerator(CardArt.seed(card))
    return function(...) return rng:random(...) end
end

local function drawSymbol(stat, centerX, centerY, size)
    if stat == "int" then
        love.graphics.rectangle("fill",
            centerX - size / 2, centerY - size / 2, size, size, 2, 2)
    elseif stat == "charm" then
        love.graphics.circle("fill", centerX, centerY, size / 2)
    elseif stat == "sense" then
        local radius = size * 0.58
        love.graphics.polygon("fill",
            centerX, centerY - radius,
            centerX - size / 2, centerY + radius / 2,
            centerX + size / 2, centerY + radius / 2)
    end
end

function CardRenderer.draw(card, x, y, width, height)
    local art = CardArt.describe(card, randomFor(card))
    local radius = math.max(2, math.floor(math.min(width, height) * 0.04))

    love.graphics.push("all")

    -- Thin dark edge: at grid size a shadow becomes blur, but an edge keeps the
    -- paper silhouette crisp against the collection shelf.
    love.graphics.setColor(COLORS.border)
    love.graphics.rectangle("fill", x, y, width, height, radius, radius)
    love.graphics.setColor(art.background)
    love.graphics.rectangle("fill", x + 2, y + 2, width - 4, height - 4,
        math.max(1, radius - 1), math.max(1, radius - 1))

    -- Keep the procedural marks inside the card. Each center is sampled only
    -- from the area where that entire symbol fits.
    love.graphics.setScissor(x + 2, y + 2, width - 4, height - 4)
    local inset = math.max(5, width * 0.07)
    for _, symbol in ipairs(art.symbols) do
        local size = symbol.size * math.min(width, height)
        local availableW = math.max(0, width - 2 * inset - size)
        local availableH = math.max(0, height - 2 * inset - size)
        local centerX = x + inset + size / 2 + symbol.x * availableW
        local centerY = y + inset + size / 2 + symbol.y * availableH

        local color = COLORS[symbol.stat]
        love.graphics.setColor(color[1], color[2], color[3], 0.78)
        drawSymbol(symbol.stat, centerX, centerY, size)
        love.graphics.setColor(COLORS.border[1], COLORS.border[2],
            COLORS.border[3], 0.28)
        love.graphics.setLineWidth(math.max(1, width / 96))

        -- A restrained outline makes overlapping shapes legible without
        -- turning the card into three disconnected icons.
        if symbol.stat == "int" then
            love.graphics.rectangle("line",
                centerX - size / 2, centerY - size / 2, size, size, 2, 2)
        elseif symbol.stat == "charm" then
            love.graphics.circle("line", centerX, centerY, size / 2)
        else
            local triangleRadius = size * 0.58
            love.graphics.polygon("line",
                centerX, centerY - triangleRadius,
                centerX - size / 2, centerY + triangleRadius / 2,
                centerX + size / 2, centerY + triangleRadius / 2)
        end
    end

    -- One quiet paper strip makes the result feel like a collected note while
    -- leaving the exact phrase and values to the adjacent detail panel.
    local stripH = math.max(10, height * 0.13)
    love.graphics.setColor(COLORS.paper[1], COLORS.paper[2], COLORS.paper[3], 0.82)
    love.graphics.rectangle("fill", x + 2, y + height - stripH - 2,
        width - 4, stripH)
    love.graphics.setColor(COLORS[card.primary])
    love.graphics.rectangle("fill", x + width * 0.12, y + height - stripH / 2 - 2,
        width * 0.76, math.max(2, height * 0.022))

    love.graphics.pop()
end

return CardRenderer
