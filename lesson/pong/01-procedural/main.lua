----------------------------------------------------------------------
-- Architecture 1/6: PROCEDURAL — "just make it work"
--
-- Where does behavior live?  In the update loop. ALL of it.
--
-- The game is a bag of global variables mutated top to bottom by
-- love.update, once per frame. There is no architecture — and at this
-- size, that is honestly FINE. It's the fastest way to a working game,
-- you can read the whole frame like a recipe, and every variable is
-- one `print` away. Every game jam starts here.
--
-- The catch: nothing has a boundary, so nothing can grow. The state
-- of "a ball" is four loose globals; the *idea* of a ball exists only
-- in your head.
--
-- In class: ask "how do we add a SECOND ball?" and watch this file
-- resist you — there is no ball to make another of.
----------------------------------------------------------------------

function love.load()
    state = "play" -- "play" | "gameover"

    leftY, rightY = 230, 230 -- paddle tops (paddles are 12x80)
    leftScore, rightScore = 0, 0

    serve(1)
end

-- the one concession to structure: serving happens twice, so it's a
-- function. This is as far as procedural decomposition usually goes.
function serve(direction)
    ballX, ballY = 474, 264 -- ball is 12x12, this centers it
    ballVX = 320 * direction
    ballVY = 120 * (love.math.random() * 2 - 1)
end

function love.update(dt)
    if state ~= "play" then return end

    -- paddles: input and movement, inline
    if love.keyboard.isDown("w") then leftY = leftY - 360 * dt end
    if love.keyboard.isDown("s") then leftY = leftY + 360 * dt end
    if love.keyboard.isDown("up") then rightY = rightY - 360 * dt end
    if love.keyboard.isDown("down") then rightY = rightY + 360 * dt end
    leftY = math.max(0, math.min(460, leftY))
    rightY = math.max(0, math.min(460, rightY))

    -- ball: movement
    ballX = ballX + ballVX * dt
    ballY = ballY + ballVY * dt

    -- ball: bounce off top/bottom walls
    if ballY < 0 then ballY, ballVY = 0, -ballVY end
    if ballY > 528 then ballY, ballVY = 528, -ballVY end

    -- ball vs left paddle (AABB, written out longhand)
    if ballVX < 0 and ballX < 42 and ballX > 18
        and ballY + 12 > leftY and ballY < leftY + 80 then
        ballX = 42
        ballVX = -ballVX * 1.06
        ballVY = ((ballY + 6) - (leftY + 40)) / 40 * 240
    end

    -- ball vs right paddle (same thing again — copy, paste, flip)
    if ballVX > 0 and ballX + 12 > 918 and ballX < 942
        and ballY + 12 > rightY and ballY < rightY + 80 then
        ballX = 906
        ballVX = -ballVX * 1.06
        ballVY = ((ballY + 6) - (rightY + 40)) / 40 * 240
    end

    -- scoring
    if ballX < -12 then
        rightScore = rightScore + 1
        if rightScore >= 5 then state = "gameover" else serve(-1) end
    elseif ballX > 960 then
        leftScore = leftScore + 1
        if leftScore >= 5 then state = "gameover" else serve(1) end
    end
end

function love.draw()
    love.graphics.rectangle("fill", 30, leftY, 12, 80)
    love.graphics.rectangle("fill", 918, rightY, 12, 80)
    love.graphics.rectangle("fill", ballX, ballY, 12, 12)

    love.graphics.print(leftScore, 400, 20, 0, 2, 2)
    love.graphics.print(rightScore, 540, 20, 0, 2, 2)

    if state == "gameover" then
        love.graphics.printf("GAME OVER — SPACE to restart",
            0, 250, 480, "center", 0, 2, 2)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" and state == "gameover" then
        leftScore, rightScore, state = 0, 0, "play"
        serve(1)
    end
end
