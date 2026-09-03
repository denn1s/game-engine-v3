-- Turns intent into a place in the world. Deliberately THIN and, above
-- all, GENERIC: it only knows that an entity has a position and a
-- velocity, never what it looks like. That is what makes it reusable —
-- anything that moves on screen (a leaf, an arrow, an NPC, the player)
-- gets motion by owning these three components and nothing else.
--
--   moveIntent  -->  Movement  -->  velocity  -->  position
--
-- All the actual thinking (normalize the diagonal? how fast?) lives in
-- the pure Movement module, so it can be tested without a window. This
-- system just moves data through the components.
--
-- It does NOT touch the sprite at all: which way the character FACES and
-- whether it's WALKING are presentation, and live in SpriteFacingSystem
-- now. And it does NOT touch walls — those arrive as their own collision
-- system in lesson 15, not bolted on here.

local Movement = require("src.world.Movement")

local MovementSystem = { name = "movement" }

function MovementSystem.update(scene, dt)
    local registry = scene.registry
    local map = registry:resource("map")

    for _, pos, intent, velocity in
        registry:each("position", "moveIntent", "velocity") do

        -- Which way, how fast — from the pure module, no math here.
        local vx, vy = Movement.direction(intent.dx, intent.dy, map.normalize)

        -- Integrate: px/sec * this frame's seconds. THIS is where dt
        -- finally earns its keep in the game proper — speed is authored
        -- in real units (map.speed), independent of frame rate.
        velocity.x = vx * map.speed
        velocity.y = vy * map.speed
        pos.x = pos.x + velocity.x * dt
        pos.y = pos.y + velocity.y * dt
    end
end

return MovementSystem
