-- Draws every entity that carries `position` + `sprite`. This is the
-- lab's LabSpriteRenderSystem, promoted: the version that belongs to the
-- ENGINE, not to one throwaway demo. It is the render half of the
-- promise the Animation Lab made — a sprite is (image, quad, scale) and
-- nothing else.
--
-- It has exactly one job and it is emphatically NOT animation. The
-- `frame` and `row` numbers in the component were chosen by someone
-- else (SpriteAnimationSystem picks the frame; MovementSystem picks the
-- row). This system resolves path -> cached sheet -> quad and blits.
-- It never reads dt, never advances a clock.
--
-- Because it is generic, every future scene that shows a sprite — the
-- map, a battle, a portrait — reuses this one system unchanged. That is
-- the whole payoff for keeping systems atomic.

local ImageManager = require("src.graphics.ImageManager")

local SpriteRenderSystem = { name = "spriteRender" }

function SpriteRenderSystem.draw(scene)
    local registry = scene.registry

    for _, pos, sprite in registry:each("position", "sprite") do
        local sheet = ImageManager.sheet(sprite.path, sprite.w, sprite.h)
        local scale = sprite.scale or 1
        love.graphics.draw(sheet.image, sheet:quad(sprite.frame, sprite.row),
            pos.x, pos.y, 0, scale, scale)
    end
end

return SpriteRenderSystem
