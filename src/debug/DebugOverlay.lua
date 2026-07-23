-- The debug overlay: an entity inspector with pause and frame-stepping,
-- built on imlove (lib/imlove.lua — vendored; see the lesson README).
--
-- This is ENGINE tooling, not game code. It is not a system and it does
-- not live in any scene: it sits next to the Game, inspecting whatever
-- scene is current, and it survives scene switches. Scenes never know
-- whether the inspector is watching them.
--
--   F1   show/hide the overlay
--   F9   pause the game (the UI keeps running — that's the point)
--   F10  advance exactly one frame while paused

local imlove = require("lib.imlove")

local DebugOverlay = {}

local visible = false
local paused = false
local stepOnce = false

local selectedEntity = nil
local inspectedScene = nil -- to drop the selection when the scene changes

local FRAME_HISTORY = 120 -- two seconds' worth at 60fps
local frameTimes = {} -- rolling window of dt, in milliseconds

local function componentEditor(registry, entity)
    for _, name in ipairs(registry:componentsOf(entity)) do
        if imlove.TreeNode(name) then
            local data = registry:get(entity, name)

            local keys = {} -- pairs() order is unstable; sort for a calm UI
            for k in pairs(data) do
                keys[#keys + 1] = k
            end
            table.sort(keys)

            for _, k in ipairs(keys) do
                local v = data[k]
                if type(v) == "number" then
                    data[k] = imlove.SliderFloat(k, v, -960, 960)
                elseif type(v) == "boolean" then
                    data[k] = imlove.Checkbox(k, v)
                else
                    imlove.Text("%s: %s", k, tostring(v))
                end
            end
            imlove.TreePop()
        end
    end
end

local function buildUi(scene)
    imlove.SetNextWindowPos(10, 10, "once")
    if imlove.Begin("Inspector") then
        imlove.Text("scene: %s    FPS: %d", scene.name, love.timer.getFPS())

        -- frame TIME, not just FPS: FPS is an average, and averages hide
        -- spikes — one 50ms hitch among fifty smooth frames barely moves
        -- the number, but the player felt it. The scale is pinned at
        -- 0-33ms so the graph itself teaches the budget: 60fps means
        -- staying under 16.7ms, always.
        imlove.PlotLines("##frametime", frameTimes, 0, 33.3, 0, 40,
            ("%.1f ms"):format(frameTimes[#frameTimes] or 0))

        paused = imlove.Checkbox("pause (F9)", paused)
        imlove.SameLine()
        if imlove.Button("step (F10)") then
            stepOnce = true
        end

        imlove.Separator()

        local registry = scene.registry
        if imlove.TreeNode("entities") then
            -- a fixed-height scrolling region: the list must stay usable
            -- when a scene holds hundreds of entities, not just pong's
            -- dozen. (BeginChild must ALWAYS be matched by EndChild,
            -- even when it reports itself as not visible.)
            if imlove.BeginChild("entityList", 0, 150, true) then
                for _, entity in ipairs(registry:entities()) do
                    imlove.PushID(entity)
                    local label = ("%d: %s"):format(entity,
                        table.concat(registry:componentsOf(entity), " "))
                    if imlove.Selectable(label, selectedEntity == entity) then
                        selectedEntity = entity
                    end
                    imlove.PopID()
                end
            end
            imlove.EndChild()
            imlove.TreePop()
        end

        -- the selected entity may have been destroyed since last frame
        if selectedEntity and #registry:componentsOf(selectedEntity) == 0 then
            selectedEntity = nil
        end

        if selectedEntity then
            imlove.Separator()
            imlove.Text("entity %d", selectedEntity)
            componentEditor(registry, selectedEntity)
        end
    end
    imlove.End()
end

function DebugOverlay.toggle()
    visible = not visible
end

-- Call at the top of love.update, BEFORE the game updates: the UI reads
-- and edits the state the previous frame produced.
function DebugOverlay.beginFrame(scene)
    imlove.NewFrame()

    -- sampled even while paused or hidden: the plot reports the real
    -- frame, tool cost included, and has history the moment you open it
    frameTimes[#frameTimes + 1] = love.timer.getDelta() * 1000
    if #frameTimes > FRAME_HISTORY then
        table.remove(frameTimes, 1)
    end

    if scene ~= inspectedScene then -- entity numbers reset with the registry
        inspectedScene = scene
        selectedEntity = nil
    end

    if visible then
        buildUi(scene)
    end
end

-- The pause gate: the game's update runs only when this says so. The
-- overlay itself is never gated — a paused game with a dead UI would be
-- useless. Hiding the overlay also lifts the pause: a game frozen by an
-- invisible tool is a bug report waiting to happen.
function DebugOverlay.shouldUpdate()
    if not (visible and paused) then
        return true
    end
    if stepOnce then
        stepOnce = false
        return true
    end
    return false
end

function DebugOverlay.draw()
    imlove.Render()
end

function DebugOverlay.keypressed(key)
    if key == "f1" then
        DebugOverlay.toggle()
        return true
    elseif key == "f9" and visible then
        paused = not paused
        return true
    elseif key == "f10" and visible then
        stepOnce = true
        return true
    end
    return imlove.keypressed(key)
end

function DebugOverlay.textinput(text)
    return imlove.textinput(text)
end

function DebugOverlay.mousepressed(x, y, button)
    return imlove.mousepressed(x, y, button)
end

function DebugOverlay.mousereleased(x, y, button)
    return imlove.mousereleased(x, y, button)
end

function DebugOverlay.wheelmoved(dx, dy)
    return imlove.wheelmoved(dx, dy)
end

return DebugOverlay
