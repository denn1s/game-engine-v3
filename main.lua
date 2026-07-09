----------------------------------------------------------------------
-- Lesson 00, part B: the same loop, but inside LÖVE.
--
-- In loop.lua WE wrote the while-loop. Here LÖVE runs it for us (it
-- lives in a function called love.run) and calls our functions at the
-- right stage of each frame:
--
--   init         -> love.load()
--   handleEvents -> love.keypressed() and friends
--   update       -> love.update(dt)
--   render       -> love.draw()
--
-- This demo shows WHY dt matters. Press SPACE to change the frame cap
-- and watch the two squares.
----------------------------------------------------------------------

local CAPS = { 0, 30, 60, 144 } -- 0 = uncapped
local capIndex = 1
local frameCap = CAPS[capIndex]

local SPEED = 150            -- pixels per SECOND (used with dt)
local PIXELS_PER_FRAME = 2.5 -- pixels per FRAME (no dt — on purpose!)

local goodSquare = { x = 0, y = 200 } -- moves with dt
local badSquare  = { x = 0, y = 330 } -- moves per frame

function love.load()
    love.graphics.setFont(love.graphics.newFont(16))
end

function love.update(dt)
    -- Frame-rate INDEPENDENT: same speed on every machine.
    goodSquare.x = goodSquare.x + SPEED * dt

    -- Frame-rate DEPENDENT: this square's speed changes with the FPS.
    -- This is the classic bug dt exists to prevent.
    badSquare.x = badSquare.x + PIXELS_PER_FRAME

    local w = love.graphics.getWidth()
    if goodSquare.x > w then goodSquare.x = -24 end
    if badSquare.x > w then badSquare.x = -24 end

    -- Crude frame cap: sleep away the time this frame didn't need.
    -- (Same idea as the busy-wait in loop.lua, but we can actually
    -- sleep — the engine's loop does this properly in love.run.)
    if frameCap > 0 and dt < 1 / frameCap then
        love.timer.sleep(1 / frameCap - dt)
    end
end

function love.draw()
    local capLabel = frameCap == 0 and "uncapped" or tostring(frameCap)
    love.graphics.print(("FPS: %d   |   cap: %s   |   SPACE: change cap, ESC: quit")
        :format(love.timer.getFPS(), capLabel), 10, 10)

    love.graphics.setColor(0.35, 0.9, 0.45)
    love.graphics.rectangle("fill", goodSquare.x, goodSquare.y, 24, 24)
    love.graphics.print("x = x + SPEED * dt   (frame-rate independent)", 10, 170)

    love.graphics.setColor(0.95, 0.4, 0.4)
    love.graphics.rectangle("fill", badSquare.x, badSquare.y, 24, 24)
    love.graphics.print("x = x + PIXELS_PER_FRAME   (depends on FPS — bug!)", 10, 300)

    love.graphics.setColor(1, 1, 1)
end

function love.keypressed(key)
    if key == "space" then
        capIndex = capIndex % #CAPS + 1
        frameCap = CAPS[capIndex]
    elseif key == "escape" then
        love.event.quit()
    end
end
