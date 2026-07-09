-- The menu's only logic: wait for SPACE, then ask for the play scene.
-- Note it doesn't know HOW scenes are switched — it asks, in data.

local MenuSystem = {}

function MenuSystem.keypressed(scene, key)
    if key == "space" then
        scene.registry:spawn({ switchRequest = { to = "play" } })
    end
end

return MenuSystem
