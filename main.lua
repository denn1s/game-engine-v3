----------------------------------------------------------------------
-- Lesson 04.5 (optional): the editor window
--
-- `love . --debug` now opens a LARGER window with the game running
-- inside a viewport — the tool panels snapped to the sides — like
-- Unity's Game view. The trick is one primitive: the game renders into
-- a fixed-size Canvas (a texture), and the overlay shows that texture
-- inside a UI window. Plain `love .` is untouched: the game draws
-- straight to the screen and F1 summons the overlay from lesson 04.
--
-- The overlay is NOT part of the game. It sits next to the Game,
-- watching whatever scene is current; scenes never know it's there —
-- and now they don't even know whether the "screen" they draw to is
-- the real one or the editor's canvas.
--
-- Key presses still enter the world as DATA: the Game turns each one
-- into a `keyPressed` event entity in the current scene's registry
-- (see Game.keypressed) — unless the overlay consumed them first.
--
-- menu --SPACE--> play --someone wins--> gameover --SPACE--> menu
----------------------------------------------------------------------

local Game = require("src.Game")
local DebugOverlay = require("src.debug.DebugOverlay")

function love.load(args)
    Game.registerScene("menu", require("src.scenes.MenuScene"))
    Game.registerScene("play", require("src.scenes.PlayScene"))
    Game.registerScene("gameover", require("src.scenes.GameOverScene"))

    Game.start("menu")

    if args[1] == "--debug" then
        DebugOverlay.enterEditor()
    end
end

function love.update(dt)
    DebugOverlay.beginFrame(Game.current())
    if DebugOverlay.shouldUpdate() then -- the pause / frame-step gate
        Game.update(dt)
    end
end

function love.draw()
    DebugOverlay.beginGameDraw() -- editor mode: redirect into the canvas
    Game.draw()
    DebugOverlay.endGameDraw() -- back to the real screen
    DebugOverlay.draw() -- UI on top of everything (incl. the viewport)
end

function love.keypressed(key)
    if DebugOverlay.keypressed(key) then return end
    Game.keypressed(key)
end

-- The game has no mouse input yet, but the pattern is already the right
-- one: when the UI consumes an event, the game must never see it.
function love.mousepressed(x, y, button)
    if DebugOverlay.mousepressed(x, y, button) then return end
end

function love.textinput(text)
    if DebugOverlay.textinput(text) then return end
end

function love.mousereleased(x, y, button)
    if DebugOverlay.mousereleased(x, y, button) then return end
end

function love.wheelmoved(dx, dy)
    if DebugOverlay.wheelmoved(dx, dy) then return end
end

function love.quit()
    Game.quit()
end
