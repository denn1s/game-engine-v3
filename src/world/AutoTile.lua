-- Autotiling: a tile's ART decided by its NEIGHBORS, not by hand.
--
-- This is a deliberate, line-by-line port of last year's engine
-- (game-engine-v2, the Pong tilemap systems). The bit layout, the four
-- directions, and the mask -> tileset table are kept IDENTICAL, down to
-- the pixel coordinates, so the tileset you painted then still fits the
-- lookup now. That's the point worth naming out loud in class: a good
-- engine feature is DATA-shaped enough to survive the game that born it.
-- The farm map had 1900 tiles; this dating-sim town has maybe 100. The
-- algorithm didn't change by a single bit.
--
--   neighbor test  ->  a 4-bit mask (0..15)  ->  table  ->  sheet pixel
--
-- It touches no registry, no scene, no LÖVE — exactly like Movement and
-- CardArt before it — so tests/autotile.lua runs it under bare LuaJIT.

local AutoTile = {}

-- The tileset sheet is cut into cells this many pixels square. Last
-- year's Grass.png is 160x128 = 10x8 cells of 16px; the placeholder the
-- build tools generate uses the same geometry so the two are swappable.
AutoTile.CELL = 16

-- The four cardinal neighbors, checked in THIS order. The order IS the
-- bit layout, and it must agree with TILES below (and, unchanged, with
-- the dx[]/dy[] arrays in the old C++ systems). Same as v2: an
-- out-of-bounds neighbor is simply not counted, so a tile on the edge of
-- the map reads as an edge and draws its own border.
--
--   bit 0 (1)  = up    ( 0, -1)        bit 2 (4) = right (+1,  0)
--   bit 1 (2)  = left  (-1,  0)        bit 3 (8) = down  ( 0, +1)
--
-- So a mask is (N?1) + (W?2) + (E?4) + (S?8). Sixteen combinations:
-- every way a tile can touch (or not touch) the four around it.
AutoTile.DIRS = {
    { dx = 0, dy = -1, bit = 1, name = "N" },
    { dx = -1, dy = 0, bit = 2, name = "W" },
    { dx = 1, dy = 0,  bit = 4, name = "E" },
    { dx = 0, dy = 1,  bit = 8, name = "S" },
}

-- Compute the 0..15 mask for the tile at (x,y) in a grid.
--
-- `grid` is anything with a :get(x,y) that returns a terrain value and
-- nil for out-of-bounds — the lab's painted boolean set and the future
-- map's typed tiles both satisfy it, so ONE function autotiles either.
-- A neighbor counts toward the mask when it holds the SAME value as this
-- tile; a different tile or empty space or off-map does not. Each set
-- bit is added once and the four bits never collide, so plain + is
-- exactly a bitwise-or here (and stays readable on Lua 5.1, which has no
-- | operator).
function AutoTile.maskAt(grid, x, y)
    local here = grid:get(x, y)
    if here == nil then
        return 0 -- nothing here to tile
    end
    local mask = 0
    for _, dir in ipairs(AutoTile.DIRS) do
        if grid:get(x + dir.dx, y + dir.dy) == here then
            mask = mask + dir.bit
        end
    end
    return mask
end

-- The lookup table: mask -> the tileset PIXEL (x, y) of the cell to
-- draw. This is v2's `std::map<uint8_t, std::pair<int,int>> m`, ported
-- verbatim. Read a couple of entries to see the shape of the idea:
--
--   mask 15 = all four neighbors match  -> the plain interior tile (0,0)
--   mask 0  = no neighbor matches       -> a lone island (16,32)
--   mask 1  = only UP matches           -> the tile's top edge continues,
--                                           its bottom is a rounded hem
--
-- The other twelve are the remaining single edges, corners, and T's.
AutoTile.TILES = {
    [0]  = { 16, 32 },
    [1]  = {  0, 80 },
    [2]  = { 48, 96 },
    [3]  = { 48, 80 },
    [4]  = {  0, 96 },
    [5]  = { 16, 80 },
    [6]  = { 16, 96 },
    [7]  = { 32, 80 },
    [8]  = {  0, 32 },
    [9]  = {  0, 48 },
    [10] = { 48, 48 },
    [11] = { 48, 64 },
    [12] = { 16, 48 },
    [13] = { 16, 64 },
    [14] = { 32, 48 },
    [15] = {  0,  0 },
}

-- mask -> the 1-based (col, row) SpriteSheet:quad wants. The table
-- speaks in pixels (because the old tileset does); the sheet speaks in
-- cells; dividing by CELL reconciles them in exactly one place.
function AutoTile.quadCell(mask)
    local px = AutoTile.TILES[mask]
    return px[1] / AutoTile.CELL + 1, px[2] / AutoTile.CELL + 1
end

return AutoTile
