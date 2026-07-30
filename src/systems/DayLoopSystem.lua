-- The clock of the day: owns the `dayloop` resource and EVERY phase
-- transition. Other systems read the phase (the menu to know when to
-- listen, the fade to know what to draw) but only this system ever
-- writes it — smear a state machine's transitions across five files
-- and no one can say what state the day is in, or why.
--
--   choosing --activityPicked--> vignette --timer--> fade --timer--> choosing
--
-- The day advances at the fade's MIDPOINT, when the screen is fully
-- black — the oldest trick in transitions: change the world while
-- nobody can see it.

local DayLoopSystem = { name = "dayloop" }

local VIGNETTE_TIME = 2.5 -- seconds of flavor text before the fade

-- on the module (not local): the FadeRenderSystem derives its alpha
-- from the same clock, so the duration must have exactly one home
DayLoopSystem.FADE_TIME = 1.6 -- out over the first half, in over the second
local FADE_TIME = DayLoopSystem.FADE_TIME

local PROMPT = "What are you doing today?"
local DAYS_PER_WEEK = 5 -- Mon-Fri; Saturday hands off to the pack scene (later)

function DayLoopSystem.update(scene, dt)
    local day = scene.registry:resource("dayloop")
    day.timer = day.timer + dt

    if day.phase == "choosing" then
        -- the pick is what starts the theater. This system doesn't
        -- care WHICH activity — that's the vignette's and the stats'
        -- business — only that one was picked.
        if scene.registry:first("activityPicked") then
            day.phase, day.timer = "vignette", 0
        end
    elseif day.phase == "vignette" then
        if day.timer >= VIGNETTE_TIME then
            day.phase, day.timer = "fade", 0
        end
    elseif day.phase == "fade" then
        if not day.flipped and day.timer >= FADE_TIME / 2 then
            day.flipped = true -- the screen is black: change the world
            local runState = scene.registry:resource("runState")
            runState.day = runState.day + 1
            if runState.day > DAYS_PER_WEEK then
                runState.day = 1 -- Saturday goes here, once it exists
                runState.week = runState.week + 1
            end
            local _, textbox = scene.registry:first("textbox")
            textbox.text = PROMPT
            textbox.visibleChars = 0
        end
        if day.timer >= FADE_TIME then
            day.phase, day.timer, day.flipped = "choosing", 0, false
        end
    end
end

return DayLoopSystem
