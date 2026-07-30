local Screen = require("src.Screen") -- the game's resolution, one source

function love.conf(t)
    -- names the game's per-user save directory (love.filesystem writes
    -- there and nowhere else) — without it, LÖVE falls back to the
    -- folder name, and renaming the project would orphan every save
    t.identity = "game-engine-v3"
    t.window.title = "Small Talk"
    t.window.width = Screen.w
    t.window.height = Screen.h
    t.version = "11.5"
end
