-- Owns the lab's mode and everything it means to change mode: which
-- demo is on screen (the `animLab` resource), the sheet cursor in demo
-- 1, clip durations in demo 2, and the restart of every clock.
--
-- Note what this system does NOT do: it never advances time and never
-- draws. Intent in, data mutated, done.

local ImageManager = require("src.graphics.ImageManager")

local LabSelectionSystem = { name = "labSelection" }

local function clamp(value, lo, hi)
    if value < lo then return lo end
    if value > hi then return hi end
    return value
end

function LabSelectionSystem.setup(scene)
    scene.registry:setResource("animLab", { demo = 1 })
end

function LabSelectionSystem.update(scene, dt)
    local registry = scene.registry
    local lab = registry:resource("animLab")

    for _, intent in registry:each("labIntent") do
        if intent.action == "select" then
            lab.demo = intent.demo
        end
    end

    -- one restart covers both animation kinds: clip and tween clocks
    -- are just accumulated seconds.
    local restart = false
    for _, intent in registry:each("labIntent") do
        if intent.action == "reset" or intent.action == "select" then
            restart = true
        end
    end
    if restart then
        for _, clipAnim in registry:each("clipAnim") do
            clipAnim.t = 0
        end
        for _, tweenAnim in registry:each("tweenAnim") do
            tweenAnim.t = 0
        end
    end

    for _, intent in registry:each("labIntent") do
        if intent.action == "browse" and lab.demo == 1 then
            local cursor = registry:first("browse")
            local sprite = registry:get(cursor, "sprite")
            local sheet = ImageManager.sheet(sprite.path, sprite.w, sprite.h)
            if intent.direction == "left" then
                sprite.frame = clamp(sprite.frame - 1, 1, sheet.cols)
            elseif intent.direction == "right" then
                sprite.frame = clamp(sprite.frame + 1, 1, sheet.cols)
            elseif intent.direction == "up" then
                sprite.row = clamp(sprite.row - 1, 1, sheet.rows)
            elseif intent.direction == "down" then
                sprite.row = clamp(sprite.row + 1, 1, sheet.rows)
            end
        elseif intent.action == "retune" and lab.demo == 2 then
            for entity, clipAnim, demo in registry:each("clipAnim", "demo") do
                if demo.n == lab.demo then
                    clipAnim.clip.duration = clamp(clipAnim.clip.duration + intent.delta, 0.1, 3.0)
                end
            end
        end
    end
end

return LabSelectionSystem
