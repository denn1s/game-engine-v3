-- Draws the map's terrain grid below the character. The grid only says
-- "grass"; AutoTile turns each cell's four neighbor relationships into the
-- tileset quad that makes its edges join correctly.

local AutoTile = require("src.world.AutoTile")
local Screen = require("src.Screen")
local ImageManager = require("src.graphics.ImageManager")

local TilemapRenderSystem = { name = "tilemapRender" }

local SHEET = "assets/grass_tiles.png"
local SOURCE_CELL = AutoTile.CELL
local void = { 0.07, 0.08, 0.11 }

function TilemapRenderSystem.draw(scene)
    love.graphics.setColor(void)
    love.graphics.rectangle("fill", 0, 0, Screen.w, Screen.h)

    local _, tilemap = scene.registry:first("tilemap")
    local grid = tilemap.grid
    local sheet = ImageManager.sheet(SHEET, SOURCE_CELL, SOURCE_CELL)
    local scale = tilemap.cell / SOURCE_CELL

    -- LÖVE multiplies images by the current color. White preserves the
    -- tileset's authored colors after drawing the dark background.
    love.graphics.setColor(1, 1, 1)
    for x, y in grid:each() do
        local mask = AutoTile.maskAt(grid, x, y)
        local col, row = AutoTile.quadCell(mask)
        love.graphics.draw(
            sheet.image,
            sheet:quad(col, row),
            tilemap.ox + (x - 1) * tilemap.cell,
            tilemap.oy + (y - 1) * tilemap.cell,
            0, scale, scale
        )
    end
end

return TilemapRenderSystem
