-- Detects when a ball leaves the screen, updates the match score (a
-- singleton component), and checks the win condition.
--
-- It does NOT spawn the next ball. It destroys the scored ball and
-- emits a `serveRequest` event-entity; the BallSpawnSystem takes it
-- from there. Systems talk through data, never through function calls.

local ScoringSystem = {}

-- This system owns the match state, so it creates it.
function ScoringSystem.setup(scene)
    -- a "prefab": a plain table of components, ready to spawn. The table
    -- is NOT the entity — the entity is the number spawn() returns.
    local matchPrefab = {
        match = { left = 0, right = 0, winScore = 5, state = "play" },
    }
    scene.registry:spawn(matchPrefab)
end

function ScoringSystem.update(scene, dt)
    local registry = scene.registry
    local _, match = registry:first("match")
    if match.state ~= "play" then return end -- frozen on the gameover screen

    local screenW = love.graphics.getWidth()

    for _, ballEntity in ipairs(registry:query("ball", "position", "size")) do
        local pos = registry:get(ballEntity, "position")
        local size = registry:get(ballEntity, "size")

        local serveDirection
        if pos.x + size.w < 0 then
            match.right = match.right + 1
            serveDirection = -1 -- loser receives the serve
        elseif pos.x > screenW then
            match.left = match.left + 1
            serveDirection = 1
        end

        if serveDirection then
            registry:destroy(ballEntity)
            -- only re-serve if this point didn't end the match: a request
            -- spawned on the final point would never be consumed (the
            -- BallSpawnSystem freezes on gameover) and hatch a ghost
            -- ball next match
            if match.left < match.winScore and match.right < match.winScore then
                registry:spawn({ serveRequest = { direction = serveDirection } })
            end
        end
    end

    if match.left >= match.winScore or match.right >= match.winScore then
        match.state = "gameover"
    end
end

return ScoringSystem
