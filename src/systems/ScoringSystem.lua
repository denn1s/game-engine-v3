-- Detects when a ball leaves the screen and updates the match score (a
-- singleton component). Nothing more: serving is BallSpawnSystem's job,
-- and deciding whether the match is over is WinCheckSystem's job.
--
-- It does NOT spawn the next ball. It destroys the scored ball and
-- emits a `serveRequest` event-entity; the BallSpawnSystem takes it
-- from there. Systems talk through data, never through function calls.

local ScoringSystem = { name = "scoring" }

-- This system owns the match state, so it creates it.
function ScoringSystem.setup(scene)
    -- a "prefab": a plain table of components, ready to spawn. The table
    -- is NOT the entity — the entity is the number spawn() returns.
    local matchPrefab = {
        match = { left = 0, right = 0, winScore = 5 },
    }
    scene.registry:spawn(matchPrefab)
end

function ScoringSystem.update(scene, dt)
    local registry = scene.registry
    local _, match = registry:first("match")
    local screenW = love.graphics.getWidth()

    for ballEntity, pos, size in registry:each("position", "size", "ball") do
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
            -- no "is the match over?" guard needed anymore: if this was
            -- the final point, the whole scene (and this request with it)
            -- is destroyed before anyone could consume it
            registry:spawn({ serveRequest = { direction = serveDirection } })
        end
    end
end

return ScoringSystem
