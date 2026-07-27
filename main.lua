----------------------------------------------------------------------
-- Lesson 04: Debug tools
--
-- The engine gains a debug overlay built on imlove (our vendored
-- immediate-mode UI, lib/imlove.lua): an entity inspector, pause, and
-- frame-stepping. Press F1 in game, or start with `love . --debug`.
--
-- The overlay is NOT part of the game — and its wiring is not part of
-- main.lua either. src/debug/attach.lua wraps the callbacks below so
-- the overlay can watch the Game from outside; scenes never know it's
-- there. This file only bootstraps: register scenes, start one, hand
-- the LÖVE callbacks to the Game.
--
-- Key presses still enter the world as DATA: the Game turns each one
-- into a `keyPressed` event entity in the current scene's registry
-- (see Game.keypressed) — unless the overlay consumed them first.
--
-- menu --SPACE--> play --someone wins--> gameover --SPACE--> menu
----------------------------------------------------------------------

local Game = require("src.Game")
local DebugOverlay = require("src.debug.DebugOverlay")
local attachDebugOverlay = require("src.debug.attach")

function love.load(args)
    Game.registerScene("menu", require("src.scenes.MenuScene"))
    Game.registerScene("play", require("src.scenes.PlayScene"))
    Game.registerScene("gameover", require("src.scenes.GameOverScene"))

    Game.start("menu")

    attachDebugOverlay(Game)
    if args[1] == "--debug" then
        DebugOverlay.toggle()
    end
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
