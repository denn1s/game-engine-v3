-- The Registry: where all components live, indexed by entity.
--
--   Entity    = just a number. It has no data, no behavior, no class.
--               It only "exists" as a key inside the component stores.
--   Component = plain data attached to an entity ({x = 10, y = 20}).
--
-- Storage layout: one table per component TYPE, indexed by entity:
--
--   registry.components = {
--       position = { [1] = {x=30, y=230}, [3] = {x=473, y=263} },
--       velocity = { [3] = {vx=280, vy=-40} },
--       ...
--   }
--
-- So "which components does entity 3 have?" is answered by looking up
-- key 3 in each store, and "every entity with a velocity" is a single
-- table — the data-oriented layout from week 1, in Lua. The name (and
-- the API) mirrors entt's registry, which we used in the C++ course.
--
-- Note the registry holds NO logic. Logic lives in Systems, which
-- belong to the Scene.

local Registry = {}
Registry.__index = Registry

function Registry.new()
    return setmetatable({
        nextEntity = 1,
        components = {}, -- component name -> { [entity] = data }
    }, Registry)
end

-- Create an entity with an initial set of components:
--   local ballEntity = registry:spawn({ position = {x=0,y=0}, ball = {} })
function Registry:spawn(components)
    local entity = self.nextEntity
    self.nextEntity = entity + 1
    for name, data in pairs(components) do
        self:add(entity, name, data)
    end
    return entity
end

function Registry:add(entity, name, data)
    local store = self.components[name]
    if not store then
        store = {}
        self.components[name] = store
    end
    store[entity] = data
end

function Registry:get(entity, name)
    local store = self.components[name]
    return store and store[entity]
end

-- Destroy an entity: forget it in every component store. That's all
-- destruction is — there is no object to delete.
function Registry:destroy(entity)
    for _, store in pairs(self.components) do
        store[entity] = nil
    end
end

-- All entities that have ALL of the given components, in a stable order:
--   for _, entity in ipairs(registry:query("position", "velocity")) do ... end
function Registry:query(...)
    local names = { ... }
    local first = self.components[names[1]] or {}
    local result = {}
    for entity in pairs(first) do
        local ok = true
        for i = 2, #names do
            local store = self.components[names[i]]
            if not store or store[entity] == nil then
                ok = false
                break
            end
        end
        if ok then
            result[#result + 1] = entity
        end
    end
    table.sort(result) -- pairs() order is undefined; keep runs deterministic
    return result
end

-- Every entity that exists, in a stable order. Nothing in the GAME needs
-- this — systems always know which components they want. It exists for
-- TOOLS: the debug inspector asks "what's here?" without knowing any
-- component names up front. (This is reflection, engine-flavored.)
function Registry:entities()
    local seen = {}
    local result = {}
    for _, store in pairs(self.components) do
        for entity in pairs(store) do
            if not seen[entity] then
                seen[entity] = true
                result[#result + 1] = entity
            end
        end
    end
    table.sort(result)
    return result
end

-- The names of every component an entity has, sorted. Also for tools.
function Registry:componentsOf(entity)
    local result = {}
    for name, store in pairs(self.components) do
        if store[entity] ~= nil then
            result[#result + 1] = name
        end
    end
    table.sort(result)
    return result
end

-- For "singleton" components that exist on exactly one entity (match
-- state, settings...). Returns entity, data.
function Registry:first(name)
    local store = self.components[name]
    if store then
        for entity, data in pairs(store) do
            return entity, data
        end
    end
end

return Registry
