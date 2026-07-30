-- Table -> string, the Lua way. Lua has no built-in serializer, but it
-- has something better: a Lua table IS valid Lua syntax. So we don't
-- invent a format — we print the table as Lua source ("return { ... }")
-- and deserialize by just RUNNING it with load(). Code is data.
--
-- This only works because save data follows the PLAIN DATA rule: only
-- numbers, strings, booleans, and tables of those. No functions, no
-- images, no entities — anything that can't be written down as source
-- is a bug in what we tried to save, so we error loudly instead of
-- writing a broken file.

local function isIdentifier(key)
    -- keys like `week` print bare; anything else prints as ["..."]
    return type(key) == "string" and key:match("^[%a_][%w_]*$") ~= nil
end

local function serializeValue(value, indent)
    local t = type(value)
    if t == "number" or t == "boolean" then
        return tostring(value)
    elseif t == "string" then
        return ("%q"):format(value) -- %q escapes quotes and newlines
    elseif t == "table" then
        local pieces = {}
        -- sort the keys so the same table always prints the same file:
        -- stable output means save files diff cleanly
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

        local inner = indent .. "    "
        for _, key in ipairs(keys) do
            local keyText
            if isIdentifier(key) then
                keyText = key
            elseif type(key) == "number" then
                keyText = "[" .. tostring(key) .. "]"
            elseif type(key) == "string" then
                keyText = "[" .. ("%q"):format(key) .. "]"
            else
                error("cannot serialize key of type " .. type(key))
            end
            pieces[#pieces + 1] = inner .. keyText .. " = "
                .. serializeValue(value[key], inner) .. ","
        end
        if #pieces == 0 then return "{}" end
        return "{\n" .. table.concat(pieces, "\n") .. "\n" .. indent .. "}"
    else
        error("cannot serialize value of type " .. t) -- plain data only!
    end
end

-- serialize(table)  -> a string of Lua source: "return { ... }"
-- deserialize(text) -> the table back, or nil if the text is invalid
local serialize = {}

function serialize.encode(data)
    assert(type(data) == "table", "can only serialize a table")
    return "return " .. serializeValue(data, "")
end

function serialize.decode(text)
    -- loadstring compiles the text into a function (LÖVE is LuaJIT /
    -- Lua 5.1; in 5.2+ this is load()). pcall guards against a corrupt
    -- or hand-edited file: a save that won't parse returns nil, and the
    -- caller decides what a missing save means.
    local chunk = loadstring(text)
    if not chunk then return nil end
    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then return nil end
    return data
end

return serialize
