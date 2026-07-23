-- Debug helpers for the play scene. B spawns an extra ball — partly an
-- ECS flex, partly the seed of the debug-tooling lesson coming soon.
--
-- An input system: it only turns key events into request entities, so
-- it runs FIRST in the scene — the BallSpawnSystem right after it
-- consumes the serveRequest on this very frame.

local DebugSystem = {}

function DebugSystem.update(scene, dt)
    for _, event in scene.registry:each("keyPressed") do
        if event.key == "b" then
            scene.registry:spawn({
                serveRequest = { direction = love.math.random() < 0.5 and -1 or 1 },
            })
        end
    end
end

return DebugSystem
