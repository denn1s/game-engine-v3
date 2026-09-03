-- The lab's frame: background, tab bar, and what the current demo is
-- about. Pure observer — it mutates nothing.

local Screen = require("src.Screen")

local LabChromeRenderSystem = { name = "labChromeRender" }

local COLORS = {
    desk = { 0.055, 0.071, 0.115 },
    panel = { 0.086, 0.110, 0.164 },
    cream = { 0.94, 0.89, 0.76 },
    faint = { 0.94, 0.89, 0.76, 0.5 },
}

local DEMOS = {
    { tab = "1 SHEET", title = "ONE CELL OF THE SHEET",
      help = "arrows browse   row = which animation   column = which frame" },
    { tab = "2 TIMER", title = "SECONDS BECOME FRAMES",
      help = "[ ] change the clip's seconds   4 frames / Ds  ->  frame = floor(t/D x 4) % 4 + 1" },
    { tab = "3 CLIPS", title = "SAME FRAMES, DIFFERENT CLOCKS",
      help = "one clip each: the seconds are the whole difference" },
    { tab = "4 TWEEN", title = "A SQUARE CROSSES IN EXACTLY 2 SECONDS",
      help = "three curves, one duration   R restarts   they always land together" },
    { tab = "5 COMBO", title = "TWO SYSTEMS, ONE ENTITY",
      help = "the clip writes sprite.frame, the tween writes position.x   R restarts" },
}

local titleFont, smallFont

function LabChromeRenderSystem.setup(scene)
    titleFont = love.graphics.newFont(16)
    smallFont = love.graphics.newFont(10)
end

function LabChromeRenderSystem.unload(scene)
    titleFont, smallFont = nil, nil
end

function LabChromeRenderSystem.draw(scene)
    if not titleFont then return end
    local lab = scene.registry:resource("animLab")

    love.graphics.clear(COLORS.desk)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(COLORS.cream)
    love.graphics.print("ANIMATION LAB", 14, 12)

    -- tab bar
    love.graphics.setFont(smallFont)
    local x = 190
    for i, demo in ipairs(DEMOS) do
        local active = i == lab.demo
        if active then
            love.graphics.setColor(COLORS.panel)
            love.graphics.rectangle("fill", x - 6, 12, 92, 16)
            love.graphics.setColor(COLORS.cream)
        else
            love.graphics.setColor(COLORS.faint)
        end
        love.graphics.print(demo.tab, x, 16)
        x = x + 90
    end

    love.graphics.setColor(COLORS.cream[1], COLORS.cream[2], COLORS.cream[3], 0.18)
    love.graphics.line(14, 36, Screen.w - 14, 36)

    local current = DEMOS[lab.demo]
    love.graphics.setFont(titleFont)
    love.graphics.setColor(COLORS.cream)
    love.graphics.print(current.title, 90, 52)
    love.graphics.setFont(smallFont)
    love.graphics.setColor(COLORS.faint)
    love.graphics.print(current.help, 90, 74)

    love.graphics.print("R restart    ESC quit", 14, Screen.h - 16)
    love.graphics.setColor(1, 1, 1)
end

return LabChromeRenderSystem
