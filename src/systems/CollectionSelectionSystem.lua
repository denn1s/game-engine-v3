-- Owns the collection cursor and page. Input only asks to move; this system
-- applies the grid rules and keeps the selected card visible.

local CollectionSelectionSystem = { name = "collectionSelection" }

local function clamp(value, low, high)
    return math.max(low, math.min(value, high))
end

function CollectionSelectionSystem.update(scene, dt)
    local registry = scene.registry
    local view = registry:resource("collectionView")
    local collection = registry:resource("runState").collection
    local count = #collection

    if count == 0 then
        view.selected, view.page = 0, 1
        return
    end

    if view.selected == 0 then view.selected = 1 end

    local steps = {
        left = -1,
        right = 1,
        up = -view.columns,
        down = view.columns,
    }

    for _, request in registry:each("collectionMoveRequested") do
        view.selected = clamp(
            view.selected + assert(steps[request.direction]), 1, count)
    end

    for _, request in registry:each("collectionJumpRequested") do
        view.selected = request.edge == "first" and 1 or count
    end

    view.page = math.floor((view.selected - 1) / view.pageSize) + 1
end

return CollectionSelectionSystem
