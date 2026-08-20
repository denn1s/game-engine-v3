-- A deliberately plain analysis surface, not the final card art. These look
-- like index cards pinned to a school club's probability board: enough visual
-- identity to compare outcomes, with no procedural-art ideas stolen from the
-- next lesson.

local CardGenerator = require("src.generation.CardGenerator")
local Screen = require("src.Screen")

local PackLabRenderSystem = { name = "packLabRender" }

local COLORS = {
    int = { 0.20, 0.49, 0.86 },
    charm = { 0.88, 0.29, 0.34 },
    sense = { 0.24, 0.67, 0.42 },
}
local LABELS = { int = "INT", charm = "CHA", sense = "SEN" }
local PAPER = { 0.94, 0.90, 0.78 }
local INK = { 0.10, 0.11, 0.16 }

local titleFont, bodyFont, smallFont, cardFont

function PackLabRenderSystem.setup(scene)
    titleFont = love.graphics.newFont(19)
    bodyFont = love.graphics.newFont(12)
    smallFont = love.graphics.newFont(10)
    cardFont = love.graphics.newFont(11)
end

function PackLabRenderSystem.unload(scene)
    titleFont, bodyFont, smallFont, cardFont = nil, nil, nil, nil
end

local function drawStatControls(stats, selected)
    local weights, total = CardGenerator.weights(stats)
    for i, name in ipairs(CardGenerator.STATS) do
        local x = 12 + (i - 1) * 126
        local color = COLORS[name]
        love.graphics.setColor(color[1], color[2], color[3], 0.22)
        love.graphics.rectangle("fill", x, 37, 116, 27, 3, 3)
        love.graphics.setColor(color)
        love.graphics.setLineWidth(i == selected and 2 or 1)
        love.graphics.rectangle("line", x, 37, 116, 27, 3, 3)
        love.graphics.setFont(bodyFont)
        love.graphics.printf(("%s %d"):format(LABELS[name], stats[name]),
            x + 6, 42, 58, "left")
        love.graphics.setFont(smallFont)
        local percent = total > 0 and weights[name] / total * 100 or 0
        love.graphics.printf(("%2.0f%%"):format(percent), x + 65, 44, 43, "right")
    end
    love.graphics.setLineWidth(1)
end

local function drawCard(card, x, y, index)
    love.graphics.setColor(PAPER)
    love.graphics.rectangle("fill", x, y, 116, 112, 3, 3)
    love.graphics.setColor(0, 0, 0, 0.28)
    love.graphics.rectangle("line", x, y, 116, 112, 3, 3)

    local color = COLORS[card.primary]
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, 116, 22, 3, 3)
    love.graphics.rectangle("fill", x, y + 18, 116, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(smallFont)
    love.graphics.print(("%d  %s"):format(index, LABELS[card.primary]), x + 6, y + 5)

    love.graphics.setColor(INK)
    love.graphics.setFont(cardFont)
    love.graphics.printf(card.phrase, x + 7, y + 29, 102, "left")
    love.graphics.setFont(smallFont)
    local stats = card.stats
    love.graphics.printf(("I %02d   C %02d   S %02d"):format(
        stats.int, stats.charm, stats.sense), x + 6, y + 92, 104, "center")
end

local function drawRow(cards, y, emptyText)
    if #cards == 0 then
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.setFont(bodyFont)
        love.graphics.printf(emptyText, 12, y + 45, 616, "center")
        return
    end
    for i, card in ipairs(cards) do
        drawCard(card, 12 + (i - 1) * 124, y, i)
    end
end

function PackLabRenderSystem.draw(scene)
    local registry = scene.registry
    local runState = registry:resource("runState")
    local lab = registry:resource("packLab")

    love.graphics.clear(0.055, 0.065, 0.105, 1)
    love.graphics.setColor(0.92, 0.89, 0.78)
    love.graphics.setFont(titleFont)
    love.graphics.print("PACK LAB", 12, 8)
    love.graphics.setFont(smallFont)
    love.graphics.setColor(1, 1, 1, 0.58)
    love.graphics.printf("1 first day   2 study week   3 specialist",
        285, 13, 343, "right")

    drawStatControls(runState.stats, lab.selectedStat)

    love.graphics.setColor(1, 1, 1, 0.72)
    love.graphics.setFont(bodyFont)
    love.graphics.print("LATEST PACK  [P]", 12, 70)
    love.graphics.setFont(smallFont)
    love.graphics.printf(("seed %s  |  collection %d"):format(
        lab.lastPackSeed or "--", #runState.collection), 360, 73, 268, "right")
    drawRow(lab.lastPack, 88, "Press P to generate five bounded, weighted cards.")

    love.graphics.setColor(1, 1, 1, 0.72)
    love.graphics.setFont(bodyFont)
    love.graphics.print("RANDOM HAND  [H]", 12, 207)
    love.graphics.setFont(smallFont)
    love.graphics.printf(("seed %s  |  sampled without replacement"):format(
        lab.handSeed or "--"), 340, 210, 288, "right")
    drawRow(lab.hand, 225, "Generate packs, then press H to test what play actually sees.")

    love.graphics.setColor(0.12, 0.14, 0.21, 1)
    love.graphics.rectangle("fill", 0, 350, Screen.w, 50)
    love.graphics.setColor(0.92, 0.89, 0.78)
    love.graphics.setFont(smallFont)
    love.graphics.printf(lab.message, 12, 355, 616, "left")
    love.graphics.setColor(1, 1, 1, 0.48)
    love.graphics.printf("Arrows tune stats   P new pack   R replay seed   H hand   C clear",
        12, 378, 616, "left")
    love.graphics.setColor(1, 1, 1)
end

return PackLabRenderSystem
