-- The menu's only logic: wait for SPACE, then ask for the play scene.
-- Note it doesn't know HOW scenes are switched — it asks, in data. Even
-- the key press arrives as data: a `keyPressed` event entity the Game
-- spawned. Key events are broadcasts: we read them, never destroy them
-- (the Game sweeps them at the end of the frame).

local MenuSystem = {}

function MenuSystem.update(scene, dt)
    for _, event in scene.registry:each("keyPressed") do
        if event.key == "space" then
            scene.registry:spawn({ switchRequest = { to = "play" } })
        end
    end
end

return MenuSystem
