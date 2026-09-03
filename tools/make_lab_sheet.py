#!/usr/bin/env python3
# Regenerates assets/lab_walk.png: a 4x4 placeholder walk sheet, 32px cells.
# Row = animation (colored), column = frame (big number + moving marker),
# so "which cell is showing?" is answerable at a glance during class.
from PIL import Image, ImageDraw

S = 32
ROWS = ["#406eff", "#ff5060", "#46d278", "#f0e3c2"]
BG = "#0e1018"
DIGITS = {
    1: ["01000", "11000", "01000", "01000", "01000", "01000", "11111"],
    2: ["11110", "00011", "00001", "00110", "01000", "10000", "11111"],
    3: ["11110", "00011", "00001", "00110", "00001", "00011", "11110"],
    4: ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
}

img = Image.new("RGB", (S * 4, S * 4), BG)
d = ImageDraw.Draw(img)
for row, color in enumerate(ROWS):
    for frame in range(4):
        x0, y0 = frame * S, row * S
        d.rectangle([x0 + 1, y0 + 1, x0 + S - 2, y0 + S - 2], outline=color, width=2)
        glyph = DIGITS[frame + 1]
        gx, gy = x0 + 9, y0 + 6
        for py, line in enumerate(glyph):
            for px, bit in enumerate(line):
                if bit == "1":
                    d.rectangle([gx + px * 3, gy + py * 3, gx + px * 3 + 2, gy + py * 3 + 2],
                                fill=color)
        mx = x0 + 6 + frame * 5
        d.rectangle([mx, y0 + S - 8, mx + 4, y0 + S - 4], fill="#ffffff")
img.save("assets/lab_walk.png")
print("wrote assets/lab_walk.png")
