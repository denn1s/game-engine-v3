-- The Map — lesson 1 of 3: a sprite that MOVES.
--
-- Today the map is one floor and one character. No tiles, no walls, no
-- other places to be. Those are lessons 14 (tiles + autotiling) and 15
-- (collision + doors). Deliberately starting with just movement keeps
-- every system here answering exactly one question.
--
-- Look at how little this scene has to say. The story of the whole
-- lesson is a list of single-question systems and one entity:
--
--   MapInputSystem        held keys          -> moveIntent (raw -1/0/1)
--   MovementSystem        moveIntent         -> velocity, position
--   SpriteFacingSystem    moveIntent         -> sprite.row, playing (+ wrap)
--   SpriteAnimationSystem clipAnim + playing -> sprite.frame
--   MapBackgroundSystem   (floor)            -> behind everything
--   SpriteRenderSystem    position + sprite  -> the pixels
--   MapHudRenderSystem    (readouts/arrows)  -> on top
--
-- The entity that flows down that list is the same `sprite` component
-- the Animation Lab played with; we're just letting the player drive its
-- frame now instead of a clock on a demo wall. The lab paid off.

local Scene = require("src.ecs.Scene")
local Screen = require("src.Screen")
local SpriteClip = require("src.anim.SpriteClip")

local MapInputSystem = require("src.systems.MapInputSystem")
local MovementSystem = require("src.systems.MovementSystem")
local SpriteFacingSystem = require("src.systems.SpriteFacingSystem")
local SpriteAnimationSystem = require("src.systems.SpriteAnimationSystem")
local MapBackgroundSystem = require("src.systems.MapBackgroundSystem")
local SpriteRenderSystem = require("src.systems.SpriteRenderSystem")
local MapHudRenderSystem = require("src.systems.MapHudRenderSystem")

local SHEET = "assets/lab_walk.png"
local SCALE = 3

return function(payload)
    local scene = Scene.new("map")

    -- SCENE state (never saved): how fast the character walks and whether
    -- diagonals are normalized. `speed` is authored in px/sec on purpose
    -- — the first number in this game whose meaning is a real-world unit,
    -- which is exactly why dt matters. N toggles normalize live.
    scene.registry:setResource("map", {
        speed = 150,
        normalize = true,
    })

    -- THE player: one entity, plain data, no "Player" class. Every
    -- component is owned by a different system and read by another —
    -- that cross-wiring down the system list IS the architecture.
    local cell = 32 * SCALE
    scene.registry:spawn({
        position = { x = (Screen.w - cell) / 2, y = (Screen.h - cell) / 2 },
        moveIntent = { dx = 0, dy = 0 },   -- written by MapInputSystem
        velocity   = { x = 0, y = 0 },      -- written by MovementSystem (px/sec)
        sprite = {                          -- read by SpriteRenderSystem
            path = SHEET, w = 32, h = 32,
            frame = 1, row = 1,             -- down, standing (frame+row owned elsewhere)
            scale = SCALE,
        },
        clipAnim = {                         -- read by SpriteAnimationSystem
            clip = SpriteClip.new(4, 0.5),   -- four footsteps in half a second
            t = 0, playing = false, idle = 1,
        },
    })

    -- input, then intent spent, then the clock, then paint (floor, sprite,
    -- readouts). Draw-only and update-only systems share one list safely:
    -- Scene runs update() and draw() in two passes over the same order.
    scene:addSystem(MapInputSystem)
    scene:addSystem(MovementSystem)
    scene:addSystem(SpriteFacingSystem)
    scene:addSystem(SpriteAnimationSystem)
    scene:addSystem(MapBackgroundSystem)
    scene:addSystem(SpriteRenderSystem)
    scene:addSystem(MapHudRenderSystem)

    return scene
end
