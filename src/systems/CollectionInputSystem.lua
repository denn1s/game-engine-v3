-- Keyboard input becomes collection intent. It does not know where the cursor
-- is or how many cards fit on a page; CollectionSelectionSystem owns that.

local CollectionInputSystem = { name = "collectionInput" }

local DIRECTIONS = {
    left = "left",
    right = "right",
    up = "up",
    down = "down",
}

function CollectionInputSystem.update(scene, dt)
    local registry = scene.registry
    for _, event in registry:each("keyPressed") do
        local direction = DIRECTIONS[event.key]
        if direction then
            registry:spawn({
                event = true,
                collectionMoveRequested = { direction = direction },
            })
        elseif event.key == "home" then
            registry:spawn({
                event = true,
                collectionJumpRequested = { edge = "first" },
            })
        elseif event.key == "end" then
            registry:spawn({
                event = true,
                collectionJumpRequested = { edge = "last" },
            })
        end
    end
end

return CollectionInputSystem
