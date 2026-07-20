-- Collision between balls and paddles: push out, reflect, speed up,
-- and add angle depending on where the ball hit the paddle.

local SPEEDUP = 1.06

local PaddleHitsSystem = {}

local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and bx < ax + aw
       and ay < by + bh and by < ay + ah
end

function PaddleHitsSystem.update(scene, dt)
    local registry = scene.registry
    local _, match = registry:first("match")
    if match.state ~= "play" then return end -- frozen on the gameover screen

    for _, ballEntity in ipairs(registry:query("ball", "position", "size", "velocity")) do
        local bp = registry:get(ballEntity, "position")
        local bs = registry:get(ballEntity, "size")
        local bv = registry:get(ballEntity, "velocity")

        for _, paddleEntity in ipairs(registry:query("paddle", "position", "size")) do
            local pp = registry:get(paddleEntity, "position")
            local ps = registry:get(paddleEntity, "size")

            if aabb(bp.x, bp.y, bs.w, bs.h, pp.x, pp.y, ps.w, ps.h) then
                -- push the ball out so it can't get stuck inside the paddle
                if bv.vx > 0 then
                    bp.x = pp.x - bs.w
                else
                    bp.x = pp.x + ps.w
                end

                -- reflect + speed up + "english" from the hit offset (-1..1)
                local offset = ((bp.y + bs.h / 2) - (pp.y + ps.h / 2)) / (ps.h / 2)
                local speed = math.abs(bv.vx) * SPEEDUP
                bv.vx = bv.vx > 0 and -speed or speed
                bv.vy = bv.vy + offset * speed * 0.75
            end
        end
    end
end

return PaddleHitsSystem
