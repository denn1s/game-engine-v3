-- Draws the stat triangle, left column above the text box: a tiny
-- radar chart of the three hidden stats against an arbitrary DISPLAY
-- ceiling. The exact numbers stay hidden (GDD §5) — the player sees
-- their SHAPE (Int-heavy, Sense lagging) and, because the ceiling is
-- fixed, the shape visibly FILLS toward the rim as they practice.
-- The rim itself is representation, not rules: nothing in the game
-- reads DISPLAY_MAX, and stats keep counting past it happily (the
-- corner just pins at the rim).
--
-- Pure presentation over RunState, like the date: StatsSystem bumps a
-- number, and the shape is simply different the next time this looks.

local RadarRenderSystem = { name = "radarRender" }

local CX, CY = 76, 250 -- center: left column, riding above the text box
local R = 44 -- radius to a corner, px

-- the display ceiling: a corner touches the rim at 30 picks of the
-- same activity — half the run's 60 picks, a heavy specialization.
-- Purely a feel number; tune it live in the inspector-less way, here.
local DISPLAY_MAX = 30

-- one axis per stat, corners of an equilateral triangle: int on top,
-- charm lower-left, sense lower-right. Angles in radians, -90° is up.
local AXES = {
    { stat = "int",   label = "I", angle = -math.pi / 2 },
    { stat = "charm", label = "C", angle = math.pi - math.pi / 6 },
    { stat = "sense", label = "S", angle = math.pi / 6 },
}

local labelFont

function RadarRenderSystem.setup(scene)
    labelFont = love.graphics.newFont(11)
end

function RadarRenderSystem.unload(scene)
    -- drop the reference, the GC collects it; never release() fonts
    labelFont = nil
end

-- corner of the triangle at `fraction` of the way out along an axis
local function point(axis, fraction)
    return CX + math.cos(axis.angle) * R * fraction,
        CY + math.sin(axis.angle) * R * fraction
end

function RadarRenderSystem.draw(scene)
    local stats = scene.registry:resource("runState").stats


    -- the frame: full-size triangle plus a spoke per axis, both dim
    love.graphics.setColor(1, 1, 1, 0.25)
    local frame = {}
    for _, axis in ipairs(AXES) do
        local x, y = point(axis, 1)
        frame[#frame + 1] = x
        frame[#frame + 1] = y
        love.graphics.line(CX, CY, x, y)
    end
    love.graphics.polygon("line", frame)

    -- the shape: each corner at its stat's share of the ceiling,
    -- pinned to the rim once it's past. Skipped while everything is
    -- zero — all three corners would sit on the center, and a
    -- zero-area polygon is not a polygon (the generator also rejects that
    -- invalid debug state; ordinary runs begin at 1/1/1)
    if stats.int + stats.charm + stats.sense > 0 then
        local shape = {}
        for _, axis in ipairs(AXES) do
            local x, y = point(axis,
                math.min(stats[axis.stat] / DISPLAY_MAX, 1))
            shape[#shape + 1] = x
            shape[#shape + 1] = y
        end
        love.graphics.setColor(0.55, 0.75, 1.0, 0.4)
        love.graphics.polygon("fill", shape)
        love.graphics.setColor(0.55, 0.75, 1.0, 0.9)
        love.graphics.polygon("line", shape)
    end

    -- axis letters, just past each corner
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setFont(labelFont)
    for _, axis in ipairs(AXES) do
        local x, y = point(axis, 1.25)
        love.graphics.print(axis.label,
            x - labelFont:getWidth(axis.label) / 2,
            y - labelFont:getHeight() / 2)
    end
    love.graphics.setColor(1, 1, 1)
end

return RadarRenderSystem
