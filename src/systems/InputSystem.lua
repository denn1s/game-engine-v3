-- Turns raw key presses into game actions. main.lua decides NOTHING:
-- love.keypressed only spawns a tiny entity carrying a `keyPressed`
-- component, and this system consumes those entities here, inside the
-- normal update order — the same "events as entities" pattern the
-- serveRequest uses. Even the keyboard enters the world as data.
--
-- This system runs FIRST in the scene, so whatever it spawns (say, a
-- serveRequest) is seen by every other system on this same frame.
--
-- (Held keys are different: they're state, not events, so the
-- PaddleControlSystem simply polls love.keyboard.isDown each frame.)

local InputSystem = {}

function InputSystem.update(scene, dt)
    local registry = scene.registry
    local _, match = registry:first("match")

    for _, keyEntity in ipairs(registry:query("keyPressed")) do
        local key = registry:get(keyEntity, "keyPressed").key
        registry:destroy(keyEntity) -- consume the event

        if key == "escape" then
            love.event.quit()
        elseif key == "b" and match.state == "play" then
            registry:spawn({
                serveRequest = { direction = love.math.random() < 0.5 and -1 or 1 },
            })
        elseif key == "space" and match.state == "gameover" then
            match.left, match.right = 0, 0
            match.state = "play"
            -- clean the field: balls AND stale serve requests (a B press on
            -- the match's final frame could leave one behind)
            for _, ballEntity in ipairs(registry:query("ball")) do
                registry:destroy(ballEntity)
            end
            for _, requestEntity in ipairs(registry:query("serveRequest")) do
                registry:destroy(requestEntity)
            end
            registry:spawn({ serveRequest = { direction = 1 } })
        end
    end
end

return InputSystem
