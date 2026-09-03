package.path = "./?.lua;" .. package.path

local Easing = require("src.anim.Easing")
local Tween = require("src.anim.Tween")
local SpriteClip = require("src.anim.SpriteClip")

local function near(a, b)
    return math.abs(a - b) < 1e-9
end

-- Easing curves are promises about the endpoints. The middle is
-- taste; the ends are law.
for name, curve in pairs(Easing) do
    assert(near(curve(0), 0), name .. " does not start at 0")
    assert(near(curve(1), 1), name .. " does not end at 1")
end

-- A tween arrives when it says it arrives, no matter the curve.
local trip = Tween.new(90, 520, 2.0, Easing.outBack)
assert(near(Tween.at(trip, 0), 90), "tween moved before time started")
assert(near(Tween.at(trip, 1.0), 90 + 430 * Easing.outBack(0.5)), "tween ignored the curve")
assert(near(Tween.at(trip, 2.0), 520), "tween missed its arrival")
assert(near(Tween.at(trip, 99), 520), "tween drifted after arriving")
local plain = Tween.new(90, 520, 2.0, Easing.outQuad)
assert(plain and Tween.at(plain, 1.0) > 90 and Tween.at(plain, 1.0) < 520,
    "tween stood still mid-trip")
assert(Tween.at(trip, 1.5) > 520, "outBack should overshoot past the target mid-trip")
assert(pcall(Tween.new, 0, 1, 0) == false, "zero duration should fail loudly")

-- The clock -> frame conversion: N frames spread over D seconds,
-- in order, looping, and never leaving the strip.
local clip = SpriteClip.new(4, 1.0)
assert(near(SpriteClip.fps(clip), 4), "fps is not frames over seconds")
local seen = {}
for _, t in ipairs({ 0, 0.25, 0.5, 0.75 }) do
    local frame = SpriteClip.frameAt(clip, t)
    seen[frame] = true
    assert(frame == math.floor(t * 4) + 1, "frame is not the slot of the second")
end
for frame = 1, 4 do
    assert(seen[frame], "a frame never showed in one full loop")
end
assert(SpriteClip.frameAt(clip, 1.0) == 1, "clip did not loop")
assert(SpriteClip.frameAt(clip, 137.31) >= 1 and SpriteClip.frameAt(clip, 137.31) <= 4,
    "frame escaped the strip")
assert(SpriteClip.frameAt(SpriteClip.new(2, 0.4), 0.2) == 2, "quarter-speed clip miscounted")

print("animation tests passed -- same clock, same frame, always arrives")
