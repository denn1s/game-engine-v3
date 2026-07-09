function love.load()
end

function love.update(dt)
end

function love.draw()
    love.graphics.print("Game Engine Architecture v3 — Lua + LÖVE", 10, 10)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
