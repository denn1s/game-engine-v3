----------------------------------------------------------------------
-- Architecture 3/6: COMPONENT-BASED — "everything HAS-A" (Unity-style)
--
-- Where does behavior live?  In component OBJECTS attached to game
-- objects.
--
-- A GameObject is an empty shell with a position; you build behavior
-- by ADDING parts: a renderer, a mover, an input reader. No hierarchy
-- to fight — the PowerUp from last demo is just a new combination of
-- the same parts. This is Unity's GameObject/MonoBehaviour model.
--
-- IMPORTANT: this is NOT yet ECS. Three tells:
--   1. Components here have their own update() — they carry LOGIC.
--   2. Each object updates its own parts; there is no global view.
--   3. Components talk via getComponent() / findByTag() lookups.
--
-- The catch: logic that involves SEVERAL objects (collision, scoring,
-- match flow) has no natural home, so it ends up on an invisible
-- "GameManager" object — the empty-object-with-a-manager-script that
-- every Unity project on Earth contains. Find it at the bottom.
----------------------------------------------------------------------

------------------------------------------------------- GameObject
local GameObject = {}
GameObject.__index = GameObject

function GameObject.new(scene, tag, x, y, w, h)
    local self = setmetatable({
        scene = scene, tag = tag,
        x = x or 0, y = y or 0, w = w or 0, h = h or 0,
        components = {},
    }, GameObject)
    scene[#scene + 1] = self
    return self
end

function GameObject:addComponent(name, component)
    component.gameObject = self
    component.name = name
    self.components[#self.components + 1] = component
    return self -- chainable: object:addComponent(...):addComponent(...)
end

-- Unity's GetComponent<T>() — how components find their siblings
function GameObject:getComponent(name)
    for _, component in ipairs(self.components) do
        if component.name == name then return component end
    end
end

function GameObject:update(dt)
    for _, component in ipairs(self.components) do
        if component.update then component:update(dt) end
    end
end

function GameObject:draw()
    for _, component in ipairs(self.components) do
        if component.draw then component:draw() end
    end
end

-- Unity's FindObjectsWithTag — how components find OTHER objects
local function findByTag(scene, tag)
    local found = {}
    for _, gameObject in ipairs(scene) do
        if gameObject.tag == tag then found[#found + 1] = gameObject end
    end
    return found
end

------------------------------------------------------- components
-- Each component is a tiny class: data + its own behavior.

local function RectRenderer()
    return {
        draw = function(self)
            local go = self.gameObject
            love.graphics.rectangle("fill", go.x, go.y, go.w, go.h)
        end,
    }
end

local function KeyboardControl(upKey, downKey)
    return {
        update = function(self, dt)
            local go = self.gameObject
            if love.keyboard.isDown(upKey) then go.y = go.y - 360 * dt end
            if love.keyboard.isDown(downKey) then go.y = go.y + 360 * dt end
            go.y = math.max(0, math.min(540 - go.h, go.y))
        end,
    }
end

local function Motion(vx, vy)
    return {
        vx = vx, vy = vy,
        update = function(self, dt)
            self.gameObject.x = self.gameObject.x + self.vx * dt
            self.gameObject.y = self.gameObject.y + self.vy * dt
        end,
    }
end

local function BounceWalls()
    return {
        update = function(self)
            local go = self.gameObject
            -- needs its sibling: the classic getComponent dance
            local motion = go:getComponent("motion")
            if go.y < 0 then go.y, motion.vy = 0, -motion.vy end
            if go.y > 540 - go.h then
                go.y, motion.vy = 540 - go.h, -motion.vy
            end
        end,
    }
end

local function BallLogic()
    return {
        update = function(self)
            local go = self.gameObject
            local motion = go:getComponent("motion")

            -- cross-object logic: reach across the scene by tag
            for _, paddle in ipairs(findByTag(go.scene, "paddle")) do
                local movingAtIt = (motion.vx < 0) == (paddle.x < go.x)
                if movingAtIt
                    and go.x < paddle.x + paddle.w and paddle.x < go.x + go.w
                    and go.y < paddle.y + paddle.h and paddle.y < go.y + go.h
                then
                    motion.vx = -motion.vx * 1.06
                    motion.vy = ((go.y + go.h / 2) - (paddle.y + paddle.h / 2))
                                / (paddle.h / 2) * 240
                    if motion.vx > 0 then go.x = paddle.x + paddle.w
                    else go.x = paddle.x - go.w end
                end
            end

            -- out of bounds? tell the manager (someone has to keep score)
            if go.x < -go.w or go.x > 960 then
                local manager = findByTag(go.scene, "manager")[1]
                manager:getComponent("match"):pointScored(go.x < 0)
            end
        end,
    }
end

-- The infamous manager script: match flow has no object it belongs
-- to, so we invent an invisible object to hang it on.
local function MatchManager()
    return {
        left = 0, right = 0, state = "play",

        pointScored = function(self, rightScored)
            if rightScored then self.right = self.right + 1
            else self.left = self.left + 1 end

            if self.left >= 5 or self.right >= 5 then
                self.state = "gameover"
            else
                self:serve(rightScored and -1 or 1)
            end
        end,

        serve = function(self, direction)
            local ball = findByTag(self.gameObject.scene, "ball")[1]
            local motion = ball:getComponent("motion")
            ball.x, ball.y = 474, 264
            motion.vx = 320 * direction
            motion.vy = 120 * (love.math.random() * 2 - 1)
        end,

        draw = function(self)
            love.graphics.print(self.left, 400, 20, 0, 2, 2)
            love.graphics.print(self.right, 540, 20, 0, 2, 2)
            if self.state == "gameover" then
                love.graphics.printf("GAME OVER — SPACE to restart",
                    0, 250, 480, "center", 0, 2, 2)
            end
        end,
    }
end

------------------------------------------------------------- game
local scene, match

function love.load()
    scene = {}

    -- composition instead of classes: a paddle IS the sum of its parts
    GameObject.new(scene, "paddle", 30, 230, 12, 80)
        :addComponent("renderer", RectRenderer())
        :addComponent("control", KeyboardControl("w", "s"))

    GameObject.new(scene, "paddle", 918, 230, 12, 80)
        :addComponent("renderer", RectRenderer())
        :addComponent("control", KeyboardControl("up", "down"))

    GameObject.new(scene, "ball", 474, 264, 12, 12)
        :addComponent("renderer", RectRenderer())
        :addComponent("motion", Motion(320, 60))
        :addComponent("bounce", BounceWalls())
        :addComponent("ballLogic", BallLogic())

    local manager = GameObject.new(scene, "manager", 0, 0, 0, 0)
        :addComponent("match", MatchManager())
    match = manager:getComponent("match")
end

function love.update(dt)
    if match.state ~= "play" then return end
    for _, gameObject in ipairs(scene) do
        gameObject:update(dt)
    end
end

function love.draw()
    for _, gameObject in ipairs(scene) do
        gameObject:draw()
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" and match.state == "gameover" then
        match.left, match.right, match.state = 0, 0, "play"
        match:serve(1)
    end
end
