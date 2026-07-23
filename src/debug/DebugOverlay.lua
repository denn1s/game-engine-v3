-- The debug overlay: an entity inspector, a Unity-style transport bar
-- (play / pause / frame-step), a scene switcher, and live system on/off
-- toggles, built on imlove (lib/imlove.lua — vendored; see the lesson
-- README).
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
local Game = require("src.Game") -- for the scene switcher only

local DebugOverlay = {}

local visible = false
local paused = false
local stepOnce = false

local selectedEntity = nil
local inspectedComponent = 1 -- Combo index into the entity's components
local inspectedScene = nil -- to drop the selection when the scene changes

local FRAME_HISTORY = 120 -- two seconds' worth at 60fps
local frameTimes = {} -- rolling window of dt, in milliseconds
local displayedFPS = 0 -- frozen while paused, like everything else

-- One Combo picks WHICH component to edit, and only that one is drawn.
-- With a tree per component the editor grows with the entity; with a
-- Combo it stays one dropdown tall no matter how many components the
-- dating sim will pile on.
local function componentEditor(registry, entity)
    local names = registry:componentsOf(entity)
    if inspectedComponent > #names then
        inspectedComponent = 1 -- the entity changed shape under us
    end
    inspectedComponent = imlove.Combo("component", inspectedComponent, names)

    local name = names[inspectedComponent]
    if not name then return end
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
end

