-- A tiny town authored as text. The characters are convenient for humans;
-- TileGrid is the representation the game systems consume.

local TileGrid = require("src.world.TileGrid")

local MapData = {}

local ROWS = {
    "....................",
    ".##################.",
    ".##################.",
    ".#####........#####.",
    ".#####........#####.",
    ".##################.",
    ".########..########.",
    ".########..########.",
    ".##################.",
    ".##################.",
    ".##################.",
    "....................",
}

local TERRAIN = {
    ["#"] = "grass",
    ["."] = false,
}

function MapData.build()
    local width = #ROWS[1]
    local grid = TileGrid.new(width, #ROWS)

    for y, row in ipairs(ROWS) do
        assert(#row == width, ("map row %d has the wrong width"):format(y))
        for x = 1, width do
            local glyph = row:sub(x, x)
            local terrain = TERRAIN[glyph]
            assert(terrain ~= nil, ("unknown map glyph %q at %d,%d"):format(glyph, x, y))
            if terrain then
                grid:set(x, y, terrain)
            end
        end
    end

    return grid
end

return MapData
