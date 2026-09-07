-- The reference panel: the two readouts that turn "the grass re-tiles
-- itself, neat" into a lesson a student can actually READ.
--
--   1. THE MASK TABLE. All 16 blob cells, laid out by mask number and
--      drawn from the same sheet the grid uses. The row the hovered tile
--      currently falls on is boxed. This is AutoTile.TILES made visible:
--      the whole lookup, so "which of the 16 is my tile?" is answerable
--      by eye. The four corners of the table are the pure cases -- 0
--      island, 15 full interior -- and the twelve between them are the
--      edges, corners and T's the class will name.
--   2. THE NEIGHBORHOOD ZOOM. The hovered cell blown up with its four
--      neighbors, and beside it the mask spelled out: which bits are set
--      (N/W/E/S ticks), and the number as 4 binary digits. Watch the
--      bottom bit flick as you drag the cursor across a horizontal seam
--      -- that is autotiling, unmasked.
--
-- Pure presentation: reads the grid, AutoTile, and the resource; writes
-- nothing. Drawn last so it sits over the field. Same spirit as
-- MapHudRenderSystem -- a decision you can draw is a decision you can
-- reason about.

local Screen = require("src.Screen")
local AutoTile = require("src.world.AutoTile")
local ImageManager = require("src.graphics.ImageManager")

local TileLabTableSystem = { name = "tileLabTable" }

local SHEET = "assets/grass_tiles.png"
local CELL = AutoTile.CELL
local cream = { 0.94, 0.89, 0.76 }
local faint = { 0.94, 0.89, 0.76, 0.4 }
local box = { 0.31, 0.83, 0.55 }      -- highlighted mask row / lit neighbor
local dim = { 0.35, 0.38, 0.45 }      -- unlit neighbor tick
local void = { 0.07, 0.08, 0.11 }     -- matches the field's empty cell

local smallFont, bigFont, bitFont

function TileLabTableSystem.setup(scene)
    smallFont = love.graphics.newFont(9)
    bigFont = love.graphics.newFont(12)
    bitFont = love.graphics.newFont(20)
end

function TileLabTableSystem.unload(scene)
    smallFont, bigFont, bitFont = nil, nil, nil
end

-- The four bits ordered most-significant (value 8) to least (value 1), so
-- a row of them left-to-right reads as the binary of the mask number.
-- Each carries the direction it encodes -- the map between "a bit" and
-- "a neighbor" -- S=8, E=4, W=2, N=1 (the weights in AutoTile.DIRS).
local BITS = {
    { bit = 8, name = "S" },
    { bit = 4, name = "E" },
    { bit = 2, name = "W" },
    { bit = 1, name = "N" },
}

local function bitOn(mask, bit)
    return math.floor(mask / bit) % 2 == 1
end

-- Draw one tileset cell (given a sheet already cut to CELL) at a spot.
-- White first, always: the current color would otherwise tint the art.
local function drawTile(sheet, mask, x, y, scale)
    local col, row = AutoTile.quadCell(mask)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(sheet.image, sheet:quad(col, row), x, y, 0, scale, scale)
end

