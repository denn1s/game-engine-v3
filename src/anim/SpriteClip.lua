-- A clip is the other direction through the same problem: the asset
-- is frames, the design unit is SECONDS. "Four footsteps in 0.5s"
-- says it; fps is only ever derived (frames / duration), never
-- written down. Same logic as a video player's timecode: a frame
-- index is just a function of elapsed time.

local SpriteClip = {}

function SpriteClip.new(frameCount, duration)
    assert(frameCount > 0, "a clip needs at least one frame")
    assert(duration > 0, "a clip needs a positive duration")
    return { frames = frameCount, duration = duration }
end

function SpriteClip.fps(clip)
    return clip.frames / clip.duration
end

-- 1-based frame index at elapsed time t, looping forever.
function SpriteClip.frameAt(clip, t)
    local looped = t % clip.duration
    return math.floor(looped * SpriteClip.fps(clip)) % clip.frames + 1
end

return SpriteClip
