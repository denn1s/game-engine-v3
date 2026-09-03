-- Turns intent into a place in the world. The heart of the lesson, and
-- deliberately THIN: all the actual thinking (normalize? which way face?)
-- lives in the pure Movement module, so it can be tested without a
-- window. This system just moves data through the components:
--
--   moveIntent  --\
--                 Movement -> position (integrate), sprite.row (face),
--                 clipAnim.playing (tell the animator to run or idle)
--
-- It does NOT touch sprite.frame. That is SpriteAnimationSystem's job
-- and the boundary between the two is the point: MOVEMENT decides where
-- you are and that you're walking; ANIMATION decides which foot is down.
-- A teleport would run one and not the other; this keeps them swappable.
--
-- It also does NOT touch walls. There are none yet — walk off any edge
-- and the world wraps, so a demo student wandering backwards can't get
-- lost. That wrap is a placeholder that LITERALLY BECOMES COLLISION in
-- lesson 15: the last thing this lesson wants is to make it real.

local Screen = require("src.Screen")
local Movement = require("src.world.Movement")

local MovementSystem = { name = "movement" }

function MovementSystem.update(scene, dt)
    local registry = scene.registry
    local map = registry:resource("map")

    for _, pos, intent, velocity, sprite, anim in
        registry:each("position", "moveIntent", "velocity", "sprite", "clipAnim") do

        -- Which way, how fast — from the pure module, no math here.
        local vx, vy, rawMag = Movement.direction(intent.dx, intent.dy, map.normalize)
        local moving = rawMag > 0

        -- Integrate: px/sec * this frame's seconds. THIS is where dt
        -- finally earns its keep in the game proper — speed is authored
        -- in real units (map.speed), independent of frame rate.
        velocity.x = vx * map.speed
        velocity.y = vy * map.speed
        pos.x = pos.x + velocity.x * dt
        pos.y = pos.y + velocity.y * dt

        -- Facing: only when moving, so we keep the last direction when
        -- idle instead of snapping to "down" every time keys are let go.
        if moving then
            sprite.row = Movement.facing(intent.dx, intent.dy)
        end

        -- The one word we hand the animator: run, or idle.
        anim.playing = moving

        -- Placeholder wrap. A cell is the drawn footprint, so the sprite
        -- fully clears one edge before it pops back on the other.
        local cell = sprite.w * (sprite.scale or 1)
        if pos.x > Screen.w then pos.x = -cell end
        if pos.x < -cell then pos.x = Screen.w end
        if pos.y > Screen.h then pos.y = -cell end
        if pos.y < -cell then pos.y = Screen.h end
    end
end

return MovementSystem
