-- Spawns balls. Note that NOBODY calls this system directly: whoever
-- wants a ball (the scoring system, the B key, scene setup) spawns a
-- tiny entity carrying only a `serveRequest` component, and this system
-- consumes it on the next frame.
--
-- This is the "events as entities" pattern: systems never call each
-- other — they communicate by writing data into the registry.

local START_SPEED = 280
local SIZE = 14

local BallSpawnSystem = { name = "ballSpawn" }

function BallSpawnSystem.setup(scene)
    -- ask for the opening serve; update() does the actual spawning
    scene.registry:spawn({ serveRequest = { direction = 1 } })
end

function BallSpawnSystem.update(scene, dt)
    local registry = scene.registry

    for requestEntity, request in registry:each("serveRequest") do
        registry:destroy(requestEntity) -- consume the event

        registry:spawn({
            position = {
                x = (love.graphics.getWidth() - SIZE) / 2,
                y = (love.graphics.getHeight() - SIZE) / 2,
            },
            size = { w = SIZE, h = SIZE },
            velocity = {
                vx = START_SPEED * request.direction,
                -- random vertical angle so serves aren't identical
                vy = START_SPEED * (love.math.random() - 0.5),
            },
            ball = {},
            bounceWalls = {},
        })
    end
end

return BallSpawnSystem
