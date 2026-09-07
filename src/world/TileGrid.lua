-- A rectangular grid of terrain. The one piece of STATE the whole tile
-- system shares: the lab paints into it, autotiling reads out of it, and
-- the real map's collision (lesson 15) will test it for `solid`.
--
-- Deliberately dumb: a width, a height, and a flat array of cells. No
-- LÖVE, no registry — a plain data container, so it is trivially testable
-- and every consumer agrees on what a cell is.
--
-- Cell convention:
--   - x grows right, y grows DOWN (matching the sprite sheet and the
--     screen), 1-based so it reads naturally as "column 1, row 1".
--   - a cell is ANY terrain value (a string like "grass", a number,
--     `true` in the lab) or nil for empty. AutoTile compares cells by
--     equality, so the type is the identity — two cells "match" when
--     they hold the same thing.
--   - reading off the grid returns nil. AutoTile treats that as "no
--     neighbor", which makes the map boundary draw its own edge — the
--     same behavior last year's C++ got from its explicit bounds check.

local TileGrid = {}
TileGrid.__index = TileGrid

function TileGrid.new(width, height)
    return setmetatable({
        width = width,
        height = height,
        cells = {}, -- flat [y*width + x] store; nil == empty
    }, TileGrid)
end

function TileGrid:inBounds(x, y)
    return x >= 1 and x <= self.width and y >= 1 and y <= self.height
end

function TileGrid:get(x, y)
    if not self:inBounds(x, y) then
        return nil
    end
    return self.cells[(y - 1) * self.width + x]
end

function TileGrid:set(x, y, terrain)
    if not self:inBounds(x, y) then
        return
    end
    self.cells[(y - 1) * self.width + x] = terrain
end

function TileGrid:clear()
    self.cells = {}
end

-- Every (x, y, terrain) that is non-empty, in a stable row-major order.
-- Render systems use it to skip the empty air and touch only real tiles.
function TileGrid:each()
    local i = 0
    local total = self.width * self.height
    return function()
        while i < total do
            i = i + 1
            local x = (i - 1) % self.width + 1
            local y = math.floor((i - 1) / self.width) + 1
            local terrain = self.cells[i]
            if terrain ~= nil then
                return x, y, terrain
            end
        end
        return nil
    end
end

return TileGrid
