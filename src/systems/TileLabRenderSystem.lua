-- Draws the painted grid as AUTOTILED grass. For each non-empty cell it
-- asks AutoTile for a mask from the current neighbors, turns that mask
-- into a sheet cell, and blits exactly the piece of the tileset that
-- corresponds to how this tile touches its surroundings.
--
-- This is where the lesson's thesis becomes pixels: there is no branch
-- here for "if edge then ... else corner then ...". There is a lookup.
-- One table, one number, and every grass tile on screen resolves to the
-- right of 16 art pieces without a single conditional about shape.
--
-- It also proves the "persistent relationship, not a bake" claim from
-- the scene comment: it recomputes every mask every frame from the grid
-- the paint system just changed, so a cell repaints the instant its
-- neighbor appears. A naive "compute once and store" design would have
-- to invalidate on every edit; deriving is both simpler and always
-- correct at this map size.

local AutoTile = require("src.world.AutoTile")
local Screen = require("src.Screen")
local ImageManager = require("src.graphics.ImageManager")

local TileLabRenderSystem = { name = "tileLabRender" }

local SHEET = "assets/grass_tiles.png"
local CELL = AutoTile.CELL

local void = { 0.07, 0.08, 0.11 }
local cellEdge = { 0.16, 0.18, 0.24 }
local white = { 1, 1, 1 }

function TileLabRenderSystem.draw(scene)
    love.graphics.setColor(void)
    love.graphics.rectangle("fill", 0, 0, Screen.w, Screen.h)

    local _, tilemap = scene.registry:first("tilemap")
    local grid = tilemap.grid
    local cell, ox, oy = tilemap.cell, tilemap.ox, tilemap.oy
    local fieldW, fieldH = tilemap.cols * cell, tilemap.rows * cell

    -- The paintable field, framed and ruled, so empty cells read as
    -- "somewhere to paint" rather than dead space.
    love.graphics.setColor(cellEdge)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", ox - 1, oy - 1, fieldW + 2, fieldH + 2)
    love.graphics.setLineWidth(1)
    for x = 0, tilemap.cols do
        love.graphics.line(ox + x * cell, oy, ox + x * cell, oy + fieldH)
    end
    for y = 0, tilemap.rows do
        love.graphics.line(ox, oy + y * cell, ox + fieldW, oy + y * cell)
    end

    local scale = cell / CELL
    local sheet = ImageManager.sheet(SHEET, CELL, CELL)

    -- reset to white: LÖVE tints sprites by the CURRENT color, so drawing
    -- tiles after a colored rectangle would darken them (a classic
    -- "why is my art gray" trap worth naming in class).
    love.graphics.setColor(white)
    for x, y in grid:each() do
        local mask = AutoTile.maskAt(grid, x, y)
        local col, row = AutoTile.quadCell(mask)
        love.graphics.draw(sheet.image, sheet:quad(col, row),
            ox + (x - 1) * cell, oy + (y - 1) * cell, 0, scale, scale)
    end
end

return TileLabRenderSystem
