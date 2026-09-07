#!/usr/bin/env python3
# Regenerates assets/grass_tiles.png: the 16 autotile blob cells the mask
# table in src/world/AutoTile.lua points at, as placeholder art with the
# EXACT geometry of last year's Grass.png (160x128, 16px cells, same cell
# per mask) -- so dropping the old sheet in over this file is a pure art
# upgrade that changes zero code.
#
# The drawing rule IS the autotile idea, on purpose: students who can't
# yet tell a corner from a T can SEE that a tile with fewer matching
# neighbors has more empty space. Every cell starts as full grass; each
# edge WITHOUT a match gets a transparent band carved off it and a dark
# rim on the cut. Mask 15 (all four match) is therefore one plain
# seamless square; mask 0 is a floating block.
#
# The mask -> pixel table is imported from the game module itself (via
# luajit) rather than duplicated here: the tool draws exactly what the
# code will look up, and the two cannot drift apart.
import subprocess
from PIL import Image, ImageColor

S = 16
W, H = 160, 128
TRANSPARENT = (0, 0, 0, 0)
FILL = ImageColor.getcolor("#a4c263", "RGBA")   # sampled from the original body green
RIM = ImageColor.getcolor("#5f8040", "RGBA")    # dark outline on cut edges
LIT = ImageColor.getcolor("#c0d470", "RGBA")    # sparse texture dots
BAND = 3                   # empty margin (px) on a non-matching edge


def load_tiles():
    out = subprocess.run(
        ["luajit", "-e",
         'package.path="./?.lua;"..package.path; '
         'local A = require("src.world.AutoTile"); '
         'io.write(A.CELL, "\\n"); '
         'for m = 0, 15 do local t = A.TILES[m]; '
         'io.write(m, " ", t[1], " ", t[2], "\\n") end'],
        capture_output=True, text=True, check=True).stdout.splitlines()
    cell = int(out[0])
    tiles = {}
    for line in out[1:]:
        mask, x, y = (int(v) for v in line.split())
        tiles[mask] = (x, y)
    return tiles, cell


# direction bit -> the band each NON-matching edge carves off the cell.
# N=1, W=2, E=4, S=8 (AutoTile.DIRS). The rim then falls out of the shape
# itself: a grass pixel adjacent to a CARVED pixel is darkened. Edges
# that connect (no carve inside the cell) get no rim -- so mask 15 is a
# plain seamless square and adjacent 15s tile perfectly.
CARVE = {
    1: lambda x, y: y < BAND,
    2: lambda x, y: x < BAND,
    4: lambda x, y: x >= S - BAND,
    8: lambda x, y: y >= S - BAND,
}
DOTS = ((6, 5), (11, 8), (4, 12), (9, 13))


def grass_shape(mask):
    cuts = [CARVE[bit] for bit in (1, 2, 4, 8) if not mask & bit]
    return [[not any(c(x, y) for c in cuts) for x in range(S)] for y in range(S)]


img = Image.new("RGBA", (W, H), TRANSPARENT)
pix = img.load()

TILES, CELL = load_tiles()
assert CELL == S, "this tool and AutoTile.lua disagree on cell size"

for mask, (tx, ty) in TILES.items():
    grass = grass_shape(mask)
    for y in range(S):
        for x in range(S):
            if not grass[y][x]:
                pix[tx + x, ty + y] = TRANSPARENT
            elif any(0 <= nx < S and 0 <= ny < S and not grass[ny][nx]
                     for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                pix[tx + x, ty + y] = RIM
            else:
                pix[tx + x, ty + y] = FILL
    for dx, dy in DOTS:
        if grass[dy][dx]:
            pix[tx + dx, ty + dy] = LIT

img.save("assets/grass_tiles.png")
print("wrote assets/grass_tiles.png (160x128, 16px cells, v2-compatible geometry)")
