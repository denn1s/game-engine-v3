-- attach(Game): wire the DebugOverlay into LÖVE by WRAPPING the
-- callbacks main.lua already defined. This file IS the UI integration —
-- all of it. main.lua bootstraps the game and never says how the
-- overlay hooks in; the Game never knows it's being watched; the
-- overlay never knows how it got installed. Self-installing tools are
-- the idiomatic LÖVE pattern (lovebird, lurker and lovedebug all work
-- exactly like this).
--
-- Two kinds of wrapping happen here:
--
--  * frame hooks: beginFrame before the game updates, the pause /
--    frame-step gate around love.update, the UI rendered after the
--    game draws so it sits on top.
--
--  * input hooks: every event the UI can consume goes to the overlay
--    FIRST and stops there when consumed. That's `WantCaptureMouse`
--    from real ImGui — without it, clicking a debug button would also
--    click whatever card sits under the cursor once the game goes
--    mouse-driven.
--
-- Call it from love.load: by then main.lua's chunk has run, so every
-- callback wrapped below already exists.

local DebugOverlay = require("src.debug.DebugOverlay")

-- Every LÖVE event the overlay may consume. Supporting a new one
-- (mousemoved, say) is one string here — plus a DebugOverlay handler of
-- the same name returning "did I consume it?".
local UI_EVENTS = {
    "keypressed",
    "textinput",
    "mousepressed",
    "mousereleased",
    "wheelmoved",
}

return function(game)
    local update = love.update
    love.update = function(dt)
        -- before the game: the UI reads and edits the state the
        -- previous frame produced
        DebugOverlay.beginFrame(game.current())
        if DebugOverlay.shouldUpdate() then -- the pause gate
            update(dt)
        end
    end

    local draw = love.draw
    love.draw = function()
        draw()
        DebugOverlay.draw() -- last: UI on top of everything
    end

    for _, event in ipairs(UI_EVENTS) do
        local original = love[event]
        love[event] = function(...)
            if DebugOverlay[event](...) then return end -- UI consumed it
            -- the game may not handle this event at all (no mouse yet)
            if original then original(...) end
        end
    end
end
