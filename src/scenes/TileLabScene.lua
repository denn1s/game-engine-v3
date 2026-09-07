-- The Tile Lab: a place to SEE autotiling work, before the map needs it.
--
-- Last year autotiling was taught inside a 50x38 farm map: the algorithm
-- was correct but the MAP was the lesson's homework, not its microscope.
-- This lab inverts that. The whole screen is one question — "why does a
-- tile change when its neighbor changes?" — and you answer it by PAINTING:
-- click and drag cells into grass, watch their art re-decide itself live as
-- neighbors appear and vanish, and read the mask behind any cell in the
-- table on the right.
--
-- It is built from the same pieces the real map will use, wired the same
-- way, and it teaches the lesson-13 movement split all over again:
--
--   TileLabInputSystem     mouse held + position   -> hover + paint intent
--   TileLabPaintSystem     intent                  -> mutates the TileGrid
--   TileLabRenderSystem    TileGrid + AutoTile     -> the blob, re-tiled
--   TileLabTableSystem     (a mask, the sheet)     -> the 16-cell reference
--
-- Input only fills the resource; paint is the only thing that changes the
-- world; render only reads. That discipline is why a cell repaints the
-- moment you let go: nothing caches a tile, every frame re-derives the mask
-- from the neighbors. Autotiling is a PERSISTENT relationship, not a one-
-- time bake — and the lab makes that obvious by breaking it if you try to
-- bake (see the "why not cache" note in the README).

local Scene = require("src.ecs.Scene")
local TileGrid = require("src.world.TileGrid")

local SHEET = "assets/grass_tiles.png"

local TileLabInputSystem = require("src.systems.TileLabInputSystem")
local TileLabPaintSystem = require("src.systems.TileLabPaintSystem")
local TileLabRenderSystem = require("src.systems.TileLabRenderSystem")
local TileLabTableSystem = require("src.systems.TileLabTableSystem")

-- one terrain for now. A string, so equality IS type identity and two
-- cells "match" exactly when they hold the same thing (AutoTile.maskAt's
-- whole idea). The real map will add "path", "wall"... and reuse this.
local GRASS = "grass"

return function(payload)
    local scene = Scene.new("tileLab")

    -- The grid, as ONE entity's component. Not an entity per cell: the
    -- whole point of a tilemap is that a tile is a POSITION, not an
    -- object. Geometry (ox/oy/cell) rides with it so every system reads
    -- the same layout.
    --
    -- It starts EMPTY on purpose. The lesson is build-up, not a demo blob:
    -- click one cell and it has no neighbors (mask 0, the island); add one
    -- beside it and watch *both* their art change as a single bit flips on.
    -- The teacher narrates the mask from nothing, cell by cell. C clears
    -- back to this state mid-class.
    local cols, rows, cell = 14, 7, 32
    local grid = TileGrid.new(cols, rows)
    scene.registry:spawn({
        tilemap = {
            grid = grid, cols = cols, rows = rows, cell = cell,
            ox = 14, oy = 48,
        },
    })

    -- Live interaction state, written by input, read by the others. Kept
    -- a resource (not a component): there is exactly one cursor and it is
    -- not "a thing in the world."
    scene.registry:setResource("tileLab", {
        terrain = GRASS,
        hoverX = 0, hoverY = 0, hovering = false,
        clearRequested = false,
    })

    scene:addSystem(TileLabInputSystem)
    scene:addSystem(TileLabPaintSystem)
    scene:addSystem(TileLabRenderSystem)
    scene:addSystem(TileLabTableSystem)

    return scene
end
