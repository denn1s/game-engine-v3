----------------------------------------------------------------------
-- Architecture 5/6: SCENE GRAPH — "the game is a TREE" (Godot-style)
--
-- Where does behavior live?  In NODES, arranged in a tree.
--
-- Everything is a Node with a position RELATIVE to its parent.
-- update() and draw() walk the tree; each node adds its own transform
-- before its children draw. Move a parent, and its whole subtree
-- moves — that's transform propagation, and it's the superpower here.
--
-- Our tree tonight:
--
--   root
--   ├── court                <- shakes on every paddle hit: ONE number
--   │   ├── leftPaddle       <- moves; has a visual child
--   │   │   └── rect         (in Godot: Sprite2D + CollisionShape2D)
--   │   ├── rightPaddle
--   │   │   └── rect
--   │   └── ball
--   │       └── rect
--   └── ui                   <- NOT under court: doesn't shake
--       ├── leftScore
--       ├── rightScore
--       └── gameOverLabel
--
-- This is Godot's model (Node2D), Flash's display list, cocos2d.
-- Behavior = subclass a node and override process() — plus signals
-- (events, demo 4) for talking across branches.
--
-- The catch: siblings talking to each other need paths
-- (parent:get("leftPaddle") — Godot's get_node("../LeftPaddle")),
-- and data that ISN'T a thing on screen (the score! your Pokemon
-- party!) has no natural place in a tree of visible things.
----------------------------------------------------------------------

-------------------------------------------------------------- Node
local Node = {}
Node.__index = Node

function Node.new(name, x, y)
    return setmetatable({
        name = name, x = x or 0, y = y or 0,
        children = {}, byName = {}, parent = nil,
    }, Node)
end

function Node:add(child)
    child.parent = self
    self.children[#self.children + 1] = child
    self.byName[child.name] = child
    return child
end

function Node:get(name) -- Godot's get_node()
    return self.byName[name]
end

function Node:process(dt) end -- override me
function Node:render() end -- override me

function Node:update(dt)
    self:process(dt)
    for _, child in ipairs(self.children) do child:update(dt) end
end

function Node:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y) -- children inherit this
    self:render()
    for _, child in ipairs(self.children) do child:draw() end
    love.graphics.pop()
end

------------------------------------------------- node subclasses
local function subclass()
    local class = setmetatable({}, { __index = Node })
    class.__index = class
    return class
end

local RectNode = subclass()
function RectNode.new(w, h)
    local self = Node.new("rect", 0, 0)
    self.w, self.h = w, h
    return setmetatable(self, RectNode)
end
function RectNode:render()
    love.graphics.rectangle("fill", 0, 0, self.w, self.h)
end

local LabelNode = subclass()
function LabelNode.new(name, x, y, textFn)
    local self = Node.new(name, x, y)
    self.textFn = textFn -- called every frame: labels observe the game
    return setmetatable(self, LabelNode)
end
function LabelNode:render()
    love.graphics.print(self.textFn(), 0, 0, 0, 2, 2)
end

local PaddleNode = subclass()
function PaddleNode.new(name, x, upKey, downKey)
    local self = Node.new(name, x, 230)
    self.w, self.h = 12, 80 -- collision box (the RectNode is just looks)
    self.upKey, self.downKey = upKey, downKey
    self:add(RectNode.new(12, 80))
    return setmetatable(self, PaddleNode)
end
function PaddleNode:process(dt)
    if love.keyboard.isDown(self.upKey) then self.y = self.y - 360 * dt end
    if love.keyboard.isDown(self.downKey) then self.y = self.y + 360 * dt end
    self.y = math.max(0, math.min(540 - self.h, self.y))
end

-- the court: its ONLY behavior is shaking. Because every game object
-- is its child, offsetting these two numbers moves the entire world.
local CourtNode = subclass()
function CourtNode.new()
    local self = Node.new("court", 0, 0)
    self.shake = 0
    return setmetatable(self, CourtNode)
end
function CourtNode:process(dt)
    self.shake = math.max(0, self.shake - dt)
    if self.shake > 0 then
        self.x = love.math.random(-4, 4)
        self.y = love.math.random(-4, 4)
    else
        self.x, self.y = 0, 0
    end
end

local BallNode = subclass()
function BallNode.new(onOut)
    local self = Node.new("ball", 474, 264)
    self.w, self.h = 12, 12
    self.vx, self.vy = 0, 0
    self.onOut = onOut -- in Godot this would be a signal
    self:add(RectNode.new(12, 12))
    return setmetatable(self, BallNode)
end
function BallNode:serve(direction)
    self.x, self.y = 474, 264
    self.vx = 320 * direction
    self.vy = 120 * (love.math.random() * 2 - 1)
end
function BallNode:process(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    if self.y < 0 then self.y, self.vy = 0, -self.vy end
    if self.y > 540 - self.h then self.y, self.vy = 540 - self.h, -self.vy end

    -- talking to siblings: ask the parent, by name/path
    for _, name in ipairs({ "leftPaddle", "rightPaddle" }) do
        local paddle = self.parent:get(name)
        if (self.vx < 0) == (paddle.x < self.x)
            and self.x < paddle.x + paddle.w and paddle.x < self.x + self.w
            and self.y < paddle.y + paddle.h and paddle.y < self.y + self.h
        then
            self.vx = -self.vx * 1.06
            self.vy = ((self.y + self.h / 2) - (paddle.y + paddle.h / 2))
                      / (paddle.h / 2) * 240
            if self.vx > 0 then self.x = paddle.x + paddle.w
            else self.x = paddle.x - self.w end
            self.parent.shake = 0.15 -- the whole world flinches
        end
    end

    if self.x < -self.w then self.onOut("left") end
    if self.x > 960 then self.onOut("right") end
end

------------------------------------------------------------- game
local root, ball
-- Confession: the score is NOT in the tree. It isn't a thing on
-- screen (the labels just OBSERVE it). Godot solves this with
-- autoload singletons — global state smuggled back into a tree world.
local match = { left = 0, right = 0, state = "play" }

function love.load()
    root = Node.new("root", 0, 0)
    local court = root:add(CourtNode.new())

    court:add(PaddleNode.new("leftPaddle", 30, "w", "s"))
    court:add(PaddleNode.new("rightPaddle", 918, "up", "down"))

    ball = court:add(BallNode.new(function(side)
        if side == "left" then match.right = match.right + 1
        else match.left = match.left + 1 end
        if match.left >= 5 or match.right >= 5 then
            match.state = "gameover"
        else
            ball:serve(side == "left" and -1 or 1)
        end
    end))
    ball:serve(1)

    local ui = root:add(Node.new("ui", 0, 0))
    ui:add(LabelNode.new("leftScore", 400, 20, function()
        return match.left
    end))
    ui:add(LabelNode.new("rightScore", 540, 20, function()
        return match.right
    end))
    ui:add(LabelNode.new("gameOver", 240, 250, function()
        return match.state == "gameover" and "GAME OVER — SPACE to restart" or ""
    end))
end

function love.update(dt)
    if match.state ~= "play" then return end
    root:update(dt) -- one call walks the whole tree
end

function love.draw()
    root:draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" and match.state == "gameover" then
        match.left, match.right, match.state = 0, 0, "play"
        ball:serve(1)
    end
end
