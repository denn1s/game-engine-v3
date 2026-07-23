----------------------------------------------------------------------
-- Lesson 04.5 (optional): the editor window
--
-- `love . --debug` now opens a LARGER window with the game running
-- inside a viewport — the tool panels snapped to the sides — like
-- Unity's Game view. The trick is one primitive: the game renders into
-- a fixed-size Canvas (a texture), and the overlay shows that texture
-- inside a UI window. Plain `love .` is untouched: the game draws
-- straight to the screen and F1 summons the overlay from lesson 04.
--
-- The overlay is NOT part of the game — and its wiring is not part of
-- main.lua either. src/debug/attach.lua wraps the callbacks below so
-- the overlay can watch the Game from outside; scenes never know it's
-- there — and now they don't even know whether the "screen" they draw
-- to is the real one or the editor's canvas. This file only
-- bootstraps: register scenes, start one, hand the callbacks to the
-- Game.
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
        DebugOverlay.enterEditor()
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
