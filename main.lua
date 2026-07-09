----------------------------------------------------------------------
-- Lesson 01: Pong from scratch
--
-- Left player: W / S      Right player: UP / DOWN
-- SPACE serves the ball. First to WIN_SCORE wins.
----------------------------------------------------------------------

local Paddle = require("src.paddle")
local Ball = require("src.ball")

local WIN_SCORE = 5
local MARGIN = 30 -- distance from paddles to the side walls

-- The game is a tiny state machine:
--   "serve"    waiting for SPACE, ball frozen at center
--   "play"     ball in motion
--   "gameover" somebody reached WIN_SCORE
local state = "serve"
local serveDirection = 1

local leftPaddle, rightPaddle, paddles, ball
local score = { left = 0, right = 0 }
local bigFont, smallFont

function love.load()
    bigFont = love.graphics.newFont(48)
    smallFont = love.graphics.newFont(16)

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    leftPaddle = Paddle.new(MARGIN, (screenH - 80) / 2, "w", "s")
    rightPaddle = Paddle.new(screenW - MARGIN - 14, (screenH - 80) / 2, "up", "down")
    paddles = { leftPaddle, rightPaddle }

    ball = Ball.new()
end

function love.update(dt)
    -- paddles always respond, even while waiting to serve
    leftPaddle:update(dt)
    rightPaddle:update(dt)

    if state ~= "play" then return end

    ball:update(dt, paddles)

    -- a point is scored when the ball leaves the screen on either side
    local screenW = love.graphics.getWidth()
    if ball.x + ball.w < 0 then
        score.right = score.right + 1
        serveDirection = -1 -- loser receives the serve
        EndPoint()
    elseif ball.x > screenW then
        score.left = score.left + 1
        serveDirection = 1
        EndPoint()
    end
end

function EndPoint()
    ball:reset(serveDirection)
    if score.left >= WIN_SCORE or score.right >= WIN_SCORE then
        state = "gameover"
    else
        state = "serve"
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" then
        if state == "serve" then
            state = "play"
        elseif state == "gameover" then
            score.left, score.right = 0, 0
            ball:reset(serveDirection)
            state = "serve"
        end
    end
end

function love.draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- center line
    love.graphics.setColor(1, 1, 1, 0.35)
    for y = 0, screenH, 30 do
        love.graphics.rectangle("fill", screenW / 2 - 2, y, 4, 15)
    end
    love.graphics.setColor(1, 1, 1)

    -- score
    love.graphics.setFont(bigFont)
    love.graphics.printf(tostring(score.left), 0, 20, screenW / 2 - 40, "right")
    love.graphics.printf(tostring(score.right), screenW / 2 + 40, 20, screenW / 2 - 40, "left")

    leftPaddle:draw()
    rightPaddle:draw()
    ball:draw()

    love.graphics.setFont(smallFont)
    if state == "serve" then
        love.graphics.printf("SPACE to serve", 0, screenH - 40, screenW, "center")
    elseif state == "gameover" then
        local winner = score.left > score.right and "Left" or "Right"
        love.graphics.printf(winner .. " player wins! SPACE to play again",
            0, screenH - 40, screenW, "center")
    end
end
