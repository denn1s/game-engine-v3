-- The time -> frame converter for real scenes (the lab's
-- ClipAnimationSystem, promoted and stripped of every demo).
--
-- One promise from the Animation Lab, now with a twist:
--
--   a clip is a pure function of elapsed SECONDS
--   frame = floor(t / duration * frames) % frames + 1
--
-- The twist is the word "elapsed." Here the clock only accrues while the
-- entity is actually playing an animation. MovementSystem decides that
-- by setting a single boolean:
--
--   clipAnim.playing = true    -> we advance t and pick a walk frame
--   clipAnim.playing = false   -> we show the idle frame and rewind t to 0
--
-- Rewinding on stop means every new step starts on frame 1 (the plant),
-- not whatever mid-stride frame you stopped on — a tiny polish that is
-- invisible until you notice it.
--
-- Note the split this system embodies: it writes `frame`, MovementSystem
-- writes `row`. Two systems, one entity, one component, they never talk.
-- A walk cycle is (which strip) AND (which cell); we hand the two axes
-- of that pair to the two systems that actually know the answers.

local SpriteClip = require("src.anim.SpriteClip")

local SpriteAnimationSystem = { name = "spriteAnimation" }

function SpriteAnimationSystem.update(scene, dt)
    local registry = scene.registry

    for _, sprite, anim in registry:each("sprite", "clipAnim") do
        if anim.playing then
            anim.t = anim.t + dt
            sprite.frame = SpriteClip.frameAt(anim.clip, anim.t)
        else
            anim.t = 0
            sprite.frame = anim.idle or 1
        end
    end
end

return SpriteAnimationSystem
