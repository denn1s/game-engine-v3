# Teacher Guide — World Map Tiles and Autotiling

> Instructor-facing cheat sheet for the live-coding class. This is not a
> student handout. It assumes the previous class ended with the current
> `MapScene`: a character can move around a blank 640×400 screen.

## Class outcome

By the end of class, the blank map screen should contain a small tile-based
place. Students should be able to explain this pipeline:

```text
map characters → terrain grid → neighbor mask (0–15) → tileset quad → pixels
```

The game only needs a small, single-screen town where the player will later
choose one of three date locations. Do not build scrolling, a map editor,
collision, doors, or scene transitions today. Those obscure the lesson's one
new idea: **a tile's appearance can be derived from its neighbors**.

Assumed class length: **90 minutes**. Assumed autotiling rule: **four cardinal
neighbors**, giving 16 possible masks.

## What to prepare before class

### Required files

- A 160×128 PNG tileset at `assets/grass_tiles.png`.
- Sixteen usable 16×16 grass variants placed at the coordinates in the
  `AutoTile.TILES` lookup table below.
- A working copy of the previous movement lesson.
- The completed reference repository open on branch `14-Tiles`:
  `/home/dennis/Dev/UVG/gea/game-engine-v3`.
- A backup commit or patch containing the finished lesson.

The prepared repository already includes
`tools/make_tile_sheet.py`. From its root, generate the placeholder asset with:

```bash
python3 tools/make_tile_sheet.py
```

The generated sheet deliberately looks simple but clearly exposes edges. It is
better for teaching than a visually busy RPG tileset. If you draw your own,
keep nearest-neighbor filtering, transparency around boundary pieces, and the
exact 16×16 cell size.

### Prepare, but do not live-code

Copy these finished scaffold files from the reference repository before class,
or have them ready in a patch students can apply:

- `src/world/TileGrid.lua`
- `src/world/AutoTile.lua`
- `tests/autotile.lua`
- `assets/grass_tiles.png`

The reference repository also contains a full interactive `TileLabScene`.
Use that as the opening demonstration if desired, but do not type its mouse
input and diagnostic HUD live. The lab is a microscope for the concept, not
the game feature students need to build.

### Five-minute rehearsal

1. Run the current classroom project and verify movement still works.
2. Run the reference tile lab with `love .` from the prepared repository.
3. Paint one isolated cell, then one cell above it, then a 3×3 block.
4. Verify `luajit tests/autotile.lua` passes.
5. Keep the tileset PNG open in an image viewer so students can see that the
   code selects small rectangles from one image.

## The board before opening the editor

Write this first:

```text
N = 1     W = 2     E = 4     S = 8

mask = matching north + matching west + matching east + matching south
```

Four neighbors are four yes/no questions. Four bits describe `2⁴ = 16`
combinations. The number is not a mysterious tile ID; it is a compact answer
to “which adjacent cells contain the same terrain?”

Example:

```text
    grass
      │
grass X grass       N + W + E = 1 + 2 + 4 = mask 7

    empty
```

Then say: “The grid stores **what the world is**. Autotiling decides **how that
world looks**. Those are separate jobs.”

## Run of class

### 0–10 min — Show the problem

Run the current map. Ask what makes the moving character feel as if it is
floating. A flat background has no readable boundary, path, or place.

Show the prepared tile lab:

- Paint one tile: no matching neighbors, so mask 0.
- Paint immediately above it: the lower tile gains N=1; the upper tile gains
  S=8. Both pictures change even though only one new cell was painted.
- Fill a 3×3 square: its center becomes mask 15, the seamless interior tile.

Key sentence: **we store terrain, not corners**. Corner/edge/interior art is a
consequence of the terrain around a cell.

### 10–25 min — Read the pure grid

Open the prepared `TileGrid.lua`. Do not dwell on every method. Point out:

