-- Advances every tween clock and writes the sampled value into the
-- entity's position. That's the whole job: TIME in, COMPONENT out.
-- The renderer that draws the square never does a tween calculation,
-- and the code that spawned the entity never touches dt.
--
-- Looping is this system's policy, not Tween's: a Tween is one
-- single pass and stays clamped after it arrives; `hold` adds a pause
-- at the end before the clock wraps.

local TweenSystem = { name = "tweenSystem" }

function TweenSystem.update(scene, dt)
    local registry = scene.registry
    local lab = registry:resource("animLab")

    for _, pos, anim, demo in registry:each("position", "tweenAnim", "demo") do
        if demo.n == lab.demo then
            anim.t = anim.t + dt
            local hold = anim.hold or 0
            local cycle = anim.tween.duration + hold
            local sample = anim.t % cycle
            if anim.t >= cycle and hold == 0 then
                sample = anim.tween.duration -- no-pause tweens stay arrived
            end

            -- p = raw progress (the clock), e = eased progress (the feel).
            -- Keeping both visible is the lesson: the curve changes how
            -- the value MOVES, never WHEN it arrives.
            anim.p = math.min(sample / anim.tween.duration, 1)
            anim.e = anim.tween.easing(anim.p)
            pos.x = anim.tween.from + (anim.tween.to - anim.tween.from) * anim.e
            anim.value = pos.x
        end
    end
end

return TweenSystem
