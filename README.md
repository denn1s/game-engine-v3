# Lesson 14 — The map, part 2: tiles & autotiling

The three-class map, again:

| Lesson | The question | Adds a system that… |
|---|---|---|
| 13 | what makes a thing move? | turns held keys into position + facing + animation |
| **14 (today)** | what makes a place? | draws a tile grid (with autotiling) under the feet |
| 15 | what makes a wall and a door? | pushes back on solid tiles, launches a date |

Yesterday the map was a flat rectangle and a sprite. Today the rectangle
becomes a **place**: a grid of tiles, whose art re-decides itself from their
neighbors — autotiling — so painting one tile repaints three.

Autotiling is not new to you. Last year (the C++/Raylib engine) it lived
inside a 50×38 farm map, and the map was bigger than the lesson. Today we
build the **same algorithm** on a tiny dating-sim town, first in a lab where
you can watch a single mask, then under the player's feet. That contrast is
the point: the bit layout, the four directions, and the lookup table are a
**line-for-line port** of last year's `m` map — same pixels, same order, so
the tileset painted then still fits the code now. An engine feature that
outlives the game it was born in is the whole Phase-3 argument for building
an engine at all.

## Run it

```bash
love .                # the lab (this lesson's microscope) — the default
love . map            # the walkable map from lesson 13
luajit tests/autotile.lua
```

In the **lab**: **left-drag paints** grass, **right-drag erases**, **C**
clears. It **starts empty** — that is the teaching order: click one cell and
it has no neighbors (`mask 0`, the island); add a neighbor and watch *both*
their art change as one bit flips. Hover any tile to read it on the right:
**the mask spelled out as four binary squares** (`S·8 E·4 W·2 N·1`, MSB on the
left, a lit box is a matching neighbor), the same four bits as an additive
breakdown, and the tileset cell that number picks from — the whole lookup, all
16, boxed to the one you're on.

`main.lua` opens on `tileLab` for this lesson and boots any registered scene
by name (`love . map`), so the labs are directly openable without the debug
switcher; `--debug` may appear anywhere in the args. This is a small tooling
addition, not lesson content — do not spend class time on it.

## Instructor preparation

The **lab and the two pure modules are the scaffold**: hand them out (they're
already on this branch) or type them ahead. Live-coding the whole lab plus the
map integration will not fit ninety minutes, and the lab is a microscope, not
the subject. **Live-code the back half: `MapData` and wiring autotiling into
the real `MapScene`.** Do not type the lab's HUD (`TileLabTableSystem`) — it
is readout plumbing, the same call you made about `MapHudRenderSystem`
last class.

Regenerate the placeholder sheet with `python3 tools/make_tile_sheet.py`. To
use **last year's tileset instead**, drop that `Grass.png` in over
`assets/grass_tiles.png` — the geometry and every cell coordinate are
identical, so it is a pure art upgrade with zero code changes. The old farm
map and this town can share one tileset; show the room the file, it lands.

## Learning goals

By the end, students should be able to explain:

- a tilemap is two ideas — **a grid of terrain** and **a rendering
  convention** — and only the second one is autotiling;
- how four yes/no neighbors become **one integer** (`N·1 + W·2 + E·4 + S·8`),
  and why a 16-row table is then the entire "which sprite?" decision — no
  `if`-ladder about edges and corners;
- why a tile's look is a **relationship** to its neighbors: change one cell
  and its three touching neighbors change too, because nothing about them was
  baked in;
- why the map keeps **one component holding a dense grid**, not one entity
  per tile — last year's `TileComponent` struct per cell was a farm-map
  choice, not a rule of ECS;
- the recurring shape again: `TileGrid` + `AutoTile` are pure and
  window-less, so `tests/autotile.lua` runs them under bare LuaJIT while the
  systems around them cannot be tested without one.

## The lab, read as a machine

Open `love .` and drive it before you explain it. The field **starts empty**,
and that is the lesson's order of operations. The whole screen answers one
question — *why does a tile change when its neighbor does?*

```text
  [ 14x7 field, empty ]          MASK TABLE  (all 16 blob cells, boxed to current)
  drag LMB -> paint grass         HOVER   mask in binary
  drag RMB -> erase                 [0] [0] [0] [1]  = 1
    C      -> clear                 S·8  E·4 W·2 N·1     <- exactly one box lit
                                    mask = 1               = the neighbour I added
                                      N same +1            <- the same bit, as a sum
                                      W ---- +0
                                      E ---- +0            binary row + additive list
                                      S ---- +0            are one fact, two notations
                                      1 = 1
```