local function buildUi(scene)
    imlove.SetNextWindowPos(10, 10, "once")
    if imlove.Begin("Inspector") then
        -- every section is a CollapsingHeader (not TreeNode: headers are
        -- for a panel's top-level sections — full-width bar, no indent —
        -- tree nodes are for nesting INSIDE content, same convention as
        -- Dear ImGui). All default open; fold what you don't need.
        if imlove.CollapsingHeader("frame", true) then
            imlove.Text("FPS: %d", displayedFPS)

            -- frame TIME, not just FPS: FPS is an average, and averages
            -- hide spikes — one 50ms hitch among fifty smooth frames
            -- barely moves the number, but the player felt it. The scale
            -- is pinned at 0-33ms so the graph itself teaches the
            -- budget: 60fps means staying under 16.7ms, always.
            imlove.PlotLines("##frametime", frameTimes, 0, 33.3, 0, 40,
                ("%.1f ms"):format(frameTimes[#frameTimes] or 0))
        end

        local registry = scene.registry
        if imlove.CollapsingHeader("entities", true) then
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
                        inspectedComponent = 1 -- new entity, new dropdown
                    end
                    imlove.PopID()
                end
            end
            imlove.EndChild()
        end

        -- the selected entity may have been destroyed since last frame
        if selectedEntity and #registry:componentsOf(selectedEntity) == 0 then
            selectedEntity = nil
        end

        if selectedEntity then
            -- a STATIC label on purpose: imlove keys header state by the
            -- full label, so a dynamic "entity 7" would get fresh state
            -- per entity — and stale state when numbers recycle across
            -- scenes. The number is shown inside instead.
            if imlove.CollapsingHeader("selected entity", true) then
                imlove.Text("entity %d", selectedEntity)
                componentEditor(registry, selectedEntity)
            end
        end
    end
    imlove.End()
end

-- The transport bar: Unity-style play / pause / step in a tiny strip,
-- top-center. NoTitleBar also removes the drag region, so the bar can't
-- be moved — it's furniture, not a document window. The "icons" are
-- ASCII on purpose: imlove's font is LÖVE's default (Vera Sans), which
-- has no play/pause glyphs — real ▶/⏸ would render as tofu boxes.
local LIT = { 0.16, 0.53, 0.90, 1.00 } -- buttonActive blue: reads as "on"
local DIM = { 0.50, 0.50, 0.50, 1.00 } -- textDisabled gray

-- One transport button. `lit` tints it as the active state (exactly one
-- of play/pause is lit at any time); a disabled button draws dim and
-- swallows its clicks.
local function transportButton(label, lit, enabled)
    if lit then imlove.PushStyleColor("button", LIT) end
    if not enabled then imlove.PushStyleColor("text", DIM) end
    local clicked = imlove.Button(label, 28)
    if not enabled then imlove.PopStyleColor() end
    if lit then imlove.PopStyleColor() end
    return clicked and enabled
end

local function buildTransportBar()
    imlove.SetNextWindowPos(love.graphics.getWidth() / 2 - 62, 10, "once")
    if imlove.Begin("transport", nil, { "NoTitleBar", "AlwaysAutoResize" }) then
        if transportButton(">", not paused, true) then -- play = unpause
            paused = false
        end
        imlove.SameLine()
        if transportButton("||", paused, true) then
            paused = true
        end
        imlove.SameLine()
        if transportButton(">|", false, paused) then -- step: only paused
            stepOnce = true
        end
    end
    imlove.End()
end

-- The Engine panel, docked at the top-right (the Inspector owns the
-- top-left). The split is by SUBJECT: the Inspector looks at DATA — the
-- entities of one scene — while this panel drives the ENGINE: which
-- scene runs, which systems run. Fixed-size on purpose: when the dating
-- sim stacks up thirty systems, the list scrolls inside the panel
-- instead of growing down the whole screen.
local function buildEnginePanel(scene)
    imlove.SetNextWindowPos(love.graphics.getWidth() - 240, 10, "once")
    imlove.SetNextWindowSize(230, 330, "once")
    if imlove.Begin("Engine") then
        -- the switcher spawns the SAME switchRequest any system would —
        -- the tool has no special powers. Pressing the current scene's
        -- button rebuilds it fresh (factories!), so it doubles as a
        -- restart button. While paused the request just sits in the
        -- registry: Game.update is what honors it, on the next step.
        if imlove.CollapsingHeader("scenes", true) then
            imlove.Text("current: %s", scene.name)
            for i, name in ipairs(Game.sceneNames()) do
                if i > 1 then imlove.SameLine() end
                if imlove.Button(name) then
                    scene.registry:spawn({ switchRequest = { to = name } })
                end
            end
        end

        -- the checkbox list IS the frame order, top to bottom — and each
        -- one is a live experiment: switch a system off and watch the
        -- world keep running without it. The off-flag lives on the scene
        -- (see Scene.new), so a fresh scene always starts with all on.
        if imlove.CollapsingHeader("systems", true) then
            for _, system in ipairs(scene.systems) do
                local enabled = imlove.Checkbox(system.name or "(unnamed)",
                    not scene.disabledSystems[system])
                scene.disabledSystems[system] = (not enabled) or nil
            end
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

    if scene ~= inspectedScene then -- entity numbers reset with the registry
        inspectedScene = scene
        selectedEntity = nil
        inspectedComponent = 1
    end

    if visible then
        buildUi(scene)
        buildEnginePanel(scene)
        buildTransportBar()
    end
end

-- The pause gate: the game's update runs only when this says so. The
-- overlay itself is never gated — a paused game with a dead UI would be
-- useless. Hiding the overlay also lifts the pause: a game frozen by an
-- invisible tool is a bug report waiting to happen.
function DebugOverlay.shouldUpdate()
    local run
    if not (visible and paused) then
        run = true
    elseif stepOnce then
        stepOnce = false
        run = true
    else
        run = false
    end

    -- the FPS label and the frame-time plot sample HERE, not in
    -- beginFrame: this gate is the single source of truth for "a game
    -- frame is about to happen", so the numbers freeze with the world —
    -- watching them dance over a paused game reads as a bug — and every
    -- F10 step appends exactly one honest sample. (Relies on main.lua
    -- calling shouldUpdate once per frame, which is its contract.)
    if run then
        displayedFPS = love.timer.getFPS()
        frameTimes[#frameTimes + 1] = love.timer.getDelta() * 1000
        if #frameTimes > FRAME_HISTORY then
            table.remove(frameTimes, 1)
        end
    end
    return run
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
