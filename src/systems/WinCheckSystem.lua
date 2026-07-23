-- Watches the match. When someone reaches winScore, requests the
-- gameover scene, sending the final score along as the payload.
--
-- ScoringSystem awards points; deciding what a finished match MEANS
-- (leave the scene) is a different responsibility, so it's a different
-- system. Runs right after ScoringSystem.

local WinCheckSystem = { name = "winCheck" }

function WinCheckSystem.update(scene, dt)
    local registry = scene.registry
    local _, match = registry:first("match")

    if match.left >= match.winScore or match.right >= match.winScore then
        registry:spawn({
            switchRequest = {
                to = "gameover",
                payload = { left = match.left, right = match.right },
            },
        })
    end
end

return WinCheckSystem
