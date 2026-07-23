-- A Scene is one screen of the game: a menu, the overworld, a battle...
-- It owns the two halves of ECS:
--
--   scene.registry  -- the DATA:  entities and their components
--   scene.systems   -- the LOGIC: run in order, every frame
--
-- Systems receive the scene, so they can reach the registry (and later,
-- scene-level things like the camera). A system is a plain table that
-- may implement any of four hooks:
--
--   setup(scene)       once, when the scene starts: create what you own
--   update(scene, dt)  every frame: simulate
--   draw(scene)        every frame: render
--   unload(scene)      when the scene goes away: clean up what you own
--
-- There is deliberately NO input hook. Key presses reach systems as
-- `keyPressed` event entities (see Game.keypressed) and are handled in
-- update(), like every other event. Input systems go FIRST in the
-- system order: they only fill components and spawn event entities;
-- the systems after them mutate the world.
--
-- The Game owns the scenes and switches between them; see src/Game.lua.

local Registry = require("src.ecs.Registry")

local Scene = {}
Scene.__index = Scene

function Scene.new(name)
    return setmetatable({
        name = name,
        registry = Registry.new(),
        systems = {}, -- ordered list; order matters!
        -- debug tools can switch a system off ([system] = true). It
        -- lives on the SCENE, not on the system table: system modules
        -- are shared by every scene instance (require caches them) and
        -- must stay stateless — and a fresh scene starts with all on.
        disabledSystems = {},
    }, Scene)
end

function Scene:addSystem(system)
    self.systems[#self.systems + 1] = system
end

-- Call once, after all systems are added: each system creates the
-- entities and resources it owns (initial entities, fonts...).
function Scene:setup()
    for _, system in ipairs(self.systems) do
        if system.setup then
            system.setup(self)
        end
    end
end

-- Call when the scene is done: release resources, stop sounds...
function Scene:unload()
    for _, system in ipairs(self.systems) do
        if system.unload then
            system.unload(self)
        end
    end
end

-- update and draw honor disabledSystems; setup and unload never do —
-- they manage resources, and a disabled system still owns what it made.
function Scene:update(dt)
    for _, system in ipairs(self.systems) do
        if system.update and not self.disabledSystems[system] then
            system.update(self, dt)
        end
    end
end

function Scene:draw()
    for _, system in ipairs(self.systems) do
        if system.draw and not self.disabledSystems[system] then
            system.draw(self)
        end
    end
end

return Scene
