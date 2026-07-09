-- Draws the title screen.

local MenuRenderSystem = {}

local titleFont, smallFont

function MenuRenderSystem.setup(scene)
    titleFont = love.graphics.newFont(72)
    smallFont = love.graphics.newFont(16)
end

function MenuRenderSystem.unload(scene)
    -- drop the references; the GC collects them. See RenderSystem.unload
    -- for why we never release() fonts.
    titleFont, smallFont = nil, nil
end

function MenuRenderSystem.draw(scene)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    love.graphics.setFont(titleFont)
    love.graphics.printf("PONG", 0, screenH * 0.28, screenW, "center")

    love.graphics.setFont(smallFont)
    love.graphics.printf("press SPACE to play  —  ESC quits",
        0, screenH * 0.62, screenW, "center")
end

return MenuRenderSystem
