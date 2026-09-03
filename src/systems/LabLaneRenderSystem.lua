-- The tweens made visible: a track line from start to finish, and the
-- square at the position TweenSystem computed. This system draws; it
-- does not sample — the value was written into `position` upstream.

local LabLaneRenderSystem = { name = "labLaneRender" }

local cream = { 0.94, 0.89, 0.76 }
local faint = { 0.94, 0.89, 0.76, 0.45 }

local smallFont

function LabLaneRenderSystem.setup(scene)
    smallFont = love.graphics.newFont(10)
end

function LabLaneRenderSystem.unload(scene)
    smallFont = nil
end

local function tick(x, y)
    love.graphics.line(x, y - 5, x, y + 5)
end

function LabLaneRenderSystem.draw(scene)
    if not smallFont then return end
    local registry = scene.registry
    local lab = registry:resource("animLab")

    love.graphics.setFont(smallFont)
    for _, pos, anim, demo in registry:each("position", "tweenAnim", "demo") do
        if demo.n == lab.demo then
            local tween = anim.tween
            local trackColor = anim.color or cream

            love.graphics.setColor(faint)
            love.graphics.line(tween.from, pos.y, tween.to, pos.y)
            love.graphics.setColor(trackColor)
            tick(tween.from, pos.y)
            tick(tween.to, pos.y)

            if demo.n == 4 then
                love.graphics.rectangle("fill", pos.x - 9, pos.y - 9, 18, 18)
            end

            love.graphics.setColor(cream)
            love.graphics.print(("%s  %.1fs trip"):format(anim.label or "", tween.duration),
                tween.from, pos.y - 24)
            love.graphics.printf(("t=%.2fs  p=%.2f  eased=%.2f"):format(
                math.min(anim.t, tween.duration + (anim.hold or 0)), anim.p or 0, anim.e or 0),
                tween.to - 130, pos.y + 10, 130, "right")
        end
    end
    love.graphics.setColor(1, 1, 1)
end

return LabLaneRenderSystem
