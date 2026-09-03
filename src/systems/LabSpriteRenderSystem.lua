-- Draws every visible `sprite`: image + quad + scale, nothing else.
-- The frame number in the component is not its problem — some other
-- system (or the player's arrow keys) decided it; this one just
-- resolves path -> cached sheet -> quad and blits.
--
-- The demo-specific overlays (the thumbnail, the formula readouts)
-- ride along because they annotate THIS drawing; the math they quote
-- is the same math SpriteSheet/clipAnim already performed.

local ImageManager = require("src.graphics.ImageManager")

local LabSpriteRenderSystem = { name = "labSpriteRender" }

local cream = { 0.94, 0.89, 0.76 }
local faint = { 0.94, 0.89, 0.76, 0.5 }

local smallFont

function LabSpriteRenderSystem.setup(scene)
    smallFont = love.graphics.newFont(10)
end

function LabSpriteRenderSystem.unload(scene)
    smallFont = nil
end

local function drawEntity(pos, sprite)
    local sheet = ImageManager.sheet(sprite.path, sprite.w, sprite.h)
    love.graphics.draw(sheet.image, sheet:quad(sprite.frame, sprite.row),
        pos.x, pos.y, 0, sprite.scale, sprite.scale)
end

function LabSpriteRenderSystem.draw(scene)
    if not smallFont then return end
    local registry = scene.registry
    local lab = registry:resource("animLab")

    for _, pos, sprite, demo in registry:each("position", "sprite", "demo") do
        if demo.n == lab.demo then
            drawEntity(pos, sprite)
        end
    end

    love.graphics.setFont(smallFont)
    if lab.demo == 1 then
        local sheet = ImageManager.sheet("assets/lab_walk.png", 32, 32)
        local cursor = registry:first("browse")
        local sprite = registry:get(cursor, "sprite")

        -- the sheet whole, then the one cell it just cut out: the QUAD.
        -- native scale — nearest filtering only stays crisp at integer zooms
        local thumbX, thumbY, thumbScale = 430, 120, 1
        love.graphics.setColor(cream)
        love.graphics.draw(sheet.image, thumbX, thumbY, 0, thumbScale, thumbScale)
        local cx, cy, cw, ch = sheet:cellRect(sprite.frame, sprite.row)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line",
            thumbX + cx * thumbScale - 1, thumbY + cy * thumbScale - 1,
            cw * thumbScale + 2, ch * thumbScale + 2)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(faint)
        love.graphics.print("rows = anims, columns = frames", thumbX, thumbY + 136)
        love.graphics.setColor(cream)
        love.graphics.print(("quad: x=(frame-1)*32=%3d  y=(row-1)*32=%3d  w=32 h=32")
            :format((sprite.frame - 1) * 32, (sprite.row - 1) * 32), 90, 320)
    elseif lab.demo == 2 then
        love.graphics.setColor(cream)
        for _, sprite, anim, demo in registry:each("sprite", "clipAnim", "demo") do
            if demo.n == 2 then
                love.graphics.print(("frame = floor(t / %.1fs x %d) %% %d + 1 = %d   t=%.2fs   %.1f fps")
                    :format(anim.clip.duration, anim.clip.frames, anim.clip.frames,
                        sprite.frame, anim.t % anim.clip.duration, anim.fps or 0),
                    90, 330)
                break
            end
        end
    elseif lab.demo == 3 then
        love.graphics.setColor(cream)
        for _, pos, sprite, anim, demo in registry:each("position", "sprite", "clipAnim", "demo") do
            if demo.n == 3 then
                love.graphics.printf(("%.1fs  ->  %.0f fps"):format(anim.clip.duration, anim.fps or 0),
                    pos.x - 40, pos.y + sprite.h * sprite.scale + 8,
                    sprite.w * sprite.scale + 80, "center")
            end
        end
    end
end

return LabSpriteRenderSystem
