-- Draws every textbox: a framed panel with the visible slice of its
-- text. Pure presentation — the typewriter's progress is a number in
-- the component; this system just substrings and paints.

local TextboxRenderSystem = { name = "textboxRender" }

local PAD = 10 -- inner padding, px

local font

function TextboxRenderSystem.setup(scene)
    font = love.graphics.newFont(14)
end

function TextboxRenderSystem.unload(scene)
    -- drop the reference, the GC collects it; never release() fonts
    font = nil
end

function TextboxRenderSystem.draw(scene)
    for _, pos, size, textbox in scene.registry:each(
        "position", "size", "textbox") do
        -- the panel: filled dark, thin light frame
        love.graphics.setColor(0.08, 0.08, 0.12, 0.9)
        love.graphics.rectangle("fill", pos.x, pos.y, size.w, size.h, 4, 4)
        love.graphics.setColor(0.8, 0.8, 0.85)
        love.graphics.rectangle("line", pos.x, pos.y, size.w, size.h, 4, 4)

        -- the visible slice. `visibleChars` counts BYTES, and sub() on
        -- a byte count can split a multi-byte character ("¿Qué…") into
        -- garbage — LÖVE would then refuse to draw the string. In
        -- UTF-8 every byte of a character after its first looks like
        -- 10xxxxxx (0x80-0xBF), so if the byte AFTER the cut is one of
        -- those, the cut landed mid-character: back up to the boundary.
        -- printf wraps long lines; watch a word JUMP to the next line
        -- as it finishes typing — that's wrapping recalculated per
        -- frame, and every typewriter ships with it anyway.
        local cut = math.floor(textbox.visibleChars)
        local function midChar(i)
            local b = textbox.text:byte(i + 1)
            return b and b >= 0x80 and b < 0xC0
        end
        while cut > 0 and midChar(cut) do
            cut = cut - 1
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(font)
        love.graphics.printf(textbox.text:sub(1, cut),
            pos.x + PAD, pos.y + PAD, size.w - 2 * PAD, "left")
    end
    love.graphics.setColor(1, 1, 1)
end

return TextboxRenderSystem