**Click one cell.** It has no matching neighbor: `0000`, `mask 0`, the lone
island art, the table boxed on cell 0. **Now click the cell above it** — watch
the `N·1` box light to `0001`, the number become 1, and *both* tiles' art
change (the lower one gained a north edge, the upper one gained a south edge,
the seam between them melts away). You touched one cell and two repainted: the
mask is recomputed every frame from the grid, so a tile never *stores* a
shape, it *derives* one. Keep building a 2×2 block and drag the cursor slowly
across its interior — the `HOVER` boxes flick one at a time as each neighbor
test flips.

Two deliberate choices to name in the lab, then revisit in the map:

- **Input polls the mouse** (`isDown`), not `mousepressed` events — holding to
  paint is *continuous state*, the exact same distinction as held keys last
  class. Same rule, new organ.
- **Render recomputes every mask every frame.** At 98 cells this costs nothing
  and it is *correct*: a cell repaints the instant you let go, with no cache
  to invalidate. The one place the "compute once" optimization would bite is
  here, and we choose not to need it.

## The 90-minute class

### 0–10 min — The floor is a lie

Run `love .`. A character on a flat rectangle. Ask: *what makes it not yet a
place?* Answer: a place has ground with **edges** — grass that stops, corners
that round off. Hand-drawing every boundary tile in a 640×384 map is the
drudgery autotiling deletes. Then open the lab (quit, `love .`): it is **empty**.
Click one tile — a lone island; click beside it — both change; keep going and a
blob emerges with its seams dissolving by themselves. Say the promise: *today we
learn why, then we put that under the player.*

### 10–35 min — Four neighbors into one number

Don't open an editor yet; put the mask on the board. A tile touches the map on
four sides; each is a yes/no. Four yes/no's = 16 states. Then assign a bit to
each side and add the yesses — which is *exactly* the four binary squares the
`HOVER` panel draws, `S·8 E·4 W·2 N·1`, MSB on the left so the row spells the
number, and the same four bits again as the additive list beneath them:

```text
N=1  W=2  E=4  S=8        mask = (N?1) + (W?2) + (E?4) + (S?8)   # 0..15
                          [S] [E] [W] [N]   <- one box per bit, lit = matching
```

Now click a cell in the lab and point at its row: `0001` *is* "only north
matches," and the number 1 *is* the sum `0+0+0+1`. Binary and addition, one
fact, two notations — a good place to remind them the machine only ever sees
the bits.

Open `AutoTile.maskAt`: four `grid:get` comparisons, `+ dir.bit` when they
match. Point out that `+` *is* bitwise-or here because the bits never collide,
and that this is Lua 5.1, which has no `|` — an honest constraint, not a
shortcut. Then `AutoTile.TILES`: the 16 masks as an **address book** into the
tileset, `mask -> pixel (x,y)`, ported verbatim from v2. Read three rows aloud:
15 is the plain interior, 0 is a lone island, 1 is "only the top continues, so
round the bottom." Every tile on screen is one of these sixteen, picked by a
number.

Run the test. `luajit tests/autotile.lua` — a lone tile is mask 0, a block
center is 15, a world corner behaves like any two-neighbor tile, the table is
total (all 16 present, on whole-cell boundaries), and **different terrains
never merge** (that line is the seed of tomorrow's grass-vs-path).

### 35–55 min — `MapData`: the map you can read

The farm map's data was a 50-row grid of numbers nobody could hold in their
head. Ours is a town, so it fits as **ASCII art** — write a
`TileGrid.fromRows(rows, terrainOf)` (or a `MapData` module, same idea) that
turns a table you can *see* into a grid:

```lua
local TOWN = {
    "############",
    "#..........#",
    "#..####....#",
    "#..#..#....#",
    "#..........#",
    "############",
}
local TERRAIN = { ["#"] = "grass", ["."] = nil }   -- '.' is void
```

Make `fromRows` **validate** — equal row lengths, and every glyph known — the
way `Movement`'s tests do: a world that is a *pure parse* is a world you can
test. The lab never needed this (it paints by hand), which is exactly why it
wasn't in the scaffold — you add it now because the map is the first thing
that wants a *data* world instead of a toy one. The same `AutoTile.maskAt`
reads the *typed* grid, so grass merges with grass, and the `nil` void gives
the boundary its edge for free (an off-map read is `nil`, `nil ~= "grass"`, so
border tiles tile themselves).

### 55–75 min — Put the floor under the feet

Add the tiles to `MapScene` **without deleting movement at all**. One new
draw-only system, `TilemapRenderSystem`, added *before* `SpriteRenderSystem`
in the list — reuse the whole lab's draw loop verbatim (iterate the grid,
mask, quad, blit), reading the scene's `MapData` grid instead of the painted
one. Then retire `MapBackgroundSystem`, whose header comment literally
announced this replacement. Walk the character across grass and void: it moves
exactly as before, on a real place. **That the character code didn't change**
is the reward for lesson 13 keeping movement independent of what it stands on
— say so, out loud, because it is why we kept the systems atomic.

