-- Draws everything: the court, every entity with position + size, and
-- the UI. It's the only system with a `draw` instead of an `update`.

local RenderSystem = { name = "render" }

local bigFont, smallFont

function RenderSystem.setup(scene)
    bigFont = love.graphics.newFont(48)
    smallFont = love.graphics.newFont(16)
end

function RenderSystem.unload(scene)
    -- Dropping the references is enough: LÖVE objects are garbage
    -- collected. font:release() looks tidier but is a trap — this font
    -- may still be love.graphics' CURRENT font, and using a released
    -- object crashes. Never release() what shared state might still
    -- reference.
    bigFont, smallFont = nil, nil
end

function RenderSystem.draw(scene)
    local registry = scene.registry
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- center line
    love.graphics.setColor(1, 1, 1, 0.35)
    for y = 0, screenH, 30 do
        love.graphics.rectangle("fill", screenW / 2 - 2, y, 4, 15)
    end
    love.graphics.setColor(1, 1, 1)

    -- score (from the match singleton)
    local _, match = registry:first("match")
    love.graphics.setFont(bigFont)
    love.graphics.printf(tostring(match.left), 0, 20, screenW / 2 - 40, "right")
    love.graphics.printf(tostring(match.right), screenW / 2 + 40, 20, screenW / 2 - 40, "left")

    -- every entity that has a position and a size is a white rectangle.
    -- (Sprites arrive in a few weeks; this is our "render component" for now.)
    for _, pos, size in registry:each("position", "size") do
        love.graphics.rectangle("fill", pos.x, pos.y, size.w, size.h)
    end

    -- the winner screen is gone from here: that's the gameover SCENE's
    -- renderer now (GameOverRenderSystem)
    love.graphics.setFont(smallFont)
    love.graphics.printf("B: spawn an extra ball (ECS flex)",
        0, screenH - 24, screenW, "center")
end

return RenderSystem
