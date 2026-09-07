package.path = "./?.lua;" .. package.path

local AutoTile = require("src.world.AutoTile")
local TileGrid = require("src.world.TileGrid")

-- The bit layout, from the DIRS table: N=1, W=2, E=4, S=8. If a test
-- below disagrees with this line, the test is wrong or the DIRS changed
-- (in which case TILES must change too — they are one contract).

local function filled(cols, rows, painted)
    local grid = TileGrid.new(cols, rows)
    for _, cell in ipairs(painted) do
        grid:set(cell[1], cell[2], true)
    end
    return grid
end

-- A lone tile has no matching neighbor: mask 0, the "island" lookup.
local lone = filled(3, 3, { { 2, 2 } })
assert(AutoTile.maskAt(lone, 2, 2) == 0, "lone tile should have an empty mask")

-- Each single neighbor lights exactly its own bit, nothing else.
local nOnly = filled(3, 3, { { 2, 2 }, { 2, 1 } })
assert(AutoTile.maskAt(nOnly, 2, 2) == 1, "up neighbor must set bit 0")
local wOnly = filled(3, 3, { { 2, 2 }, { 1, 2 } })
assert(AutoTile.maskAt(wOnly, 2, 2) == 2, "left neighbor must set bit 1")
local eOnly = filled(3, 3, { { 2, 2 }, { 3, 2 } })
assert(AutoTile.maskAt(eOnly, 2, 2) == 4, "right neighbor must set bit 2")
local sOnly = filled(3, 3, { { 2, 2 }, { 2, 3 } })
assert(AutoTile.maskAt(sOnly, 2, 2) == 8, "down neighbor must set bit 3")

-- A fully surrounded interior tile lights all four bits: the plain
-- center tile. This is the single most-used case on a real map, which is
-- exactly why hand-authoring it 200 times is madness and autotiling isn't.
local block = filled(3, 3, {
    { 1, 1 }, { 2, 1 }, { 3, 1 },
    { 1, 2 }, { 2, 2 }, { 3, 2 },
    { 1, 3 }, { 2, 3 }, { 3, 3 },
})
assert(AutoTile.maskAt(block, 2, 2) == 15, "center of a block must be 15")

-- Out-of-bounds reads count as DIFFERENT, so a corner of the world
-- behaves like any other tile with two neighbors present: E + S = 12.
local cornerGrid = filled(2, 2, { { 1, 1 }, { 2, 1 }, { 1, 2 } })
assert(AutoTile.maskAt(cornerGrid, 1, 1) == 12, "map corner should read E+S = 12")

-- Every mask 0..15 maps to a real cell in the tileset: the table is
-- total. The pixel coordinates must be multiples of CELL so the quad
-- split is exact.
for mask = 0, 15 do
    local px = AutoTile.TILES[mask]
    assert(px, ("no table entry for mask %d"):format(mask))
    assert(px[1] % AutoTile.CELL == 0, ("mask %d x is not a whole cell"):format(mask))
    assert(px[2] % AutoTile.CELL == 0, ("mask %d y is not a whole cell"):format(mask))
end

-- An empty cell has no mask to speak of (and is never drawn).
local empty = TileGrid.new(3, 3)
assert(AutoTile.maskAt(empty, 2, 2) == 0, "empty cell must return an empty mask")

-- Two different terrains side by side do NOT count as neighbors: the
-- mask is per-type. This is what lets grass and path tile coexist.
local mixed = TileGrid.new(2, 1)
mixed:set(1, 1, "grass")
mixed:set(2, 1, "path")
assert(AutoTile.maskAt(mixed, 1, 1) == 0, "different terrain must not merge")

print("autotile tests passed -- neighbor in, pixel out, table total")
