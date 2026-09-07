-- Spends the paint intent: mutates the grid, and ONLY the grid. This is
-- the world-change half of the input/paint split. Holding the left
-- button paints the hovered cell; the right button erases it. Because a
-- held button re-fires every frame, dragging paints a whole run of cells
-- -- the same "continuous state" idea that makes a held key walk.
--
-- The one thing it does NOT do is pick tile art. It only decides WHICH
-- cells are grass. What each grass cell LOOKS like is decided downstream
-- by autotiling, every frame, from the neighbors. That is why painting
-- one cell repaints its three neighbors too: they were never told to.

local TileLabPaintSystem = { name = "tileLabPaint" }

function TileLabPaintSystem.update(scene, dt)
    local registry = scene.registry
    local lab = registry:resource("tileLab")
    local _, tilemap = registry:first("tilemap")
    local grid = tilemap.grid

    if lab.clearRequested then
        grid:clear()
        lab.clearRequested = false
        return
    end

    if not lab.hovering then
        return
    end
    if lab.painting then
        grid:set(lab.hoverX, lab.hoverY, lab.terrain)
    elseif lab.erasing then
        grid:set(lab.hoverX, lab.hoverY, nil)
    end
end

return TileLabPaintSystem
