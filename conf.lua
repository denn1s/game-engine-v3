function love.conf(t)
    t.window.title = "00 - Game Loops"
    t.window.width = 960
    t.window.height = 540
    -- vsync normally caps the frame rate to the monitor's refresh rate.
    -- We turn it off in this lesson so WE are in charge of frame timing.
    t.window.vsync = 0
    t.version = "11.5"
end
