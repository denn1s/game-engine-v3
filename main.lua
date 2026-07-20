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
-- main.lua holds NO game logic: it assembles the scene and forwards
-- LÖVE's callbacks. Even a key press just becomes a tiny `keyPressed`
-- entity — the InputSystem consumes it and decides what it means.
--
-- W/S and UP/DOWN move the paddles. First to 5 wins.
-- Press B to spawn extra balls and watch every system handle them
-- with zero new code — that's the whole point of ECS.
----------------------------------------------------------------------

local Scene = require("src.ecs.Scene")

local InputSystem = require("src.systems.InputSystem")
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

    -- system order IS the frame order: input -> spawn -> control ->
    -- simulate -> resolve -> score -> draw
    scene:addSystem(InputSystem)
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
    -- always runs, even on the gameover screen: the InputSystem must
    -- still see keys there (SPACE restarts). Each simulation system
    -- guards itself with `if match.state ~= "play" then return end`.
    scene:update(dt)
end

function love.draw()
    scene:draw()
end

function love.quit()
    scene:unload()
end

function love.keypressed(key)
    scene.registry:spawn({ keyPressed = { key = key } })
end