- Coordinates are 1-based and `y` grows downward, like the screen.
- Cells live in one flat table: `(y - 1) * width + x`.
- An out-of-bounds read returns `nil`.
- The whole map is one component/data structure, not one ECS entity per tile.

Ask: “Does a patch of grass need an identity?” No. A future door does: one
door leads to the library and another to a café. Tiles are positions; doors
can later be entities.

Useful explanation for the flat index:

```text
2D coordinate (x, y) → one array slot
index = (y - 1) * width + x
```

### 25–45 min — Read and test the mask

Open `AutoTile.lua`. Focus on `DIRS` and `maskAt`; treat the lookup coordinates
as authored art data.

The core function should remain this small:

```lua
function AutoTile.maskAt(grid, x, y)
    local here = grid:get(x, y)
    if here == nil then return 0 end

    local mask = 0
    for _, dir in ipairs(AutoTile.DIRS) do
        if grid:get(x + dir.dx, y + dir.dy) == here then
            mask = mask + dir.bit
        end
    end
    return mask
end
```

Why addition works: every direction owns a different power of two, so no bit
can be added twice. In LuaJIT/Lua 5.1 this is also more readable than adding a
bit library for four flags.

Run:

```bash
luajit tests/autotile.lua
```

Read only three tests aloud:

- isolated tile → 0;
- center of a filled 3×3 block → 15;
- different terrain beside it → still 0.

The third test matters later: grass connects to grass, while grass next to a
path must draw an edge.

### 45–60 min — Live-code readable map data

Create `src/game/data/map.lua`. Keep the map small enough to read as a picture.
The dots are empty space for now; next class can reinterpret terrain for
collision and add doors.

```lua
local TileGrid = require("src.world.TileGrid")

local MapData = {}

local ROWS = {
    "....................",
    "..################..",
    "..################..",
    "..####......######..",
    "..####......######..",
    "..################..",
    "..######....######..",
    "..######....######..",
    "..################..",
    "..################..",
    "....................",
    "....................",
}

function MapData.build()
    local width = #ROWS[1]
    local grid = TileGrid.new(width, #ROWS)

    for y, row in ipairs(ROWS) do
        assert(#row == width, "map rows must have equal width")
        for x = 1, width do
            local glyph = row:sub(x, x)
            assert(glyph == "#" or glyph == ".", "unknown map glyph")
            if glyph == "#" then
                grid:set(x, y, "grass")
            end
        end
    end

    return grid
end

return MapData
```

Teaching beats:

- The ASCII rows are authoring format; `TileGrid` is runtime format.
- Parsing once keeps rendering independent of how the map was written.
- Validation turns a typo into an immediate useful error.
- Do not hand-author visual tile IDs. Store semantic terrain (`"grass"`).

The example is 20×12 cells at 32 pixels each: exactly 640×384, leaving a
16-pixel strip if a HUD is wanted. Change the pattern before class if you want
three visually obvious future destinations, but keep the dimensions.

### 60–78 min — Live-code the render system

Create `src/game/systems/TilemapRenderSystem.lua`:

```lua
local AutoTile = require("src.world.AutoTile")
local ImageManager = require("src.graphics.ImageManager")

local TilemapRenderSystem = { name = "tilemapRender" }

local PATH = "assets/grass_tiles.png"
local SOURCE_CELL = 16
local DRAW_CELL = 32

function TilemapRenderSystem.draw(scene)
    love.graphics.clear(0.07, 0.08, 0.11)

    local _, tilemap = scene.registry:first("tilemap")
    local sheet = ImageManager.sheet(PATH, SOURCE_CELL, SOURCE_CELL)
    local scale = DRAW_CELL / SOURCE_CELL

    love.graphics.setColor(1, 1, 1)
    for x, y in tilemap.grid:each() do
        local mask = AutoTile.maskAt(tilemap.grid, x, y)
        local col, row = AutoTile.quadCell(mask)
        love.graphics.draw(
            sheet.image,
            sheet:quad(col, row),
            (x - 1) * DRAW_CELL,
            (y - 1) * DRAW_CELL,
            0, scale, scale
        )
    end
end

return TilemapRenderSystem
```

