-- Keeps entities tagged with a `clamp` component inside the window
-- (vertically). The paddles use this. Runs AFTER movement.

local ClampSystem = {}

function ClampSystem.update(scene, dt)
    local registry = scene.registry

    local screenH = love.graphics.getHeight()

    -- the `clamp` tag goes last: its (empty) value just falls off the end
    for _, pos, size in registry:each("position", "size", "clamp") do
        if pos.y < 0 then pos.y = 0 end
        if pos.y + size.h > screenH then pos.y = screenH - size.h end
    end
end

return ClampSystem
