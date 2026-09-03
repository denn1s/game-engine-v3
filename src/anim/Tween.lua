-- A Tween is one number travelling between two values in a fixed
-- amount of SECONDS. That unit is the point: gameplay waits on the
-- tween (`while t < duration`), so the motion's contract is "arrive
-- in 2 seconds" — never "move 100 pixels per frame", which would
-- depend on how fast the machine is.
--
-- Pure sampling: given elapsed time, what is the value? No state,
-- no clock, no LÖVE. Systems own the accumulating t; this answers it.

local Easing = require("src.anim.Easing")

local Tween = {}

function Tween.new(from, to, duration, easing)
    assert(duration > 0, "a tween needs a positive duration")
    return {
        from = from,
        to = to,
        duration = duration,
        easing = easing or Easing.linear,
    }
end

-- The value at elapsed time t, clamped: before 0 it holds the start,
-- after `duration` it holds the end forever. A tween is a promise
-- about two moments, not an ongoing process.
function Tween.at(tween, t)
    local p = t / tween.duration
    if p < 0 then p = 0 elseif p > 1 then p = 1 end
    return tween.from + (tween.to - tween.from) * tween.easing(p)
end

return Tween
