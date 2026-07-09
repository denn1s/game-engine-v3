-- The pong match itself: everything lesson 02 built, now packaged as a
-- scene factory. Every entry builds it fresh — a rematch is simply
-- "switch here again", and nothing from the previous match can survive.

local Scene = require("src.ecs.Scene")

local BallSpawnSystem = require("src.systems.BallSpawnSystem")
local PaddleControlSystem = require("src.systems.PaddleControlSystem")
local MovementSystem = require("src.systems.MovementSystem")
local ClampSystem = require("src.systems.ClampSystem")
local BounceWallsSystem = require("src.systems.BounceWallsSystem")
local PaddleHitsSystem = require("src.systems.PaddleHitsSystem")
local ScoringSystem = require("src.systems.ScoringSystem")
local WinCheckSystem = require("src.systems.WinCheckSystem")
local DebugSystem = require("src.systems.DebugSystem")
local RenderSystem = require("src.systems.RenderSystem")

return function(payload)
    local scene = Scene.new("play")

    -- system order IS the frame order: spawn -> input -> simulate ->
    -- resolve -> score -> decide -> draw
    scene:addSystem(BallSpawnSystem)
    scene:addSystem(PaddleControlSystem)
    scene:addSystem(MovementSystem)
    scene:addSystem(ClampSystem)
    scene:addSystem(BounceWallsSystem)
    scene:addSystem(PaddleHitsSystem)
    scene:addSystem(ScoringSystem)
    scene:addSystem(WinCheckSystem)
    scene:addSystem(DebugSystem)
    scene:addSystem(RenderSystem)

    return scene
end
