-- The quiet frame around the collection: title, divider, page count and help.
-- Cards and their details belong to separate render systems.

local Screen = require("src.Screen")

local CollectionChromeRenderSystem = { name = "collectionChromeRender" }

local COLORS = {
    desk = { 0.055, 0.071, 0.115 },
    shelf = { 0.086, 0.110, 0.164 },
    cream = { 0.94, 0.89, 0.76 },
    faint = { 0.94, 0.89, 0.76, 0.42 },
}

local titleFont, smallFont

function CollectionChromeRenderSystem.setup(scene)
    titleFont = love.graphics.newFont(19)
    smallFont = love.graphics.newFont(10)
end

function CollectionChromeRenderSystem.unload(scene)
    titleFont, smallFont = nil, nil
end

function CollectionChromeRenderSystem.draw(scene)
    local view = scene.registry:resource("collectionView")
    local collection = scene.registry:resource("runState").collection
    local pageCount = math.max(1, math.ceil(#collection / view.pageSize))

    love.graphics.clear(COLORS.desk)
    love.graphics.setColor(COLORS.shelf)
    love.graphics.rectangle("fill", 230, 0, Screen.w - 230, Screen.h)

    love.graphics.setColor(COLORS.cream)
    love.graphics.setFont(titleFont)
    love.graphics.print("CONVERSATION NOTES", 14, 11)

    love.graphics.setFont(smallFont)
    love.graphics.setColor(COLORS.faint)
    love.graphics.print("the things you might say", 15, 34)
    love.graphics.printf(("%02d CARDS"):format(#collection),
        493, 17, 132, "right")

    love.graphics.setColor(COLORS.cream[1], COLORS.cream[2], COLORS.cream[3], 0.18)
    love.graphics.line(14, 53, 216, 53)
    love.graphics.line(230, 53, 626, 53)

    love.graphics.setColor(COLORS.faint)
    love.graphics.printf(("PAGE %d / %d"):format(view.page, pageCount),
        476, 371, 150, "right")
    love.graphics.print("ARROWS browse    HOME / END jump", 244, 371)
    love.graphics.setColor(1, 1, 1)
end

return CollectionChromeRenderSystem
