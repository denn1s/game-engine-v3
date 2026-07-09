-- Integrates velocity into position, for ANY entity that has both.
-- Paddles, balls, and everything we add later move through this one system.

local MovementSystem = {}

function MovementSystem.update(scene, dt)
    local registry = scene.registry

    for _, entity in ipairs(registry:query("position", "velocity")) do
        local pos = registry:get(entity, "position")
        local vel = registry:get(entity, "velocity")
        pos.x = pos.x + vel.vx * dt
        pos.y = pos.y + vel.vy * dt
    end
end

return MovementSystem
