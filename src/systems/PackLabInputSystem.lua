-- Keyboard -> intent. This system does not generate or tune anything; it
-- announces requests so each reaction can remain one small, inspectable system.

local PackLabInputSystem = { name = "packLabInput" }

local function emit(registry, component, data)
    registry:spawn({ event = true, [component] = data or {} })
end

function PackLabInputSystem.update(scene, dt)
    local registry = scene.registry
    for _, event in registry:each("keyPressed") do
        local key = event.key
        if key == "p" then
            emit(registry, "packRequested")
        elseif key == "r" then
            emit(registry, "packReplayRequested")
        elseif key == "h" then
            emit(registry, "handRequested")
        elseif key == "c" then
            emit(registry, "collectionClearRequested")
        elseif key == "1" or key == "2" or key == "3" then
            emit(registry, "statPresetRequested", { preset = tonumber(key) })
        elseif key == "left" then
            emit(registry, "statSelectionRequested", { direction = -1 })
        elseif key == "right" then
            emit(registry, "statSelectionRequested", { direction = 1 })
        elseif key == "up" then
            emit(registry, "statAdjustmentRequested", { amount = 1 })
        elseif key == "down" then
            emit(registry, "statAdjustmentRequested", { amount = -1 })
        elseif key == "pageup" then
            emit(registry, "statAdjustmentRequested", { amount = 5 })
        elseif key == "pagedown" then
            emit(registry, "statAdjustmentRequested", { amount = -5 })
        end
    end
end

return PackLabInputSystem
