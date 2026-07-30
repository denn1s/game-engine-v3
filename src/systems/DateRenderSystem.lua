-- Draws the date, upper-LEFT: the left column belongs to status (date
-- here, the stat triangle below it, next lesson) and the right to the
-- activity menu. Pure presentation over RunState — it owns no state,
-- so when the DayLoopSystem flips the day behind the fade, the new
-- date is simply what this system finds the next time it looks.

local DateRenderSystem = { name = "dateRender" }

local DAY_NAMES = { "MON", "TUE", "WED", "THU", "FRI" }

local dayFont, weekFont

function DateRenderSystem.setup(scene)
    dayFont = love.graphics.newFont(40)
    weekFont = love.graphics.newFont(14)
end

function DateRenderSystem.unload(scene)
    -- drop the references, the GC collects them; never release() fonts
    dayFont, weekFont = nil, nil
end

function DateRenderSystem.draw(scene)
    local runState = scene.registry:resource("runState")

    love.graphics.setFont(dayFont)
    love.graphics.printf(DAY_NAMES[runState.day] or "???",
        16, 16, 148, "left")

    love.graphics.setFont(weekFont)
    love.graphics.printf(("week %d"):format(runState.week),
        16, 60, 148, "left")
end

return DateRenderSystem
