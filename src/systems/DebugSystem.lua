-- Debug helpers for the play scene. B spawns an extra ball — partly an
-- ECS flex, partly the seed of the debug-tooling lesson coming soon.

local DebugSystem = {}

function DebugSystem.keypressed(scene, key)
    if key == "b" then
        scene.registry:spawn({
            serveRequest = { direction = love.math.random() < 0.5 and -1 or 1 },
        })
    end
end

return DebugSystem
