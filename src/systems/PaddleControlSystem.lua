-- Reads the keyboard and turns it into velocity for paddle entities.
-- Note it doesn't move anything: that's the MovementSystem's job.

local MARGIN = 30 -- distance from paddles to the side walls

local PaddleControlSystem = {}

-- This system owns the paddles, so it creates them.
function PaddleControlSystem.setup(scene)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    local function paddlePrefab(x, upKey, downKey)
        return {
            position = { x = x, y = (screenH - 80) / 2 },
            size = { w = 14, h = 80 },
            velocity = { vx = 0, vy = 0 },
            paddle = { upKey = upKey, downKey = downKey, speed = 320 },
            clamp = {},
        }
    end

    scene.registry:spawn(paddlePrefab(MARGIN, "w", "s"))
    scene.registry:spawn(paddlePrefab(screenW - MARGIN - 14, "up", "down"))
end

function PaddleControlSystem.update(scene, dt)
    local registry = scene.registry
    local _, match = registry:first("match")
    if match.state ~= "play" then return end -- frozen on the gameover screen

    for _, entity in ipairs(registry:query("paddle", "velocity")) do
        local paddle = registry:get(entity, "paddle")
        local vel = registry:get(entity, "velocity")

        local dir = 0
        if love.keyboard.isDown(paddle.upKey) then dir = dir - 1 end
        if love.keyboard.isDown(paddle.downKey) then dir = dir + 1 end

        vel.vy = dir * paddle.speed
    end
end

return PaddleControlSystem
