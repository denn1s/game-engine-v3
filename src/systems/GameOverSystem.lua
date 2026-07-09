-- Waits for SPACE, then back to the menu — the loop closes:
-- menu -> play -> gameover -> menu.

local GameOverSystem = {}

function GameOverSystem.keypressed(scene, key)
    if key == "space" then
        scene.registry:spawn({ switchRequest = { to = "menu" } })
    end
end

return GameOverSystem
