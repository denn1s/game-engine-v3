-- The Map — lesson 2 of 3: a moving sprite gets a tile-based PLACE.
--
-- TileGrid stores what terrain exists. AutoTile derives how each terrain
-- cell looks from its neighbors. Collision and doors remain lesson 15.
--
-- Look at how little this scene has to say. The story of the whole
-- lesson is a list of single-question systems and one entity:
--
--   MapInputSystem        held keys          -> moveIntent (raw -1/0/1)
--   MovementSystem        moveIntent         -> velocity, position
--   SpriteFacingSystem    moveIntent         -> sprite.row, playing (+ wrap)
--   SpriteAnimationSystem clipAnim + playing -> sprite.frame
--   TilemapRenderSystem   terrain + neighbors -> floor tiles behind everything
--   SpriteRenderSystem    position + sprite  -> the pixels
--   MapHudRenderSystem    (readouts/arrows)  -> on top
--
-- The entity that flows down that list is the same `sprite` component
-- the Animation Lab played with; we're just letting the player drive its
-- frame now instead of a clock on a demo wall. The lab paid off.

local Scene = require("src.ecs.Scene")
local SpriteClip = require("src.anim.SpriteClip")
local MapData = require("src.data.map")

local MapInputSystem = require("src.systems.MapInputSystem")
local MovementSystem = require("src.systems.MovementSystem")
local SpriteFacingSystem = require("src.systems.SpriteFacingSystem")
local SpriteAnimationSystem = require("src.systems.SpriteAnimationSystem")
local TilemapRenderSystem = require("src.systems.TilemapRenderSystem")
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

    -- One tilemap entity, not one entity per cell. A tile is a position in a
    -- dense grid; it does not need an identity of its own.
    scene.registry:spawn({
        tilemap = {
            grid = MapData.build(),
            cell = 32,
            ox = 0,
            oy = 0,
        },
    })

    -- THE player: one entity, plain data, no "Player" class. Every
    -- component is owned by a different system and read by another —
    -- that cross-wiring down the system list IS the architecture.
    scene.registry:spawn({
        -- Start over the upper-left lawn rather than the empty courtyard.
        position = { x = 64, y = 64 },
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
    scene:addSystem(TilemapRenderSystem)
    scene:addSystem(SpriteRenderSystem)
    scene:addSystem(MapHudRenderSystem)

    return scene
end
