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
-- Started with `--debug`, the overlay goes one step further and becomes
-- an EDITOR, Unity-style: the OS window grows, the game renders into a
-- fixed-size canvas, and that canvas is shown in a viewport window with
-- the tool panels around it (see enterEditor).
--
--   F1   show/hide the tool panels (the viewport is the game — it stays)
--   F9   pause the game (the UI keeps running — that's the point)
--   F10  advance exactly one frame while paused

local imlove = require("lib.imlove")
local Game = require("src.Game") -- for the scene switcher only
local Screen = require("src.Screen") -- the game's resolution, one source
local serialize = require("src.state.serialize") -- for the dump modal

local DebugOverlay = {}

local visible = false
local paused = false
local stepOnce = false

local editor = false -- --debug: game-in-a-viewport (see enterEditor)
local gameCanvas = nil -- the game's render target while in editor mode

-- The editor's backdrop, deliberately NOT black: the game keeps black
-- (the canvas clears to it, see beginGameDraw), so the viewport reads
-- as "the game", visibly distinct from the editor around it.
local EDITOR_BG = { 0.16, 0.16, 0.18 }

local selectedEntity = nil
local inspectedComponent = 1 -- Combo index into the entity's components
local inspectedScene = nil -- to drop the selection when the scene changes

local FRAME_HISTORY = 120 -- two seconds' worth at 60fps
local frameTimes = {} -- rolling window of dt, in milliseconds
local displayedFPS = 0 -- frozen while paused, like everything else

-- The overlay's font: LÖVE's default (Vera Sans) for text, with Noto
-- Sans Symbols 2 chained BEHIND it via LÖVE's font fallbacks — glyphs
-- Vera lacks (the transport bar's ▶ ⏸ ⏭) fall through and resolve
-- there instead of rendering as tofu boxes. Lazy: fonts want a window,
-- so this runs on the first frame, not at require time.
local fontInstalled = false
local function installFont()
    if fontInstalled then return end
    fontInstalled = true
    local ui = love.graphics.newFont(13)
    ui:setFallbacks(love.graphics.newFont(
        "lib/fonts/NotoSansSymbols2-Regular.ttf", 13))
    imlove.io.FontDefault = ui
end

-- How deep the field editor follows nested tables before it gives up.
-- Plain data cannot contain a cycle — but the inspector reads EVERY
-- component, and nothing enforces the plain-data rule outside the save
-- file. A tool that hangs the game on the one bad component you were
-- trying to look at is not a tool.
local MAX_DEPTH = 4

-- pairs() order is unstable, and a panel whose rows reshuffle every
-- frame is unreadable. Numbers sort first and numerically (an array
-- reads 1, 2, 3 — not 1, 10, 2), strings alphabetically after them;
-- plain data has no other kind of key.
local function sortedKeys(data)
    local keys = {}
    for key in pairs(data) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) == "number"
    end)
    return keys
end

-- One row per field: numbers and booleans get a live widget, nested
-- tables recurse under a TreeNode, anything else prints as text.
--
-- The recursion is what makes RunState inspectable at all: `stats` is a
-- table inside a table, and an editor that stops at the first level can
-- only tell you that a table exists. Ctrl+click a slider to type an
-- exact value — that's how you set Int to 20 without playing eight
-- weeks of the game first.
local function fieldEditor(data, depth)
    for _, key in ipairs(sortedKeys(data)) do
        local value, label = data[key], tostring(key)
        if type(value) == "number" then
            data[key] = imlove.SliderFloat(label, value, -960, 960)
        elseif type(value) == "boolean" then
            data[key] = imlove.Checkbox(label, value)
        elseif type(value) == "table" then
            if depth >= MAX_DEPTH then
                imlove.Text("%s: ...", label)
            -- an open TreeNode pushes its label onto the ID stack, so
            -- two nested tables that share a key name (`stats.int` and
            -- `collection[1].int`) never collide on widget state
            elseif imlove.TreeNode(label) then
                fieldEditor(value, depth + 1)
                imlove.TreePop()
            end
        else
            imlove.Text("%s: %s", label, tostring(value))
        end
    end
end

-- The dump modal: a component printed the way the SAVE FILE would write
-- it, by reusing the game's own serializer. The tree above is for poking
-- one value; this is for reading a whole shape at once (a 50-card
-- collection is not a thing you inspect one TreeNode at a time).
--
-- It also doubles as a PLAIN-DATA LINTER. serialize.encode errors on
-- anything that can't be written down as Lua source, so pointing this at
-- a component holding a font or a canvas prints the reason instead of
-- the data — the rule from lesson 05 stops being a promise students have
-- to take on faith and becomes something the tool tells them.
local DUMP_TITLE = "component dump"
local dumpText = nil -- a SNAPSHOT, taken when the button is pressed

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

    if imlove.Button("dump") then
        -- pcall: a linter REPORTS that a component isn't plain data. It
        -- does not crash the tool that just found out.
        local ok, result = pcall(serialize.encode, data)
        dumpText = ("-- %s\n%s"):format(name,
            ok and result or ("-- cannot serialize: " .. tostring(result)))
        imlove.OpenPopup(DUMP_TITLE)
    end
    if imlove.BeginPopupModal(DUMP_TITLE) then
        -- fixed box, not auto-fit: a modal sized to its content would
        -- grow taller than the screen by week three
        if imlove.BeginChild("dump", 520, 300, true) then
            imlove.Text(dumpText or "")
        end
        imlove.EndChild()
        if imlove.Button("close") then
            dumpText = nil
            imlove.CloseCurrentPopup()
        end
        imlove.EndPopup()
    end

    fieldEditor(data, 1)
