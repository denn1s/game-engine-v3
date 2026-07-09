-- A paddle: a rectangle the player moves up and down with two keys.
--
-- This module is a tiny Lua "class". Lua has no classes built in; the
-- idiom is a table of methods (Paddle) plus a metatable, so that
-- paddle:update(dt) finds `update` in Paddle via __index.

local Paddle = {}
Paddle.__index = Paddle

local SPEED = 320 -- pixels per second

function Paddle.new(x, y, upKey, downKey)
    local self = setmetatable({}, Paddle)
    self.x, self.y = x, y
    self.w, self.h = 14, 80
    self.upKey, self.downKey = upKey, downKey
    return self
end

function Paddle:update(dt)
    local dir = 0
    if love.keyboard.isDown(self.upKey) then dir = dir - 1 end
    if love.keyboard.isDown(self.downKey) then dir = dir + 1 end

    self.y = self.y + dir * SPEED * dt

    -- keep the paddle inside the window
    local screenH = love.graphics.getHeight()
    if self.y < 0 then self.y = 0 end
    if self.y + self.h > screenH then self.y = screenH - self.h end
end

function Paddle:draw()
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Paddle
