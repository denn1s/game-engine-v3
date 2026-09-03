-- Easing curves: pure functions of progress (0..1) -> eased progress (0..1).
-- A tween picks ONE of these to say how it spends its time; the duration
-- never changes, only the velocity profile inside it.

local Easing = {}

function Easing.linear(t)
    return t
end

function Easing.inQuad(t)
    return t * t
end

function Easing.outQuad(t)
    return t * (2 - t)
end

function Easing.inOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    end
    local f = 2 * t - 2
    return 0.5 * f * f * f + 1
end

-- Overshoots the target and settles back. The constant is the
-- back-pull amount; 1.70158 is the classic Robert Penner value.
function Easing.outBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    local f = t - 1
    return 1 + c3 * f * f * f + c1 * f * f
end

return Easing
