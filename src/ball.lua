-- The ball: moves with a velocity, bounces off the top/bottom walls and
-- off paddles, and speeds up a little on every paddle hit.

local Ball = {}
Ball.__index = Ball

local START_SPEED = 280
local SPEEDUP = 1.06 -- 6% faster on every paddle hit
local SIZE = 14

function Ball.new()
    local self = setmetatable({}, Ball)
    self.w, self.h = SIZE, SIZE
    self:reset(1)
    return self
end

-- Put the ball at the center, serving toward `direction` (1 = right, -1 = left).
function Ball:reset(direction)
    self.x = (SCREEN_W - self.w) / 2
    self.y = (SCREEN_H - self.h) / 2
    self.vx = START_SPEED * direction
    -- random vertical angle so serves aren't identical
    self.vy = START_SPEED * (love.math.random() - 0.5)
end

-- Axis-Aligned Bounding Box collision: two rectangles overlap unless one
-- is completely to the left of / above the other.
local function aabb(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w
       and a.y < b.y + b.h and b.y < a.y + a.h
end

function Ball:update(dt, paddles)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- bounce off top and bottom walls
    if self.y < 0 then
        self.y = 0
        self.vy = -self.vy
    elseif self.y + self.h > SCREEN_H then
        self.y = SCREEN_H - self.h
        self.vy = -self.vy
    end

    for _, paddle in ipairs(paddles) do
        if aabb(self, paddle) then
            -- push the ball out of the paddle so it can't get stuck inside
            if self.vx > 0 then
                self.x = paddle.x - self.w
            else
                self.x = paddle.x + paddle.w
            end

            -- reflect, speed up, and add "english": hitting near the paddle's
            -- edge sends the ball at a steeper angle
            local paddleCenter = paddle.y + paddle.h / 2
            local ballCenter = self.y + self.h / 2
            local offset = (ballCenter - paddleCenter) / (paddle.h / 2) -- -1 .. 1

            local speed = math.abs(self.vx) * SPEEDUP
            self.vx = self.vx > 0 and -speed or speed
            self.vy = self.vy + offset * speed * 0.75
        end
    end
end

function Ball:draw()
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Ball
