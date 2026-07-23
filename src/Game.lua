-- The Game: owns the scenes and switches between them. There is exactly
-- one Game, so it's a plain module (require caches it), not a class.
--
-- Nobody calls a switch function directly. To change scenes, ANY system
-- spawns an event entity in its own registry:
--
--   registry:spawn({ switchRequest = { to = "gameover", payload = {...} } })
--
-- and the Game honors it AFTER the frame's update — never in the middle
-- of one, when the current scene's systems are still iterating the very
-- registry that a switch would destroy. Deferred transitions like this
-- are how real engines avoid that whole class of crashes.

local Game = {}

local factories = {} -- scene name -> function(payload) -> Scene
local current = nil

-- Scenes register a factory, not an instance: every entry builds the
-- scene fresh, so no stale state can survive a visit.
function Game.registerScene(name, factory)
    factories[name] = factory
end

local function performSwitch(name, payload)
    assert(factories[name], "unknown scene: " .. tostring(name))
    if current then
        current:unload()
    end
    current = factories[name](payload)
    current:setup()
end

function Game.start(name)
    performSwitch(name, nil)
end

function Game.update(dt)
    current:update(dt)

    -- key events are broadcasts: systems READ them, nobody destroys
    -- them. Their frame is over, so the Game — which spawned them —
    -- sweeps them now. Input lives for exactly one update.
    for _, entity in ipairs(current.registry:query("keyPressed")) do
        current.registry:destroy(entity)
    end

    -- the frame is over; now it's safe to honor a switch request
    local _, request = current.registry:first("switchRequest")
    if request then
        performSwitch(request.to, request.payload)
    end
end

function Game.draw()
    current:draw()
end

function Game.keypressed(key)
    if key == "escape" then -- quitting is a Game concern, not a scene's
        love.event.quit()
        return
    end
    -- everything else enters the world as DATA: a `keyPressed` event
    -- entity. LÖVE delivers key events BEFORE love.update, so every
    -- system sees it during this frame's update; Game.update sweeps it
    -- afterwards.
    current.registry:spawn({ keyPressed = { key = key } })
end

function Game.quit()
    if current then
        current:unload()
    end
end

-- Handy for tests and (soon) debug tooling.
function Game.current()
    return current
end

return Game
