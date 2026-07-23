----------------------------------------------------------------------
-- Architecture 6/6: ECS — "entities HAVE data, systems DO things"
--
-- Where does behavior live?  In SYSTEMS that run over DATA.
--
-- This looks like demo 3 (components) but flips who is in charge:
--   * Components are PLAIN DATA. No update(). No methods. Tables.
--   * An entity is just a NUMBER — a key into the component stores.
--   * All logic lives in systems: each one queries "every entity
--     with components X and Y" and processes them in bulk.
--
-- Demo 3 asked "what does THIS object do this frame?"
-- ECS asks "what does the MOVEMENT rule do to EVERYTHING, this frame?"
--
-- The payoff: press B during play. Extra balls, and every system
-- handles them with ZERO new code — movement moves them, walls bounce
-- them, paddles hit them, scoring scores them. Try that in demo 1.
--
-- This one-file version is a preview. Next lessons we build it
-- properly (Registry, Scene, one system per file) and you'll rebuild
-- your Breakout on it.
----------------------------------------------------------------------

---------------------------------------------------------- registry
-- One table per component TYPE, indexed by entity number.
local registry = { nextEntity = 1, components = {} }

function registry.spawn(components)
    local entity = registry.nextEntity
    registry.nextEntity = entity + 1
    for name, data in pairs(components) do
        local store = registry.components[name] or {}
        registry.components[name] = store
        store[entity] = data
    end
    return entity
end

function registry.get(entity, name)
    local store = registry.components[name]
    return store and store[entity]
end

function registry.destroy(entity)
    for _, store in pairs(registry.components) do
        store[entity] = nil
    end
end

