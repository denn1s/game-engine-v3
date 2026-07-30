-- Moves the menu cursor and announces picks. An input system: it only
-- mutates the menu component and spawns event entities, so it runs
-- FIRST in the scene (see the Scene comment on system order).
--
-- Note what it does NOT know: what the options mean, what happens when
-- one is picked, or even that this menu is about activities. On
-- confirm it spawns an `activityPicked` event entity and its job is
-- done — whoever cares (the vignette, the stats, one day the audio)
-- queries for the event on this same frame. The Game sweeps it after
-- the update, like every `event` entity.

local MenuInputSystem = { name = "menuInput" }

function MenuInputSystem.update(scene, dt)
    local registry = scene.registry

    -- the menu only listens while the day is CHOOSING: during the
    -- vignette and the fade it goes inert, so confirm can never pick
    -- twice. This guard is what makes one confirm key safe to share
    -- across every listener the scene will ever have.
    local day = registry:resource("dayloop")
    if day and day.phase ~= "choosing" then return end

    for _, event in registry:each("keyPressed") do
        for _, menu in registry:each("menu") do
            if event.key == "left" then
                -- -2/+1 instead of -1: Lua arrays are 1-based, % is 0-based
                menu.cursor = (menu.cursor - 2) % #menu.options + 1
            elseif event.key == "right" then
                menu.cursor = menu.cursor % #menu.options + 1
            elseif event.key == "return" or event.key == "space" then
                registry:spawn({
                    event = true,
                    activityPicked = { option = menu.options[menu.cursor] },
                })
            end
        end
    end
end

return MenuInputSystem
