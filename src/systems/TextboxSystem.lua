-- The typewriter: reveals a textbox's text a few characters per second.
-- That one line of math is the entire system.
--
-- The textbox is PURE OUTPUT — it listens to nothing. It types its
-- line out and sits there until someone writes new text into the
-- component. The contract for that someone (the vignette, a battle,
-- anyone): set `text` AND reset `visibleChars` to 0, and the
-- typewriter starts over on its own. No play() call, no reset event —
-- changing the data IS the API.

local TextboxSystem = { name = "textbox" }

function TextboxSystem.update(scene, dt)
    for _, textbox in scene.registry:each("textbox") do
        textbox.visibleChars = math.min(
            textbox.visibleChars + textbox.speed * dt,
            #textbox.text)
    end
end

return TextboxSystem
