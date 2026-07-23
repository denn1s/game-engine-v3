-- Entities tagged with `bounceWalls` reflect off the top and bottom of
-- the screen. The ball uses this. Runs AFTER movement.

local BounceWallsSystem = {}

function BounceWallsSystem.update(scene, dt)
    local registry = scene.registry

    local screenH = love.graphics.getHeight()

    for _, pos, size, vel in registry:each("position", "size", "velocity", "bounceWalls") do
        if pos.y < 0 then
            pos.y = 0
            vel.vy = -vel.vy
        elseif pos.y + size.h > screenH then
            pos.y = screenH - size.h
            vel.vy = -vel.vy
        end
    end
end

return BounceWallsSystem