Tour the system order once more: floor tiles → sprite → HUD, three
single-question systems, draw-only ones safely interleaved with update-only
ones because `Scene` runs `update` and `draw` as two passes.

### 75–85 min — The one component, not two thousand

Stop on `TileGrid`. Last year each tile was a `TileComponent` in a vector,
fine for a farm, absurd for 98 cells drawn identically every frame. Here the
whole map is **one component on one entity** holding a dense grid. The ECS
motto from week 1, applied to layout: an entity is a thing with identity; a
map cell is a **position**, and there is nothing to identify. When students
ask "but where do the doors live" — that's the point: doors *do* want
identity (each is a different place), so tomorrow a door is an **entity**,
while the floor it sits on stays a grid.

### 85–90 min — Exit ticket (Discord)

1. A grass tile has grass above, left and right but void below. What is its
   mask, and would its three grass neighbors change if you painted the cell
   below it? Why?
2. Name the two ideas a tilemap separates. Which one is autotiling?
3. The character walked on a flat rectangle last class and on tiles today,
   but `MovementSystem` didn't change. What single design decision bought
   that?

## Architecture underneath the tiles

```text
MapData (pure: rows -> TileGrid, glyph -> terrain)  -- or the lab's painted grid
        |
        v
  TileGrid:get(x,y) -> terrain | nil        <- nil off-map = "no neighbor"
        |
        v
  AutoTile.maskAt(grid,x,y) -> 0..15        (pure)  <- the four-bit sum
  AutoTile.TILES[mask] -> {px,py}           (pure)  <- the address book
  AutoTile.quadCell(mask) -> sheet (col,row)
        |
        v
  TilemapRenderSystem / TileLabRenderSystem
     for each cell: mask -> quad -> blit under the sprite
        |
        v
  SpriteRenderSystem   (unchanged from lesson 13 — the payoff)
```

Left of the fold are **today's pure code** (`MapData`, `AutoTile`, `TileGrid`,
all testable without a window); the two render systems are today's glue; the
sprite box at the bottom is yesterday's, reused untouched.

## Deliberate limitations

- **One layer, one draw.** No ground-over-object Z-sorting, no walk-behind
  trees. A tiny town doesn't need it; a real RPG's map pipeline does, and that
  is a future lesson, not today's hole.
- **No collision, still the wrap.** The character walks off grass onto void
  and off the map. That is *tomorrow's* entire subject — `TileGrid` already
  stores terrain so a `solid` flag is one table away — and today resisted
  bolting it on so autotiling stays the only new idea.
- **Recomputed every frame.** Correct and free at this size. The moment the
  map is big enough to care, cache masks per cell and *invalidate on edit* —
  the classic tilemap footgun, and a reason to have understood the live
  version first.
- **One terrain in the lab, two in `TOWN`.** Grass and void. The "different
  terrain never merges" test is the whole reason adding "path" tomorrow is
  data, not code.

## Homework — the other four bits

Today's mask is four bits because a tile touches **four** neighbors. Add the
four diagonals and it's eight bits, 256 combinations, and the *47-cell* blob
sheet the fancy tilesets ship with. This is not today's lesson, and the reason
is a scoping lesson in itself: last year's game needed it (50×38 organic farm
blobs), this town does not (three yards and a path — the pinwheel corner
artifacts at 4-way read as style, not bugs).

The payoff of doing it as homework rather than code: because `AutoTile` is
pure and the systems read `maskAt -> TILES`, an 8-neighbor tilemap is **the
same systems with a bigger table** — no new code path, exactly the
"engine feature as data, not code" line we keep landing on. Wire a fifth
`{name="NE", dx=1, dy=-1, bit=16}` into `DIRS`, extend `TILES` to 256 rows,
point it at a 47-cell sheet. If you want the shape first: in the lab, hover a
cell and imagine four more `HOVER` lines — that's all that changes.

## Next class

Lesson 15 gives the tiles consequences. A `solid` flag on the terrain table,
a `CollisionSystem` that reads `TileGrid` under the player's feet and refuses
the move instead of wrapping the world, and three **door tiles** — the first
things on this map that want to be *entities* with identity rather than
positions in a grid, because walking into the café should launch the café,
not the cinema. Autotiling, promoted and reused; movement, finally interrupted.
