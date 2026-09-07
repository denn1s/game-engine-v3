-- The mouse becomes PAINT INTENT. This is the same split as
-- MapInputSystem -> MovementSystem, on a different organ:
--
--   hover, dragging   (continuous state) -> poll the pointer
--   clear             (discrete action)  -> read a keyPressed event
--
-- An input system only fills the resource; it never touches the grid.
-- TileLabPaintSystem spends what this writes. Keeping the halves apart
-- is what lets the class point at two systems and say "input stops
-- here, world changes start there."
--
-- It reads Mouse, not love.mouse. Mouse hands back GAME coordinates —
-- identical to love.mouse in the plain game, but corrected for the
-- editor's viewport. A system that hardcoded the device number would
-- silently know, and be wrong, the moment the game is watched.

local Mouse = require("src.Mouse")

local TileLabInputSystem = { name = "tileLabInput" }

function TileLabInputSystem.update(scene, dt)
    local registry = scene.registry
    local lab = registry:resource("tileLab")
    local _, tilemap = registry:first("tilemap")

    -- continuous: where is the pointer, and is a button down? The cell
    -- under the cursor is derived from geometry, clamped to the grid so
    -- a stray pointer in the margin simply hovers nothing. `over` is
    -- false when the editor's mouse is over a panel, not the game.
    local mx, my, over = Mouse.position()
    local gx, gy = mx - tilemap.ox, my - tilemap.oy
    local cx = math.floor(gx / tilemap.cell) + 1
    local cy = math.floor(gy / tilemap.cell) + 1
    lab.hovering = over
        and cx >= 1 and cx <= tilemap.cols
        and cy >= 1 and cy <= tilemap.rows
    if lab.hovering then
        lab.hoverX, lab.hoverY = cx, cy
    end

    -- Buttons are STATE too ("am I dragging?"), not events: painting
    -- wants to continue every frame the button is held, exactly like
    -- walking. LÖVE numbers buttons 1=left, 2=right. Only paint while the
    -- pointer is actually over the game (over implies nothing else does).
    lab.painting = lab.hovering and over and love.mouse.isDown(1)
    lab.erasing = lab.hovering and over and love.mouse.isDown(2)

    -- discrete: one key, one meaning, event-read. It only SETS the flag;
    -- honoring it (mutating the grid) is the paint system's job.
    for _, event in registry:each("keyPressed") do
        if event.key == "c" then
            lab.clearRequested = true
        end
    end
end

return TileLabInputSystem
