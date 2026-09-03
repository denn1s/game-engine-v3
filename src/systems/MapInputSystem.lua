-- Keys become MOVEMENT INTENT. This is an input system, so it runs
-- FIRST and it is only allowed to fill components — never to move
-- anything. It writes the raw keys each entity with a `moveIntent` is
-- holding; MovementSystem spends that intent later this same frame.
--
-- This is the scene's one deliberate departure from the rest of the
-- engine, and the departure IS the lesson. Everywhere else, input is
-- DISCRETE: MenuInputSystem reads `keyPressed` event entities, because
-- a menu cursor steps once per press. Walking is not discrete — you
-- HOLD a key and keep moving while it's down. Event entities can't
-- carry "still down, still down, still down," so movement polls the
-- keyboard state each frame instead.
--
--   discrete action  (menu pick, confirm, jump)   -> keyPressed event
--   continuous state (walk, steer, aim)            -> love.keyboard.isDown
--
-- Real engines keep both: an action-mapping layer for the discrete
-- stuff, a raw device poll for the analog stuff. We're building the
-- raw poll by hand so the distinction is visible, not buried in a
-- framework.

local MapInputSystem = { name = "mapInput" }

local LEFT  = { "left", "a" }
local RIGHT = { "right", "d" }
local UP    = { "up", "w" }
local DOWN  = { "down", "s" }

local function anyDown(keys)
    for _, key in ipairs(keys) do
        if love.keyboard.isDown(key) then return true end
    end
    return false
end

function MapInputSystem.update(scene, dt)
    local registry = scene.registry

    -- One raw axis each, -1 / 0 / +1, straight from the device. Note we
    -- store BOTH axes: the player can press two at once, and resolving
    -- that (dominant axis, diagonal) is NOT the input system's job.
    local dx = (anyDown(RIGHT) and 1 or 0) - (anyDown(LEFT) and 1 or 0)
    local dy = (anyDown(DOWN) and 1 or 0) - (anyDown(UP) and 1 or 0)

    for _, intent in registry:each("moveIntent") do
        intent.dx = dx
        intent.dy = dy
    end

    -- The escape hatch: `n` toggles diagonal normalization on/off, so
    -- the room can feel the sqrt(2) bug instead of just being told about
    -- it. This is the ONLY thing here that reads discrete events, and
    -- it writes a resource, not a position — still within an input
    -- system's "produce intent, change nothing else" budget.
    for _, event in registry:each("keyPressed") do
        if event.key == "n" then
            local map = registry:resource("map")
            map.normalize = not map.normalize
        end
    end
end

return MapInputSystem
