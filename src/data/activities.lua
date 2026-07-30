-- The activities: content, not code. This file is ONLY a table — the
-- first of many (cards are coming): designers tune it, systems read
-- it, and nothing in here can have a bug that isn't a typo.
--
-- Each activity names the hidden stat it trains and carries a small
-- pool of flavor lines (GDD §5: 5-8 each, so repeats feel alive).

return {
    study = {
        stat = "int",
        lines = {
            "You feel sharper.",
            "The words start making sense.",
            "One more chapter. Just one.",
            "You fall asleep on the book. It counts.",
            "Somewhere in there, an idea sticks.",
        },
    },
    grooming = {
        stat = "charm",
        lines = {
            "Not bad. Not bad at all.",
            "A comb through the hair works miracles.",
            "You practice smiling. It's getting less weird.",
            "Today's look: intentional.",
            "The mirror approves, for once.",
        },
    },
    hobbies = {
        stat = "sense",
        lines = {
            "You lose track of time, pleasantly.",
            "Huh. You never noticed that before.",
            "Your hands learn something your head can't name.",
            "That song again. It hits different today.",
            "You could talk about this for hours.",
        },
    },
}
