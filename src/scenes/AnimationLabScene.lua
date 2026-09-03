-- The Animation Lab: five demos of the same idea — an animation is a
-- pure function of elapsed seconds, and a SYSTEM spends dt feeding it
-- time. Sprites/sheets first (frames as data), tweens next (values as
-- curves), a combo at the end where both write one entity.
--
-- Nothing here touches the engine. It is scenes and systems like every
-- other branch; the lab exists to be a playground before the pack
-- reveal and the map walk cycle need these ideas for real.

local Scene = require("src.ecs.Scene")

local Easing = require("src.anim.Easing")
local Tween = require("src.anim.Tween")
local SpriteClip = require("src.anim.SpriteClip")

local LabInputSystem = require("src.systems.LabInputSystem")
local LabSelectionSystem = require("src.systems.LabSelectionSystem")
local TweenSystem = require("src.systems.TweenSystem")
local ClipAnimationSystem = require("src.systems.ClipAnimationSystem")
local LabChromeRenderSystem = require("src.systems.LabChromeRenderSystem")
local LabSpriteRenderSystem = require("src.systems.LabSpriteRenderSystem")
local LabLaneRenderSystem = require("src.systems.LabLaneRenderSystem")

local SHEET = "assets/lab_walk.png"

local function sprite(scale, row)
    return { path = SHEET, w = 32, h = 32, frame = 1, row = row or 1, scale = scale }
end

return function(payload)
    local scene = Scene.new("animLab")

    -- demo 1: one cell of the sheet, parked on the cursor entity
    scene.registry:spawn({
        position = { x = 90, y = 120 },
        sprite = sprite(5),
        browse = true, -- "arrows move THIS sprite"
        demo = { n = 1 },
    })

    -- demo 2: seconds -> frames, one clip playing
    scene.registry:spawn({
        position = { x = 200, y = 120 },
        sprite = sprite(5),
        clipAnim = { clip = SpriteClip.new(4, 1.2), t = 0 },
        demo = { n = 2 },
    })

    -- demo 3: the same four frames on three clocks
    for i, duration in ipairs({ 0.4, 0.8, 1.6 }) do
        scene.registry:spawn({
            position = { x = 80 + (i - 1) * 180, y = 110 },
            sprite = sprite(4, i),
            clipAnim = { clip = SpriteClip.new(4, duration), t = 0 },
            demo = { n = 3 },
        })
    end

    -- demo 4: one duration, three velocity curves
    local lanes = {
        { label = "linear", easing = Easing.linear, color = { 0.94, 0.89, 0.76 } },
        { label = "outQuad", easing = Easing.outQuad, color = { 0.25, 0.43, 1.0 } },
        { label = "outBack", easing = Easing.outBack, color = { 1.0, 0.31, 0.38 } },
    }
    for i, lane in ipairs(lanes) do
        scene.registry:spawn({
            position = { x = 90, y = 110 + (i - 1) * 60 },
            tweenAnim = {
                tween = Tween.new(90, 520, 2.0, lane.easing),
                t = 0, hold = 0.6,
                label = lane.label, color = lane.color,
            },
            demo = { n = 4 },
        })
    end

    -- demo 5: clip + tween on ONE entity. The tween owns position.x;
    -- the clip owns sprite.frame; neither knows the other is there.
    scene.registry:spawn({
        position = { x = 90, y = 150 },
        sprite = sprite(4),
        clipAnim = { clip = SpriteClip.new(4, 0.5), t = 0 },
        tweenAnim = { tween = Tween.new(90, 470, 2.5, Easing.outQuad), t = 0,
                      label = "outQuad walk" },
        demo = { n = 5 },
    })

    -- input, then intent applied, then the clocks, then paint
    scene:addSystem(LabInputSystem)
    scene:addSystem(LabSelectionSystem)
    scene:addSystem(TweenSystem)
    scene:addSystem(ClipAnimationSystem)
    scene:addSystem(LabChromeRenderSystem)
    scene:addSystem(LabSpriteRenderSystem)
    scene:addSystem(LabLaneRenderSystem)

    return scene
end
