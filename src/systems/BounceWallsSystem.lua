-- Entities tagged with `bounceWalls` reflect off the top and bottom of
-- the screen. The ball uses this. Runs AFTER movement.

local BounceWallsSystem = {}

function BounceWallsSystem.update(scene, dt)
    local registry = scene.registry
    local _, match = registry:first("match")
    if match.state ~= "play" then return end -- frozen on the gameover screen

    local screenH = love.graphics.getHeight()

    for _, entity in ipairs(registry:query("bounceWalls", "position", "size", "velocity")) do
        local pos = registry:get(entity, "position")
        local size = registry:get(entity, "size")
        local vel = registry:get(entity, "velocity")

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
