package.path = "./?.lua;" .. package.path

local Movement = require("src.world.Movement")

local function near(a, b)
    return math.abs(a - b) < 1e-9
end

local function magnitude(x, y)
    return math.sqrt(x * x + y * y)
end

-- Standing still is not "moving at zero," it is the absence of motion:
-- a zero vector, and no facing so the character keeps the last one.
local vx, vy, raw = Movement.direction(0, 0, true)
assert(vx == 0 and vy == 0 and raw == 0, "idle input still had velocity")
assert(Movement.facing(0, 0) == nil, "idle input invented a facing")

-- The whole point of normalization: straight lines AND diagonals cover
-- exactly one unit of ground per step. Eight directions, one length.
local diagonals = 0
for dx = -1, 1 do
    for dy = -1, 1 do
        if dx ~= 0 or dy ~= 0 then
            local nx, ny = Movement.direction(dx, dy, true)
            assert(near(magnitude(nx, ny), 1),
                ("normalized (%d,%d) is not unit speed"):format(dx, dy))
            if dx ~= 0 and dy ~= 0 then diagonals = diagonals + 1 end
        end
    end
end
assert(diagonals == 4, "expected four diagonal directions")

-- ...and the bug we are normalizing AWAY: leave it off and a diagonal
-- is sqrt(2) faster. The test names the sin so the fix has a reason.
local bx, by = Movement.direction(1, 1, false)
assert(near(magnitude(bx, by), math.sqrt(2)),
    "un-normalized diagonal is not the sqrt(2) bug")

-- Facing: the four cardinals map to the sheet's four rows.
assert(Movement.facing(0, 1) == Movement.ROWS.down, "down is not row 1")
assert(Movement.facing(-1, 0) == Movement.ROWS.left, "left is not row 2")
assert(Movement.facing(1, 0) == Movement.ROWS.right, "right is not row 3")
assert(Movement.facing(0, -1) == Movement.ROWS.up, "up is not row 4")

-- Diagonals pick the dominant axis; an exact tie prefers horizontal.
-- These are policy choices, but they must be STABLE choices.
assert(Movement.facing(1, -1) == Movement.ROWS.right, "tie should prefer horizontal")
assert(Movement.facing(1, -2) == Movement.ROWS.up, "vertical-dominant should face up")
assert(Movement.facing(2, -1) == Movement.ROWS.right, "horizontal-dominant should face right")
assert(Movement.facing(0, 1) ~= Movement.ROWS.up, "down and up collided")

print("movement tests passed -- one unit of ground, every direction")
