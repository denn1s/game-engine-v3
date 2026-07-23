----------------------------------------------------------------------
-- Architecture 7: THE HYBRID — how real games actually ship
--
-- Part 1's verdict table had no all-green row: every paradigm is bad
-- at something. Real engines answer by MIXING them, each where it's
-- strong. This Pong uses three at once:
--
--   * ECS (arch 6)            simulates the court: paddles, balls,
--                             collisions. Bulk, uniform, composable.
--   * EVENTS (arch 4)         systems announce FACTS on a bus;
--                             score, juice and flow REACT to them.
--   * a STATE MACHINE         owns match flow: serve delay -> play
--     (plain explicit code!)  -> gameover. Sequential logic gets a
--                             sequential tool — no ECS costume.
--
-- Look for the [ECS] / [EVENT] / [FSM] tags below, and notice the
-- boundaries: systems detect and emit, handlers decide, the state
-- machine sequences. Nobody reaches into anybody else's insides.
--
-- Press B during play for extra balls (the ECS half still shrugs).
----------------------------------------------------------------------

--------------------------------------------------- [EVENT] the bus
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

------------------------------------------------ [ECS] the registry
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

------------------------------------------------- [ECS] the systems
-- Systems SIMULATE and DETECT. Note what's missing compared to demo
-- 06: no score, no gameover, no serving in here. Systems report facts
-- to the bus and get on with their frame.

local function spawnBall(direction)
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
                Bus.emit("ball:paddle") -- [EVENT] fact, not decision
            end
        end
    end
end

local function outOfBoundsSystem()
    for _, ballEntity in ipairs(registry.query("ball", "position")) do
        local position = registry.get(ballEntity, "position")
        local out = position.x < -12 and "left" or position.x > 960 and "right"
        if out then
            registry.destroy(ballEntity)
            Bus.emit("ball:out", out) -- [EVENT] who scores? not my job
        end
    end
end

local function renderSystem()
    for _, entity in ipairs(registry.query("position", "size")) do
        local position = registry.get(entity, "position")
        local size = registry.get(entity, "size")
        love.graphics.rectangle("fill", position.x, position.y, size.w, size.h)
    end
end

------------------------------------- [FSM] the match state machine
-- Sequential flow gets sequential code. Explicit states, explicit
-- transitions — you can read the whole match lifecycle right here.

local match = { left = 0, right = 0 }
local fsm = { state = nil, time = 0 }
local states = {}

function fsm.enter(name, ...)
    fsm.state, fsm.time = name, 0
    if states[name].enter then states[name].enter(...) end
end

states.serve = {
    enter = function(direction) states.serve.direction = direction end,
    update = function(dt)
        -- paddles stay live during the serve pause
        paddleControlSystem(dt); movementSystem(dt); clampSystem()
        if fsm.time > 0.8 then
            spawnBall(states.serve.direction)
            fsm.enter("play")
        end
    end,
    draw = function()
        love.graphics.printf("READY...", 0, 180, 480, "center", 0, 2, 2)
    end,
}

states.play = {
    update = function(dt)
        paddleControlSystem(dt)
        movementSystem(dt)
        clampSystem()
        bounceWallsSystem()
        paddleHitsSystem()
        outOfBoundsSystem()
    end,
}

states.gameover = {
    update = function(dt) end, -- world frozen; only SPACE gets us out
    draw = function()
        love.graphics.printf("GAME OVER — SPACE to restart",
            0, 250, 480, "center", 0, 2, 2)
    end,
}

------------------------------------------ [EVENT] the rule handlers
-- Facts come in, decisions go out. Note the flow decision is just a
-- state transition — the FSM and the bus meet in four lines.

Bus.on("ball:out", function(side)
    if side == "left" then match.right = match.right + 1
    else match.left = match.left + 1 end
    if match.left >= 5 or match.right >= 5 then
        fsm.enter("gameover")
    else
        fsm.enter("serve", side == "left" and -1 or 1)
    end
end)

-- juice, decoupled as always
local flash = { time = 0 }
Bus.on("ball:paddle", function() flash.time = 0.08 end)

------------------------------------------------------------- love
function love.load()
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
    fsm.enter("serve", 1)
end

function love.update(dt)
    fsm.time = fsm.time + dt
    flash.time = math.max(0, flash.time - dt)
    states[fsm.state].update(dt)
end

function love.draw()
    if flash.time > 0 then
        love.graphics.setColor(0.25, 0.25, 0.25)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
        love.graphics.setColor(1, 1, 1)
    end

    renderSystem()
    love.graphics.print(match.left, 400, 20, 0, 2, 2)
    love.graphics.print(match.right, 540, 20, 0, 2, 2)

    if states[fsm.state].draw then states[fsm.state].draw() end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "b" and fsm.state == "play" then
        spawnBall(love.math.random() < 0.5 and -1 or 1)
    elseif key == "space" and fsm.state == "gameover" then
        match.left, match.right = 0, 0
        fsm.enter("serve", 1)
    end
end
