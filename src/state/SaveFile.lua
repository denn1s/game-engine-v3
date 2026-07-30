-- The save file: one plain-data table that survives quitting the game.
--
-- It goes through love.filesystem, never io.open: LÖVE gives every game
-- its own per-user save directory (see t.identity in conf.lua) and
-- writes there. You never write next to the executable — on a deployed
-- machine that directory is read-only, shared between users, and wiped
-- by every update. Run `love . --debug` and check the overlay, or:
--
--   print(love.filesystem.getSaveDirectory())
--
-- Every save carries a `version` field. The day the shape of the data
-- changes, old files announce what they are and can be migrated (or at
-- worst, detected and discarded) instead of exploding somewhere deep in
-- a scene.

local serialize = require("src.state.serialize")

local SaveFile = {
    FILENAME = "save.lua",
    VERSION = 1,
}

function SaveFile.save(data)
    data.version = SaveFile.VERSION
    love.filesystem.write(SaveFile.FILENAME, serialize.encode(data))
end

-- Returns the saved table, or nil when there is no usable save — first
-- run, corrupt file, or a version we no longer understand. Callers
-- treat all three the same way: start fresh.
function SaveFile.load()
    local text = love.filesystem.read(SaveFile.FILENAME)
    if not text then return nil end

    local data = serialize.decode(text)
    if not data or data.version ~= SaveFile.VERSION then return nil end
    return data
end

return SaveFile
