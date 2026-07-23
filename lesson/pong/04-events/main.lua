----------------------------------------------------------------------
-- Architecture 4/6: EVENT-DRIVEN — "don't call us, we'll call you"
--
-- Where does behavior live?  In SUBSCRIBERS.
--
-- The simulation only DETECTS things and announces them on a bus:
-- "the ball hit a paddle", "the ball went out on the left". Everything
-- that REACTS — bouncing, scoring, serving, ending the match, screen
-- flash — is a handler registered somewhere. The ball does not know
-- scoring exists. Scoring does not know what a ball is.
--
-- The payoff: look at the "juice" section at the bottom — screen
-- flash and a console beep, added WITHOUT touching the simulation.
-- This is why every real engine has an event layer (Godot signals,
-- Unity's UnityEvent/C# events, Unreal delegates).
--
-- The catch: control flow is now invisible. Try answering "what
-- happens when the ball goes out?" by reading top to bottom — you
-- can't. You have to grep for subscribers. One point scored here is a
-- CHAIN: ball:out -> match:point -> (serve OR match:over).
----------------------------------------------------------------------

------------------------------------------------------------ the bus
local Bus = { handlers = {} }

function Bus.on(eventName, handler)
    local list = Bus.handlers[eventName] or {}
    Bus.handlers[eventName] = list
    list[#list + 1] = handler
end

function Bus.emit(eventName, payload)
    for _, handler in ipairs(Bus.handlers[eventName] or {}) do
        handler(payload)
    end
end

-------------------------------------------------------- world state
-- Plain data. Nothing here has behavior; behavior is in the handlers.
local leftPaddle = { x = 30, y = 230, w = 12, h = 80, up = "w", down = "s" }
local rightPaddle = { x = 918, y = 230, w = 12, h = 80, up = "up", down = "down" }
local ball = { x = 474, y = 264, w = 12, h = 12, vx = 0, vy = 0 }
local match = { left = 0, right = 0, state = "play" }
local flash = { time = 0 } -- juice: filled by a subscriber, see bottom

local function overlaps(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w
       and a.y < b.y + b.h and b.y < a.y + a.h
end

------------------------------------------- simulation: DETECT only
-- This loop moves things and reports facts. It decides nothing.
function love.update(dt)
    if match.state ~= "play" then return end

    for _, paddle in ipairs({ leftPaddle, rightPaddle }) do
        if love.keyboard.isDown(paddle.up) then paddle.y = paddle.y - 360 * dt end
        if love.keyboard.isDown(paddle.down) then paddle.y = paddle.y + 360 * dt end
        paddle.y = math.max(0, math.min(540 - paddle.h, paddle.y))
    end

    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    if ball.y < 0 or ball.y > 540 - ball.h then
        Bus.emit("ball:wall")
    end
    for _, paddle in ipairs({ leftPaddle, rightPaddle }) do
        if (ball.vx < 0) == (paddle.x < ball.x) and overlaps(ball, paddle) then
            Bus.emit("ball:paddle", paddle)
        end
    end
    if ball.x < -ball.w then Bus.emit("ball:out", "left") end
    if ball.x > 960 then Bus.emit("ball:out", "right") end

    flash.time = math.max(0, flash.time - dt)
end

--------------------------------------------- handlers: REACT here
-- All game rules live below this line, as reactions.

Bus.on("serve", function(direction)
    ball.x, ball.y = 474, 264
    ball.vx = 320 * direction
    ball.vy = 120 * (love.math.random() * 2 - 1)
end)

Bus.on("ball:wall", function()
    ball.y = math.max(0, math.min(540 - ball.h, ball.y))
    ball.vy = -ball.vy
end)

Bus.on("ball:paddle", function(paddle)
    ball.vx = -ball.vx * 1.06
    ball.vy = ((ball.y + ball.h / 2) - (paddle.y + paddle.h / 2))
              / (paddle.h / 2) * 240
    if ball.vx > 0 then ball.x = paddle.x + paddle.w
    else ball.x = paddle.x - ball.w end
end)

Bus.on("ball:out", function(side)
    -- react to a fact by announcing a decision: chains are normal here
    if side == "left" then match.right = match.right + 1
    else match.left = match.left + 1 end
    Bus.emit("match:point", side)
end)

Bus.on("match:point", function(side)
    if match.left >= 5 or match.right >= 5 then
        Bus.emit("match:over")
    else
        Bus.emit("serve", side == "left" and -1 or 1)
    end
end)

Bus.on("match:over", function()
    match.state = "gameover"
end)

------------------------------------------------ juice subscribers
-- Added later, touching NOTHING above. This is the whole pitch.

Bus.on("ball:paddle", function()
    flash.time = 0.08
end)

Bus.on("match:point", function()
    print("beep! score is now " .. match.left .. " - " .. match.right)
end)

------------------------------------------------------------- love
function love.load()
    Bus.emit("serve", 1)
end

function love.draw()
    if flash.time > 0 then
        love.graphics.setColor(0.25, 0.25, 0.25)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.rectangle("fill", leftPaddle.x, leftPaddle.y, 12, 80)
    love.graphics.rectangle("fill", rightPaddle.x, rightPaddle.y, 12, 80)
    love.graphics.rectangle("fill", ball.x, ball.y, 12, 12)

    love.graphics.print(match.left, 400, 20, 0, 2, 2)
    love.graphics.print(match.right, 540, 20, 0, 2, 2)

    if match.state == "gameover" then
        love.graphics.printf("GAME OVER — SPACE to restart",
            0, 250, 480, "center", 0, 2, 2)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" and match.state == "gameover" then
        match.left, match.right, match.state = 0, 0, "play"
        Bus.emit("serve", 1)
    end
end
