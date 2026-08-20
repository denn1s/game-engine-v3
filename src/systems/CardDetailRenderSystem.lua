-- Exact values live here, not in the procedural picture. The collection grid
-- should communicate a card's shape at a glance; this panel answers precisely.

local CardDetailRenderSystem = { name = "cardDetailRender" }

local COLORS = {
    cream = { 0.94, 0.89, 0.76 },
    ink = { 0.10, 0.11, 0.16 },
    int = { 0.20, 0.49, 0.86 },
    charm = { 0.88, 0.29, 0.34 },
    sense = { 0.24, 0.67, 0.42 },
}

local LABELS = { int = "INT", charm = "CHA", sense = "SEN" }
local titleFont, bodyFont, numberFont, smallFont

function CardDetailRenderSystem.setup(scene)
    titleFont = love.graphics.newFont(11)
    bodyFont = love.graphics.newFont(14)
    numberFont = love.graphics.newFont(20)
    smallFont = love.graphics.newFont(9)
end

function CardDetailRenderSystem.unload(scene)
    titleFont, bodyFont, numberFont, smallFont = nil, nil, nil, nil
end

function CardDetailRenderSystem.draw(scene)
    local registry = scene.registry
    local collection = registry:resource("runState").collection
    local view = registry:resource("collectionView")
    local card = collection[view.selected]

    if not card then
        love.graphics.setColor(COLORS.cream[1], COLORS.cream[2], COLORS.cream[3], 0.45)
        love.graphics.setFont(bodyFont)
        love.graphics.printf("No conversation notes yet.", 24, 170, 182, "center")
        return
    end

    love.graphics.setColor(COLORS[card.primary])
    love.graphics.setFont(titleFont)
    love.graphics.print(LABELS[card.primary] .. "-PRIMARY", 16, 69)

    love.graphics.setColor(COLORS.cream)
    love.graphics.setFont(bodyFont)
    love.graphics.printf(card.phrase, 16, 94, 198, "left")

    love.graphics.setFont(smallFont)
    love.graphics.setColor(COLORS.cream[1], COLORS.cream[2], COLORS.cream[3], 0.42)
    love.graphics.print("WHAT IS IN THIS NOTE", 16, 187)

    local stats = { "int", "charm", "sense" }
    for i, name in ipairs(stats) do
        local x = 16 + (i - 1) * 67
        love.graphics.setColor(COLORS[name])
        love.graphics.setFont(numberFont)
        love.graphics.print(('%02d'):format(card.stats[name]), x, 210)
        love.graphics.setFont(smallFont)
        love.graphics.print(LABELS[name], x + 1, 235)
    end

    love.graphics.setColor(COLORS.cream[1], COLORS.cream[2], COLORS.cream[3], 0.18)
    love.graphics.line(16, 262, 214, 262)
    love.graphics.setColor(COLORS.cream[1], COLORS.cream[2], COLORS.cream[3], 0.50)
    love.graphics.setFont(smallFont)
    love.graphics.printf(
        "The picture shows the shape.\nThe numbers settle the argument.",
        16, 278, 198, "left")
    love.graphics.setColor(1, 1, 1)
end

return CardDetailRenderSystem
