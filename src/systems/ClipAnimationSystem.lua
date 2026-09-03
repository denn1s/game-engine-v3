-- The time -> frame converter. Every animated sprite entity carries a
-- `clipAnim` (a clip + accumulated seconds); this system is the ONLY
-- place in the engine that converts one to the other:
--
--   sprite.frame = SpriteClip.frameAt(clip, t)
--
-- which is `floor(t / duration * frames) % frames + 1` — "go through N
-- frames in D seconds". The renderer just draws whatever frame the
-- component says. Frame animation and property animation (tweens)
-- touch different components of the same entity and never talk.

local SpriteClip = require("src.anim.SpriteClip")

local ClipAnimationSystem = { name = "clipAnimation" }

function ClipAnimationSystem.update(scene, dt)
    local registry = scene.registry
    local lab = registry:resource("animLab")

    for _, sprite, anim, demo in registry:each("sprite", "clipAnim", "demo") do
        if demo.n == lab.demo then
            anim.t = anim.t + dt
            anim.fps = SpriteClip.fps(anim.clip) -- for the readout only
            sprite.frame = SpriteClip.frameAt(anim.clip, anim.t)
        end
    end
end

return ClipAnimationSystem
