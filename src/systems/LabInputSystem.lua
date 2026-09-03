-- Keys become lab intent. Like every input system here it knows nothing
-- about what the intents DO: demo switching, cursor moves, retiming —
-- LabSelectionSystem owns all of that.

local LabInputSystem = { name = "labInput" }

local DEMO_KEYS = {
    ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5,
}

function LabInputSystem.update(scene, dt)
    local registry = scene.registry
    for _, event in registry:each("keyPressed") do
        local demo = DEMO_KEYS[event.key]
        if demo then
            registry:spawn({ event = true, labIntent = { action = "select", demo = demo } })
        elseif event.key == "r" then
            registry:spawn({ event = true, labIntent = { action = "reset" } })
        elseif event.key == "left" or event.key == "right"
            or event.key == "up" or event.key == "down" then
            registry:spawn({ event = true, labIntent = { action = "browse", direction = event.key } })
        elseif event.key == "[" then
            registry:spawn({ event = true, labIntent = { action = "retune", delta = -0.1 } })
        elseif event.key == "]" then
            registry:spawn({ event = true, labIntent = { action = "retune", delta = 0.1 } })
        end
    end
end

return LabInputSystem