-- every entity that has ALL the named components
function registry.query(...)
    local names, result = { ... }, {}
    for entity in pairs(registry.components[names[1]] or {}) do
        local ok = true
        for i = 2, #names do
            local store = registry.components[names[i]]
            if not store or store[entity] == nil then ok = false break end
        end
        if ok then result[#result + 1] = entity end
    end
    table.sort(result)
    return result
end

function registry.first(name) -- for singletons, like the match
    for entity, data in pairs(registry.components[name] or {}) do
        return entity, data
    end
end

----------------------------------------------------------- systems
-- Plain functions over queries. Note none of them mentions another:
-- they meet only through the data.

local function serveBall(direction)
    registry.spawn({
        position = { x = 474, y = 264 },
        size = { w = 12, h = 12 },
        velocity = { vx = 320 * direction,
                     vy = 120 * (love.math.random() * 2 - 1) },
        ball = {},
    })
end

local function paddleControlSystem(dt)
    for _, entity in ipairs(registry.query("paddle", "velocity")) do
        local paddle = registry.get(entity, "paddle")
        local velocity = registry.get(entity, "velocity")
        velocity.vy = 0
        if love.keyboard.isDown(paddle.upKey) then velocity.vy = -360 end
        if love.keyboard.isDown(paddle.downKey) then velocity.vy = 360 end
    end
end

-- moves ANYTHING with a position and velocity: paddles, balls, and
-- every entity you haven't invented yet
local function movementSystem(dt)
    for _, entity in ipairs(registry.query("position", "velocity")) do
        local position = registry.get(entity, "position")
        local velocity = registry.get(entity, "velocity")
        position.x = position.x + velocity.vx * dt
        position.y = position.y + velocity.vy * dt
    end
end

local function clampSystem()
    for _, entity in ipairs(registry.query("paddle", "position", "size")) do
        local position = registry.get(entity, "position")
        local size = registry.get(entity, "size")
        position.y = math.max(0, math.min(540 - size.h, position.y))
    end
end

local function bounceWallsSystem()
    for _, entity in ipairs(registry.query("ball", "position", "velocity")) do
        local position = registry.get(entity, "position")
        local velocity = registry.get(entity, "velocity")
        local size = registry.get(entity, "size")
        if position.y < 0 then position.y, velocity.vy = 0, -velocity.vy end
        if position.y > 540 - size.h then
            position.y, velocity.vy = 540 - size.h, -velocity.vy
        end
    end
end

local function paddleHitsSystem()
    for _, ballEntity in ipairs(registry.query("ball", "position", "velocity")) do
        local ballPos = registry.get(ballEntity, "position")
        local ballSize = registry.get(ballEntity, "size")
        local velocity = registry.get(ballEntity, "velocity")
        for _, paddleEntity in ipairs(registry.query("paddle", "position")) do
            local paddlePos = registry.get(paddleEntity, "position")
            local paddleSize = registry.get(paddleEntity, "size")
            if (velocity.vx < 0) == (paddlePos.x < ballPos.x)
                and ballPos.x < paddlePos.x + paddleSize.w
                and paddlePos.x < ballPos.x + ballSize.w
                and ballPos.y < paddlePos.y + paddleSize.h
                and paddlePos.y < ballPos.y + ballSize.h
            then
                velocity.vx = -velocity.vx * 1.06
                velocity.vy = ((ballPos.y + ballSize.h / 2)
                              - (paddlePos.y + paddleSize.h / 2))
                              / (paddleSize.h / 2) * 240
                if velocity.vx > 0 then
                    ballPos.x = paddlePos.x + paddleSize.w
                else
                    ballPos.x = paddlePos.x - ballSize.w
                end
            end
        end
    end
end

local function scoringSystem()
    local _, match = registry.first("match")
    for _, ballEntity in ipairs(registry.query("ball", "position")) do
        local position = registry.get(ballEntity, "position")
        local out = position.x < -12 and "left" or position.x > 960 and "right"
        if out then
            registry.destroy(ballEntity) -- nothing survives but data
            if out == "left" then match.right = match.right + 1
            else match.left = match.left + 1 end
            if match.left >= 5 or match.right >= 5 then
                match.state = "gameover"
            else
                serveBall(out == "left" and -1 or 1)
            end
        end
    end
end

local function renderSystem()
    for _, entity in ipairs(registry.query("position", "size")) do
        local position = registry.get(entity, "position")
        local size = registry.get(entity, "size")
        love.graphics.rectangle("fill", position.x, position.y, size.w, size.h)
    end

    local _, match = registry.first("match")
    love.graphics.print(match.left, 400, 20, 0, 2, 2)
    love.graphics.print(match.right, 540, 20, 0, 2, 2)
    if match.state == "gameover" then
        love.graphics.printf("GAME OVER — SPACE to restart",
            0, 250, 480, "center", 0, 2, 2)
    end
end

------------------------------------------------------------- game
function love.load()
    registry.spawn({ match = { left = 0, right = 0, state = "play" } })

    -- a paddle is not a class: it's this recipe of components
    registry.spawn({
        position = { x = 30, y = 230 }, size = { w = 12, h = 80 },
        velocity = { vx = 0, vy = 0 },
        paddle = { upKey = "w", downKey = "s" },
    })
    registry.spawn({
        position = { x = 918, y = 230 }, size = { w = 12, h = 80 },
        velocity = { vx = 0, vy = 0 },
        paddle = { upKey = "up", downKey = "down" },
    })


    registry.spawn({
        position = { x = 518, y = 230 }, size = { w = 12, h = 180 },
        paddle = { upKey = "u", downKey = "j" },
    })

    serveBall(1)
end

function love.update(dt)
    local _, match = registry.first("match")
    if match.state ~= "play" then return end

    -- system order IS the frame: input -> move -> resolve -> score
    paddleControlSystem(dt)
    movementSystem(dt)
    clampSystem()
    bounceWallsSystem()
    paddleHitsSystem()
end

function love.draw()
    renderSystem()
end

function love.keypressed(key)
    local _, match = registry.first("match")
    if key == "escape" then
        love.event.quit()
    elseif key == "b" and match.state == "play" then
        -- THE demo: a new ball is data. Every system just... handles it.
        serveBall(love.math.random() < 0.5 and -1 or 1)
    elseif key == "space" and match.state == "gameover" then
        match.left, match.right, match.state = 0, 0, "play"
        for _, ballEntity in ipairs(registry.query("ball")) do
            registry.destroy(ballEntity)
        end
        serveBall(1)
    end
end
