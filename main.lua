----------------------------------------------------------------------
-- Lesson 06: the game proper begins.
--
-- Pong is gone (it lives on in the earlier branches). What remains is
-- the ENGINE it forced us to build: Game (scene switching), Scene
-- (systems + registry), Registry (entities, components, resources),
-- Screen (logical resolution), the save file, and the debug overlay.
--
-- This file only bootstraps: register scenes, start one, hand the
-- callbacks to the Game. Key presses still enter the world as DATA:
-- the Game turns each one into a `keyPressed` event entity in the
-- current scene's registry — unless the overlay consumed them first.
----------------------------------------------------------------------

local Game = require("src.Game")
local DebugOverlay = require("src.debug.DebugOverlay")
local attachDebugOverlay = require("src.debug.attach")

function love.load(args)
    Game.registerScene("week", require("src.scenes.WeekScene"))
    Game.registerScene("packLab", require("src.scenes.PackLabScene"))
    Game.registerScene("collection", require("src.scenes.CollectionScene"))

    -- The generator's balancing instrument remains available in the debug
    -- scene switcher; lesson 11 starts where those generated cards will live.
    Game.start("collection")

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