end

local function buildUi(scene)
    -- snapped to the left edge, full height ("once": drag it free if you
    -- want a floating window — the layout is a default, not a law)
    imlove.SetNextWindowSnap("left", "once")
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
-- be moved — it's furniture, not a document window. The glyphs render
-- thanks to the Noto Symbols fallback font (see installFont).
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
    -- re-centered every frame, like the viewport: the bar can't be
    -- dragged (NoTitleBar), so a saved position could only ever be a
    -- stale one — from an ini written when the window was another size
    imlove.SetNextWindowPos(love.graphics.getWidth() / 2 - 62, 10)
    if imlove.Begin("transport", nil, { "NoTitleBar", "AlwaysAutoResize" }) then
        if transportButton("▶", not paused, true) then -- play = unpause
            paused = false
        end
        imlove.SameLine()
        if transportButton("⏸", paused, true) then
            paused = true
        end
        imlove.SameLine()
        if transportButton("⏭", false, paused) then -- step: only paused
            stepOnce = true
        end
    end
    imlove.End()
end

-- The Engine panel, snapped to the right edge (the Inspector owns the
-- left). The split is by SUBJECT: the Inspector looks at DATA — the
-- entities of one scene — while this panel drives the ENGINE: which
-- scene runs, which systems run. The width is set explicitly; a snapped
-- window keeps it while the edge pins its height.
local function buildEnginePanel(scene)
    imlove.SetNextWindowSize(230, 330, "once")
    imlove.SetNextWindowSnap("right", "once")
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

-- The game viewport: the canvas the game just rendered, framed by a
-- window with no title bar and re-centered every frame — furniture,
-- like the transport bar, not a document window. Note what it ISN'T:
-- there is no special "draw the game here" machinery. The game already
-- landed in a texture, and a texture in a window is one Image() call.
local function buildGameViewport()
    local sw, sh = love.graphics.getDimensions()
    local gw, gh = gameCanvas:getDimensions()
    local pad = imlove.GetStyle().windowPadding
    imlove.SetNextWindowPos((sw - gw) / 2 - pad, (sh - gh) / 2 - pad)
    if imlove.Begin("viewport", nil, { "NoTitleBar", "AlwaysAutoResize" }) then
        imlove.Image(gameCanvas)
    end
    imlove.End()
end

function DebugOverlay.toggle()
    visible = not visible
end

-- Editor mode, entered once at startup (there is no way back — quit and
-- relaunch without --debug): the OS window grows by half, the game gets
-- a canvas at the resolution conf.lua asked for, and from then on it
-- renders in there (see beginGameDraw), never noticing that the "screen"
-- it fills is a texture inside a bigger window. Unity's Game view works
-- exactly like this: the editor is a big app, the game draws into a
-- render target, and a panel displays it.
function DebugOverlay.enterEditor()
    -- the window is sized by what has to FIT, not by a multiplier of
    -- the game: the centered viewport plus a gutter per side wide
    -- enough for the panels (Engine is 230 + window chrome), and
    -- headroom above/below for the transport bar. A multiplier broke
    -- the day the game's resolution changed under it (960×540 → the
    -- GDD's 640×400) and the panels no longer fit beside the viewport.
    local gutter, headroom = 280, 100
    love.window.setMode(Screen.w + 2 * gutter, Screen.h + 2 * headroom)
    gameCanvas = love.graphics.newCanvas(Screen.w, Screen.h)
    love.graphics.setBackgroundColor(EDITOR_BG)
    -- the editor keeps its OWN layout file: window positions saved in a
    -- 1440-wide editor make no sense in the 960-wide plain game (and
    -- vice versa), so the two modes must never share one ini.
    imlove.io.IniFilename = "imlove-editor.ini"
    editor = true
    visible = true
end

-- Bracket the game's draw (see main.lua). In editor mode the game
-- renders into the canvas, cleared to black — inside its viewport the
-- game still owns the black. Outside editor mode both are no-ops and
-- the game draws straight to the screen, exactly as before.
function DebugOverlay.beginGameDraw()
    if not editor then return end
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(0, 0, 0, 1)
end

function DebugOverlay.endGameDraw()
    if not editor then return end
    love.graphics.setCanvas()
end

-- Call at the top of love.update, BEFORE the game updates: the UI reads
-- and edits the state the previous frame produced.
function DebugOverlay.beginFrame(scene)
    installFont()
    imlove.NewFrame()

    if scene ~= inspectedScene then -- entity numbers reset with the registry
        inspectedScene = scene
        selectedEntity = nil
        inspectedComponent = 1
    end

    -- the viewport is NOT gated on `visible`: in editor mode it IS the
    -- game. F1 hides the tools around it, never the game itself. Built
    -- first, so the panels stack in front of it if they ever overlap.
    if editor then
        buildGameViewport()
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
