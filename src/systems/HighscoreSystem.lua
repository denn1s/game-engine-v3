-- Decides whether the match that just ended is the best victory so far
-- (the biggest winning margin) and, if so, writes the save file. Runs
-- once, in setup: the result is history by the time this scene exists,
-- so there is nothing to do per-frame.
--
-- Publishes a `highscore` resource for the render system:
--   { winner = 5, loser = 1, isNew = true }

local SaveFile = require("src.state.SaveFile")

local HighscoreSystem = { name = "highscore" }

function HighscoreSystem.setup(scene)
    local registry = scene.registry
    local finalScore = registry:resource("finalScore")

    local winner = math.max(finalScore.left, finalScore.right)
    local loser = math.min(finalScore.left, finalScore.right)

    local data = SaveFile.load() or {}
    local best = data.bestVictory

    -- a bigger margin is a better victory; `winner > loser` guards the
    -- debug scene switcher, which can jump here with a 0-0 "match"
    local isNew = winner > loser
        and (not best or winner - loser > best.winner - best.loser)

    if isNew then
        best = { winner = winner, loser = loser }
        data.bestVictory = best
        SaveFile.save(data)
    end

    if best then
        registry:setResource("highscore", {
            winner = best.winner,
            loser = best.loser,
            isNew = isNew,
        })
    end
end

return HighscoreSystem
