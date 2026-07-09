----------------------------------------------------------------------
-- Lesson 02: Pong, rebuilt on an Entity-Component-System
--
-- Same game as lesson 01. New architecture, in layers:
--
--   Scene      one screen of the game; owns a Registry + ordered Systems
--   Registry   the DATA: components indexed by entity
--   Entity     just a number — a key into the registry, nothing more
--   System     the LOGIC: runs over entities that have certain components
--
-- Note main.lua doesn't create a single entity: every system spawns
-- what it owns in its setup(). main.lua only assembles the scene and
-- forwards LÖVE's callbacks.
--
-- W/S and UP/DOWN move the paddles. First to 5 wins.
-- Press B to spawn extra balls and watch every system handle them
-- with zero new code — that's the whole point of ECS.
----------------------------------------------------------------------

local Scene = require("src.ecs.Scene")

local BallSpawnSystem = require("src.systems.BallSpawnSystem")
local PaddleControlSystem = require("src.systems.PaddleControlSystem")
local MovementSystem = require("src.systems.MovementSystem")
local ClampSystem = require("src.systems.ClampSystem")
local BounceWallsSystem = require("src.systems.BounceWallsSystem")
local PaddleHitsSystem = require("src.systems.PaddleHitsSystem")
local ScoringSystem = require("src.systems.ScoringSystem")
local RenderSystem = require("src.systems.RenderSystem")

local scene

function love.load()
    scene = Scene.new("pong")

    -- system order IS the frame order: spawn -> input -> simulate ->
    -- resolve -> score -> draw
    scene:addSystem(BallSpawnSystem)
    scene:addSystem(PaddleControlSystem)
    scene:addSystem(MovementSystem)
    scene:addSystem(ClampSystem)
    scene:addSystem(BounceWallsSystem)
    scene:addSystem(PaddleHitsSystem)
    scene:addSystem(ScoringSystem)
    scene:addSystem(RenderSystem)

    scene:setup() -- each system creates what it owns
end

function love.update(dt)
    local _, match = scene.registry:first("match")
    if match.state == "play" then
        scene:update(dt)
    end
end

function love.draw()
    scene:draw()
end

function love.quit()
    scene:unload()
end

function love.keypressed(key)
    local registry = scene.registry
    local _, match = registry:first("match")

    if key == "escape" then
        love.event.quit()
    elseif key == "b" and match.state == "play" then
        registry:spawn({
            serveRequest = { direction = love.math.random() < 0.5 and -1 or 1 },
        })
    elseif key == "space" and match.state == "gameover" then
        match.left, match.right = 0, 0
        match.state = "play"
        -- clean the field: balls AND stale serve requests (a B press on
        -- the match's final frame could leave one behind)
        for _, ballEntity in ipairs(registry:query("ball")) do
            registry:destroy(ballEntity)
        end
        for _, requestEntity in ipairs(registry:query("serveRequest")) do
            registry:destroy(requestEntity)
        end
        registry:spawn({ serveRequest = { direction = 1 } })
    end
end
