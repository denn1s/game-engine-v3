----------------------------------------------------------------------
-- Lesson 04: Debug tools
--
-- The engine gains a debug overlay built on imlove (our vendored
-- immediate-mode UI, lib/imlove.lua): an entity inspector, pause, and
-- frame-stepping. Press F1 in game, or start with `love . --debug`.
--
-- The overlay is NOT part of the game. It sits next to the Game,
-- watching whatever scene is current; scenes never know it's there.
--
-- Key presses still enter the world as DATA: the Game turns each one
-- into a `keyPressed` event entity in the current scene's registry
-- (see Game.keypressed) — unless the overlay consumed them first.
--
-- menu --SPACE--> play --someone wins--> gameover --SPACE--> menu
----------------------------------------------------------------------

local Game = require("src.Game")
local DebugOverlay = require("src.debug.DebugOverlay")

function love.load(args)
    Game.registerScene("menu", require("src.scenes.MenuScene"))
    Game.registerScene("play", require("src.scenes.PlayScene"))
    Game.registerScene("gameover", require("src.scenes.GameOverScene"))

    Game.start("menu")

    if args[1] == "--debug" then
        DebugOverlay.toggle()
    end
end

function love.update(dt)
    DebugOverlay.beginFrame(Game.current())
    if DebugOverlay.shouldUpdate() then -- the pause / frame-step gate
        Game.update(dt)
    end
end

function love.draw()
    Game.draw()
    DebugOverlay.draw() -- UI on top of everything
end

function love.keypressed(key)
    if DebugOverlay.keypressed(key) then return end
    Game.keypressed(key)
end

-- The game has no mouse input yet, but the pattern is already the right
-- one: when the UI consumes an event, the game must never see it.
function love.mousepressed(x, y, button)
    if DebugOverlay.mousepressed(x, y, button) then return end
end

function love.textinput(text)
    if DebugOverlay.textinput(text) then return end
end

function love.mousereleased(x, y, button)
    if DebugOverlay.mousereleased(x, y, button) then return end
end

function love.wheelmoved(dx, dy)
    if DebugOverlay.wheelmoved(dx, dy) then return end
end

function love.quit()
    Game.quit()
end
