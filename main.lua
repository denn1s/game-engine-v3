----------------------------------------------------------------------
-- Lesson 14: the map — part 2, tiles & autotiling.
--
-- The engine is complete enough now to stop explaining itself and start
-- being used. This file only bootstraps: register scenes, start one, hand
-- the callbacks to the Game. It opens on the tile lab, this lesson's
-- microscope; `love . map` boots the walkable map. Key presses still enter
-- the world as DATA: the Game turns each one into a `keyPressed` event
-- entity in the current scene's registry — unless the overlay consumed them
-- first. (Held input is the exception: continuous keys — walking — and mouse
-- buttons — painting — are polled, not evented; see MapInputSystem and
-- TileLabInputSystem.)
----------------------------------------------------------------------

local Game = require("src.Game")
local DebugOverlay = require("src.debug.DebugOverlay")
local attachDebugOverlay = require("src.debug.attach")

function love.load(args)
    Game.registerScene("week", require("src.scenes.WeekScene"))
    Game.registerScene("packLab", require("src.scenes.PackLabScene"))
    Game.registerScene("collection", require("src.scenes.CollectionScene"))
    Game.registerScene("animLab", require("src.scenes.AnimationLabScene"))
    Game.registerScene("tileLab", require("src.scenes.TileLabScene"))
    Game.registerScene("map", require("src.scenes.MapScene"))

    -- This lesson's subject is the tile lab, so it is what the game opens
    -- on: `love .` shows the autotiling microscope directly. `love . map`
    -- boots the walkable map, and every scene stays reachable from the
    -- debug switcher.
    --
    -- A leading arg that names a registered scene overrides the default.
    -- Any other first arg (e.g. --debug) is not a scene, so we fall back
    -- to the lab.
    local known, startScene = {}, "tileLab"
    for _, name in ipairs(Game.sceneNames()) do
        known[name] = true
    end
    if known[args[1]] then
        startScene = args[1]
    end
    Game.start(startScene)

    attachDebugOverlay(Game)
    for _, arg in ipairs(args) do
        if arg == "--debug" then
            DebugOverlay.enterEditor()
        end
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
