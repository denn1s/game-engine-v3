----------------------------------------------------------------------
-- Lesson 03: Scenes
--
-- The game is now three scenes — menu, play, gameover — owned and
-- switched by the Game. main.lua registers them and forwards LÖVE's
-- callbacks. Notice what is NOT here anymore: no state variable, no
-- entity handling, no restart logic. The scene graph IS the state
-- machine.
--
-- Key presses still enter the world as DATA: the Game turns each one
-- into a `keyPressed` event entity in the current scene's registry
-- (see Game.keypressed), and whichever systems care consume it there.
--
-- menu --SPACE--> play --someone wins--> gameover --SPACE--> menu
----------------------------------------------------------------------

local Game = require("src.Game")

function love.load()
    Game.registerScene("menu", require("src.scenes.MenuScene"))
    Game.registerScene("play", require("src.scenes.PlayScene"))
    Game.registerScene("gameover", require("src.scenes.GameOverScene"))

    Game.start("menu")
end

function love.update(dt)
    Game.update(dt)
end

function love.draw()
    Game.draw()
end

function love.keypressed(key)
    Game.keypressed(key)
end

function love.quit()
    Game.quit()
end
