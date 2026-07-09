-- A Scene is one screen of the game: a menu, the overworld, a battle...
-- It owns the two halves of ECS:
--
--   scene.registry  -- the DATA:  entities and their components
--   scene.systems   -- the LOGIC: run in order, every frame
--
-- Systems receive the scene, so they can reach the registry (and later,
-- scene-level things like the camera). A system is a plain table that
-- may implement any of five hooks:
--
--   setup(scene)          once, when the scene starts: create what you own
--   update(scene, dt)     every frame: simulate
--   draw(scene)           every frame: render
--   keypressed(scene, key) on discrete key presses (menus, debug keys)
--   unload(scene)         when the scene goes away: clean up what you own
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

function Scene:update(dt)
    for _, system in ipairs(self.systems) do
        if system.update then
            system.update(self, dt)
        end
    end
end

function Scene:draw()
    for _, system in ipairs(self.systems) do
        if system.draw then
            system.draw(self)
        end
    end
end

function Scene:keypressed(key)
    for _, system in ipairs(self.systems) do
        if system.keypressed then
            system.keypressed(self, key)
        end
    end
end

return Scene
