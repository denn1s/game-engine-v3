----------------------------------------------------------------------
-- Lesson 13: the map — part 1, a sprite that moves.
--
-- The engine is complete enough now to stop explaining itself and start
-- being used. This file only bootstraps: register scenes, start one, hand
-- the callbacks to the Game. Key presses still enter the world as DATA:
-- the Game turns each one into a `keyPressed` event entity in the current
-- scene's registry — unless the overlay consumed them first. (Walking is
-- the exception: continuous held-keys are polled, not evented — see
-- MapInputSystem.)
----------------------------------------------------------------------

local Game = require("src.Game")
local DebugOverlay = require("src.debug.DebugOverlay")
local attachDebugOverlay = require("src.debug.attach")

function love.load(args)
    Game.registerScene("week", require("src.scenes.WeekScene"))
    Game.registerScene("packLab", require("src.scenes.PackLabScene"))
    Game.registerScene("collection", require("src.scenes.CollectionScene"))
    Game.registerScene("animLab", require("src.scenes.AnimationLabScene"))
    Game.registerScene("map", require("src.scenes.MapScene"))

    -- The card pipeline is finished, so the game opens on the new subject:
    -- the world the characters will walk between dates. The raising sim and
    -- card scenes stay reachable from the debug scene switcher.
    Game.start("map")

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
