-- Draws every menu: a horizontal row of icons, a cursor on the active
-- one, the selected option's name underneath. Pure presentation — the
-- cursor only MOVES in MenuInputSystem; this system just looks at the
-- component and paints what it sees.
--
-- Icons are colored squares with a letter until the sprite lesson,
-- the same placeholder move as pong's white rectangles.

local MenuRenderSystem = { name = "menuRender" }

local ICON = 48 -- icon side, px (small-UI 32px grid rounds up to 48 here)

-- per-option placeholder colors; anything unlisted renders gray
local COLORS = {
    study    = { 0.35, 0.55, 0.95 },
    grooming = { 0.95, 0.55, 0.75 },
    hobbies  = { 0.45, 0.85, 0.55 },
}

local iconFont, labelFont

function MenuRenderSystem.setup(scene)
    iconFont = love.graphics.newFont(28)
    labelFont = love.graphics.newFont(14)
end

function MenuRenderSystem.unload(scene)
    -- drop the references, the GC collects them; never release() fonts
    -- (love.graphics may still hold one as its CURRENT font)
    iconFont, labelFont = nil, nil
end

function MenuRenderSystem.draw(scene)
    for _, pos, menu in scene.registry:each("position", "menu") do
        for i, option in ipairs(menu.options) do
            local x = pos.x + (i - 1) * menu.spacing
            local selected = (i == menu.cursor)

            -- the icon: full color when selected, dimmed otherwise
            local color = COLORS[option] or { 0.6, 0.6, 0.6 }
            local dim = selected and 1 or 0.45
            love.graphics.setColor(color[1] * dim, color[2] * dim, color[3] * dim)
            love.graphics.rectangle("fill", x, pos.y, ICON, ICON, 4, 4)

            love.graphics.setColor(0, 0, 0, 0.75)
            love.graphics.setFont(iconFont)
            love.graphics.printf(option:sub(1, 1):upper(),
                x, pos.y + ICON / 2 - iconFont:getHeight() / 2, ICON, "center")

            -- the cursor: a blinking underline. It doesn't tween over —
            -- it TELEPORTS, like the genre classics; blinking is enough
            -- life for now (animation gets its own lesson).
            if selected and math.sin(love.timer.getTime() * 6) > -0.4 then
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", x, pos.y + ICON + 6, ICON, 3)
            end
        end

        -- the selected option's name. This string wants to live in a
        -- real text box — that's the next lesson.
        local rowW = (#menu.options - 1) * menu.spacing + ICON
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(labelFont)
        love.graphics.printf(menu.options[menu.cursor],
            pos.x, pos.y + ICON + 16, rowW, "center")
    end
    love.graphics.setColor(1, 1, 1)
end

return MenuRenderSystem
