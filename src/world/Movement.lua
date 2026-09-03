-- The two decisions a moving character has to make that are NOT about
-- the running world: given the raw keys a player is holding, WHICH
-- direction do we actually travel, and WHICH WAY DOES THE SPRITE FACE.
--
-- Like CardArt, this file is a plain transformation, not a system: it
-- touches no registry, no scene, no LÖVE. That is why tests/movement.lua
-- runs it under bare LuaJIT. MovementSystem is the thin adapter that
-- feeds these pure answers into a living entity's components.
--
--   raw input      two axes, each -1 / 0 / 1, a player just typed
--   direction()    -> the velocity to travel at (the diagonal fix)
--   facing()       -> which row of the sheet to draw (which way it looks)

local Movement = {}

-- The sheet's rows are our facing convention. Classic RPG walk sheets
-- lay the four directions out as horizontal strips; the row number is
-- which strip. Everything that draws or builds the art agrees on this.
Movement.ROWS = { down = 1, left = 2, right = 3, up = 4 }

-- Given raw axis presses, return the velocity multipliers to travel by,
-- plus the raw magnitude (for the readout that teaches the bug).
--
--   (0,0)    -> standing still: zero velocity, no motion.
--   (1,0)    -> one grid axis: speed 1.
--   (1,1)    -> a diagonal. Unnormalized that is magnitude sqrt(2):
--               the classic "walking into a corner is 41% faster" bug.
--
-- When `normalize` is on we scale the vector back to unit length, so a
-- diagonal covers EXACTLY the same ground per second as a straight
-- line — at the cost of, say, a north-east walk no longer lining up
-- with the tile grid (irrelevant here, a 45-degree glide reads great).
-- When it is off we pass the raw axes through, deliberately, so the
-- class can FEEL the difference (press N in the map).
function Movement.direction(dx, dy, normalize)
    local rawMag = math.sqrt(dx * dx + dy * dy)
    if rawMag == 0 then
        return 0, 0, 0
    end
    if normalize then
        return dx / rawMag, dy / rawMag, rawMag
    end
    return dx, dy, rawMag
end

-- Which row of the walk sheet to draw for this raw press. Only called
-- while actually moving; the caller keeps the last facing when idle so
-- the character doesn't snap to "down" every time you let go.
--
-- Eight possible presses, four rows: pick the DOMINANT axis. On a dead
-- tie we prefer horizontal — a coin-flip with no wrong answer, made
-- explicit so the code reads as a choice and not an accident.
function Movement.facing(dx, dy)
    if dx == 0 and dy == 0 then
        return nil -- standing: no facing change
    end
    if math.abs(dx) >= math.abs(dy) then
        if dx < 0 then return Movement.ROWS.left end
        if dx > 0 then return Movement.ROWS.right end
    end
    if dy < 0 then return Movement.ROWS.up end
    return Movement.ROWS.down
end

return Movement
