-- Waits for SPACE, then back to the menu — the loop closes:
-- menu -> play -> gameover -> menu.

local GameOverSystem = { name = "gameOver" }

function GameOverSystem.update(scene, dt)
    for _, event in scene.registry:each("keyPressed") do
        if event.key == "space" then
            scene.registry:spawn({ switchRequest = { to = "menu" } })
        end
    end
end

return GameOverSystem