Narrate the loop as four verbs: **iterate → inspect neighbors → select quad →
draw**.

Important LÖVE trap: call `love.graphics.setColor(1, 1, 1)` before drawing.
Images are multiplied by the current drawing color, so a previous colored
rectangle can make the sheet look unexpectedly dark.

### 78–85 min — Wire it into `MapScene`

At the top of `src/game/scenes/MapScene.lua`, add:

```lua
local MapData = require("src.game.data.map")
local TilemapRenderSystem = require("src.game.systems.TilemapRenderSystem")
```

After creating the scene, spawn one entity containing the grid:

```lua
scene.registry:spawn({
    tilemap = { grid = MapData.build(), cell = 32 }
})
```

Add the tile renderer **before** `SpriteRenderSystem`:

```lua
scene:addSystem(TilemapRenderSystem)
scene:addSystem(SpriteRenderSystem)
```

Do not modify `MovementSystem`. The character still moves because movement
does not care what is drawn beneath it. System order controls paint order:
tiles first, sprite second.

Run the game. If the player begins over empty space, either move its starting
position or change the ASCII map; do not add collision as a hurried fix.

### 85–90 min — Recap and exit ticket

Ask students to answer before leaving:

1. A grass tile has grass north, east, and south, but not west. What mask does
   it produce? (`1 + 4 + 8 = 13`.)
2. What does the grid store, and what does autotiling derive?
3. Why did `MovementSystem` not need to change?

Preview next class: terrain will gain consequences. Collision will ask the
grid whether a destination is walkable, and three trigger entities/doors will
launch the dates at the library and two other locations.

## Finished architecture

```text
src/game/data/map.lua
        │ parses readable rows
        ▼
TileGrid ── get(x,y) / each()
        │
        ▼
AutoTile.maskAt() ── 0..15 ── AutoTile.quadCell()
        │
        ▼
TilemapRenderSystem ── draw below character
        │
        ▼
SpriteRenderSystem ── unchanged
```

## Debugging during the live code

| Symptom | Check first |
|---|---|
| Tiles are blurry | `image:setFilter("nearest", "nearest")` in `ImageManager` |
| Tiles are dark/colored | Reset draw color to white before `love.graphics.draw` |
| Wrong edge/corner appears | `DIRS` bit order and `TILES` lookup must agree |
| Every tile looks isolated | Neighbor cells must contain the same terrain value |
| A one-cell offset appears | Grid is 1-based; screen pixels use `(x - 1)` and `(y - 1)` |
| Sprite disappears | Register `TilemapRenderSystem` before `SpriteRenderSystem` |
| Sheet quad assertion fails | Sheet dimensions and source cell size must divide evenly |
| Map crashes while loading | Check equal row widths and unknown glyph assertion |

## Scope guards

If time runs short, preserve the mask explanation and the final rendered map.
Skip extra map shapes and tests. Do not sacrifice the conceptual split between
terrain and rendering.

If time runs long, let students add a second terrain type and observe that it
does not connect to grass. Do not expand to diagonal/47-tile autotiling in
class; eight neighbors create 256 raw masks and turn a clean introduction into
a tileset taxonomy lesson.

Avoid today:

- camera scrolling;
- Tiled/LDtk import;
- multiple visual layers and Y-sorting;
- cached neighbor masks and invalidation;
- collision and location triggers;
- one ECS entity per tile.

## After-class notes to record

- Which mask example caused confusion?
- Did students understand terrain values before the lookup table?
- How long did the ASCII-map parse take to type?
- Did the prepared tileset make all four boundaries visually obvious?
- Should collision and location triggers fit in one follow-up class or two?

