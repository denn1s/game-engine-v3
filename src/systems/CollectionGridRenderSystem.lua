-- The deliberately boring lesson scaffold: lays out a page of cards and marks
-- the cursor. Lesson 11 replaces drawPlaceholder with the shared card renderer.

local CollectionGridRenderSystem = { name = "collectionGridRender" }

local CARD_W, CARD_H = 86, 116
local GAP_X, GAP_Y = 10, 14
local GRID_X, GRID_Y = 244, 68

local COLORS = {
    paper = { 0.91, 0.87, 0.75 },
    ink = { 0.10, 0.11, 0.16 },
    cursor = { 1.00, 0.82, 0.35 },
}

local statColors = {
    int = { 0.20, 0.49, 0.86 },
    charm = { 0.88, 0.29, 0.34 },
    sense = { 0.24, 0.67, 0.42 },
}

local smallFont

function CollectionGridRenderSystem.setup(scene)
    smallFont = love.graphics.newFont(9)
end

function CollectionGridRenderSystem.unload(scene)
    smallFont = nil
end

local function drawPlaceholder(card, x, y)
    love.graphics.setColor(COLORS.paper)
    love.graphics.rectangle("fill", x, y, CARD_W, CARD_H, 3, 3)
    love.graphics.setColor(statColors[card.primary])
    love.graphics.rectangle("fill", x, y, CARD_W, 24, 3, 3)
    love.graphics.rectangle("fill", x, y + 20, CARD_W, 4)
    love.graphics.setColor(COLORS.ink)
    love.graphics.setFont(smallFont)
    love.graphics.printf(card.phrase, x + 7, y + 32, CARD_W - 14, "left")
    local stats = card.stats
    love.graphics.printf(("I%d  C%d  S%d"):format(
        stats.int, stats.charm, stats.sense),
        x + 4, y + CARD_H - 17, CARD_W - 8, "center")
end

function CollectionGridRenderSystem.draw(scene)
    local registry = scene.registry
    local collection = registry:resource("runState").collection
    local view = registry:resource("collectionView")
    local first = (view.page - 1) * view.pageSize + 1
    local last = math.min(first + view.pageSize - 1, #collection)

    for index = first, last do
        local slot = index - first
        local column = slot % view.columns
        local row = math.floor(slot / view.columns)
        local x = GRID_X + column * (CARD_W + GAP_X)
        local y = GRID_Y + row * (CARD_H + GAP_Y)

        drawPlaceholder(collection[index], x, y)

        if index == view.selected then
            love.graphics.setColor(COLORS.cursor)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x - 3, y - 3,
                CARD_W + 6, CARD_H + 6, 5, 5)
            love.graphics.setLineWidth(1)
        end
    end
    love.graphics.setColor(1, 1, 1)
end

return CollectionGridRenderSystem
