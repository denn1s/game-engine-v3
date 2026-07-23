-- Integrates velocity into position, for ANY entity that has both.
-- Paddles, balls, and everything we add later move through this one system.

local MovementSystem = {}

function MovementSystem.update(scene, dt)
    local registry = scene.registry

    for _, pos, vel in registry:each("position", "velocity") do
        pos.x = pos.x + vel.vx * dt
        pos.y = pos.y + vel.vy * dt
    end
end

return MovementSystem