function TileLabTableSystem.draw(scene)
    local registry = scene.registry
    local lab = registry:resource("tileLab")
    local _, tilemap = registry:first("tilemap")
    local grid = tilemap.grid
    local sheet = ImageManager.sheet(SHEET, CELL, CELL)

    -- Which mask is the cursor on right now (drives both highlights).
    local hoverMask = nil
    if lab.hovering and grid:get(lab.hoverX, lab.hoverY) then
        hoverMask = AutoTile.maskAt(grid, lab.hoverX, lab.hoverY)
    end

    -- Cursor box on the field itself (drawn here, last, so it is on top
    -- of the tiles it points at). This is the thing connecting the grid
    -- on the left to the numbers on the right: they describe THIS cell.
    if lab.hovering then
        local cx = tilemap.ox + (lab.hoverX - 1) * tilemap.cell
        local cy = tilemap.oy + (lab.hoverY - 1) * tilemap.cell
        love.graphics.setColor(cream)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", cx + 1, cy + 1,
            tilemap.cell - 2, tilemap.cell - 2)
        love.graphics.setLineWidth(1)
    end

    -- Panel geometry: to the right of the grid, within Screen bounds.
    local panelX = tilemap.ox + tilemap.cols * tilemap.cell + 14
    local scale = 2

    love.graphics.setFont(smallFont)
    love.graphics.setColor(cream)
    love.graphics.print("MASK TABLE", panelX, 16)

    -- (1) the 4x4 of all sixteen blob cells, ordered by mask value.
    for mask = 0, 15 do
        local mx = mask % 4
        local my = math.floor(mask / 4)
        local x = panelX + mx * CELL * scale
        local y = 30 + my * CELL * scale
        -- void chip behind, then the art (transparency reads as the same
        -- dark empty the field uses, not a lighter box)
        love.graphics.setColor(void)
        love.graphics.rectangle("fill", x, y, CELL * scale, CELL * scale)
        drawTile(sheet, mask, x, y, scale)
        if mask == hoverMask then
            love.graphics.setColor(box)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, CELL * scale, CELL * scale)
            love.graphics.setLineWidth(1)
        end
    end

    -- (2) the hovered tile spelled out below the table.
    local readY = 30 + 4 * CELL * scale + 10
    love.graphics.setColor(cream)
    love.graphics.setFont(smallFont)
    love.graphics.print("HOVER", panelX, readY)
    if not hoverMask then
        love.graphics.setColor(faint)
        love.graphics.print("paint a cell…", panelX, readY + 14)
        love.graphics.print("LMB paint   RMB erase   C clear", 14, Screen.h - 16)
        return
    end

    -- (2a) THE MASK AS BINARY — the little squares. One box per bit, most
    --      significant on the LEFT, so the row literally spells the mask
    --      in base 2. Each box carries its neighbour's letter and value
    --      (N=1 … S=8); a 1 is lit, a 0 is dark. One isolated cell is
    --      0000; add a neighbour and exactly one box flips — that box IS
    --      the neighbour you added, this is the whole lesson made visible.
    local by = readY + 14
    love.graphics.setColor(cream)
    love.graphics.print("mask in binary", panelX, by)
    local sq, gap = 28, 6
    local stripY = by + 14
    for i, b in ipairs(BITS) do
        local on = bitOn(hoverMask, b.bit)
        local x = panelX + (i - 1) * (sq + gap)
        love.graphics.setColor(on and box or dim)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, stripY, sq, sq)
        love.graphics.setLineWidth(1)
        -- the digit, centered in its box
        love.graphics.setFont(bitFont)
        love.graphics.setColor(on and box or faint)
        local glyph = on and "1" or "0"
        love.graphics.print(glyph, x + (sq - bitFont:getWidth(glyph)) / 2,
            stripY + (sq - 20) / 2)
        -- who this bit is, under its box
        love.graphics.setFont(smallFont)
        love.graphics.setColor(cream)
        love.graphics.print(("%s·%d"):format(b.name, b.bit), x + 5, stripY + sq + 2)
    end
    -- the row reads as a number
    love.graphics.setFont(bigFont)
    love.graphics.setColor(cream)
    love.graphics.print(("= %d"):format(hoverMask),
        panelX + 4 * (sq + gap) + 2, stripY + 7)

    -- (2b) big art of the hovered mask, then its ADDITIVE breakdown — the
    --      same four bits spelled as a sum, so the row above (binary) and
    --      this list (arithmetic) tie together: each lit box is one +value.
    local artY = stripY + sq + 24
    local big = 4
    drawTile(sheet, hoverMask, panelX, artY, big)
    local bx = panelX + CELL * big + 10

    love.graphics.setFont(bigFont)
    love.graphics.setColor(cream)
    love.graphics.print(("mask = %d"):format(hoverMask), bx, artY)

    love.graphics.setFont(smallFont)
    local total = 0
    for i, dir in ipairs(AutoTile.DIRS) do
        local on = bitOn(hoverMask, dir.bit)
        if on then total = total + dir.bit end
        love.graphics.setColor(on and box or dim)
        love.graphics.print(("%s  %s   %+d"):format(
            dir.name, on and "same" or "----", on and dir.bit or 0),
            bx, artY + 18 + (i - 1) * 12)
    end
    love.graphics.setColor(cream)
    love.graphics.print(("%d = %d"):format(hoverMask, total), bx, artY + 18 + 4 * 12)

    -- footer
    love.graphics.setFont(smallFont)
    love.graphics.setColor(faint)
    love.graphics.print("LMB paint   RMB erase   C clear", 14, Screen.h - 16)
end

return TileLabTableSystem
