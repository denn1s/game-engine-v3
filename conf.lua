local Screen = require("src.Screen") -- the game's resolution, one source

function love.conf(t)
    t.window.title = "04.5 - The Editor Window"
    t.window.width = Screen.w
    t.window.height = Screen.h
    t.version = "11.5"
end
