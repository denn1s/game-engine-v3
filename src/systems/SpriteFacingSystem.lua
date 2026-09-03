-- Turns motion into LOOKS. The generic MovementSystem decides WHERE an
-- entity goes; this system is the sprite-aware half that decides how a
-- walking SPRITE should read that motion:
--
--   moveIntent  -->  Movement.facing  -->  sprite.row   (which way it faces)
--   moving?     ---------------------->  clipAnim.playing (run, or idle?)
--
-- It is deliberately SEPARATE from MovementSystem so movement stays
-- reusable by anything that merely has a velocity (arrows, debris,
-- NPCs) — none of which wear a walk sheet. Only things that are both
-- moving AND drawn get a sprite and a clipAnim, so only they match here.
--
-- Like MovementSystem, it does NOT touch sprite.frame: that is
-- SpriteAnimationSystem's job. The split is the lesson — MOVEMENT says
-- where, FACING says which way, ANIMATION says which foot is down.
--
-- The placeholder world-wrap also lives here, not in MovementSystem,
-- because it needs the drawn footprint (sprite.w * scale) to let the
-- sprite fully clear an edge before popping back. It becomes real
-- COLLISION (its own system) in lesson 15.

local Screen = require("src.Screen")
local Movement = require("src.world.Movement")

local SpriteFacingSystem = { name = "spriteFacing" }

function SpriteFacingSystem.update(scene, dt)
    local registry = scene.registry

    for _, pos, intent, sprite, anim in
        registry:each("position", "moveIntent", "sprite", "clipAnim") do

        local moving = intent.dx ~= 0 or intent.dy ~= 0

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

return SpriteFacingSystem
