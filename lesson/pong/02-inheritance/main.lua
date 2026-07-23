----------------------------------------------------------------------
-- Architecture 2/6: OO INHERITANCE — "everything IS-A something"
--
-- Where does behavior live?  In the class of each object.
--
-- Objects own their data AND their behavior, and share code by
-- inheriting from a parent class. This was THE game architecture of
-- the late 90s / 2000s (early Unreal is a monument to it), and it maps
-- beautifully onto how we speak: a Ball IS A MovingEntity IS An Entity.
--
--     Entity                 x, y, w, h  — exists, can be drawn
--     └── MovingEntity       + vx, vy    — moves every frame
--         ├── Paddle         + reads keys, clamps to the court
--         └── Ball           + bounces off walls, speeds up
--
-- The catch: the hierarchy is a TREE, and abilities don't come in
-- trees. In class: where does a PowerUp that drifts like a Ball but
-- is steered like a Paddle go? You can only pick one parent.
-- (Also note below: ball-vs-paddle collision belongs to NEITHER
-- class, so it leaks back into love.update.)
----------------------------------------------------------------------

----------------------------------------------------------- Entity
local Entity = {}
Entity.__index = Entity

function Entity.new(x, y, w, h)
    return setmetatable({ x = x, y = y, w = w, h = h }, Entity)
end

function Entity:update(dt) end -- exists so main can update anything

function Entity:draw()
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

function Entity:overlaps(other)
    return self.x < other.x + other.w and other.x < self.x + self.w
       and self.y < other.y + other.h and other.y < self.y + self.h
end

----------------------------------------------------- MovingEntity
local MovingEntity = setmetatable({}, { __index = Entity })
MovingEntity.__index = MovingEntity

function MovingEntity.new(x, y, w, h, vx, vy)
    local self = Entity.new(x, y, w, h)
    self.vx, self.vy = vx or 0, vy or 0
    return setmetatable(self, MovingEntity)
end

function MovingEntity:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

----------------------------------------------------------- Paddle
local Paddle = setmetatable({}, { __index = MovingEntity })
Paddle.__index = Paddle

function Paddle.new(x, upKey, downKey)
    local self = MovingEntity.new(x, 230, 12, 80)
    self.upKey, self.downKey = upKey, downKey
    return setmetatable(self, Paddle)
end

function Paddle:update(dt)
    self.vy = 0
    if love.keyboard.isDown(self.upKey) then self.vy = -360 end
    if love.keyboard.isDown(self.downKey) then self.vy = 360 end
    MovingEntity.update(self, dt) -- the "super" call
    self.y = math.max(0, math.min(540 - self.h, self.y))
end

------------------------------------------------------------- Ball
local Ball = setmetatable({}, { __index = MovingEntity })
Ball.__index = Ball

function Ball.new()
    local self = MovingEntity.new(474, 264, 12, 12)
    return setmetatable(self, Ball)
end

function Ball:serve(direction)
    self.x, self.y = 474, 264
    self.vx = 320 * direction
    self.vy = 120 * (love.math.random() * 2 - 1)
end

function Ball:update(dt)
    MovingEntity.update(self, dt)
    if self.y < 0 then self.y, self.vy = 0, -self.vy end
    if self.y > 540 - self.h then self.y, self.vy = 540 - self.h, -self.vy end
end

function Ball:bounceOff(paddle)
    self.vx = -self.vx * 1.06
    self.vy = ((self.y + self.h / 2) - (paddle.y + paddle.h / 2))
              / (paddle.h / 2) * 240
    -- push out of the paddle so we don't collide twice
    if self.vx > 0 then self.x = paddle.x + paddle.w
    else self.x = paddle.x - self.w end
end

------------------------------------------------------------- game
local leftPaddle, rightPaddle, ball
local score, state

function love.load()
    leftPaddle = Paddle.new(30, "w", "s")
    rightPaddle = Paddle.new(918, "up", "down")
    ball = Ball.new()
    ball:serve(1)
    score = { left = 0, right = 0 }
    state = "play"
end

function love.update(dt)
    if state ~= "play" then return end

    leftPaddle:update(dt)
    rightPaddle:update(dt)
    ball:update(dt)

    -- Collision BETWEEN objects belongs to neither class. It lands
    -- here, in main — the first crack in "behavior lives in objects".
    if ball.vx < 0 and ball:overlaps(leftPaddle) then
        ball:bounceOff(leftPaddle)
    elseif ball.vx > 0 and ball:overlaps(rightPaddle) then
        ball:bounceOff(rightPaddle)
    end

    -- ...and so does scoring. Whose method would this be?
    if ball.x < -ball.w then
        score.right = score.right + 1
        if score.right >= 5 then state = "gameover" else ball:serve(-1) end
    elseif ball.x > 960 then
        score.left = score.left + 1
        if score.left >= 5 then state = "gameover" else ball:serve(1) end
    end
end

function love.draw()
    leftPaddle:draw()
    rightPaddle:draw()
    ball:draw()

    love.graphics.print(score.left, 400, 20, 0, 2, 2)
    love.graphics.print(score.right, 540, 20, 0, 2, 2)

    if state == "gameover" then
        love.graphics.printf("GAME OVER — SPACE to restart",
            0, 250, 480, "center", 0, 2, 2)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" and state == "gameover" then
        score.left, score.right, state = 0, 0, "play"
        ball:serve(1)
    end
end
