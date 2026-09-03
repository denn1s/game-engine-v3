-- Every PNG in the game loads ONCE, here, indexed by its path.
--
-- love.graphics.newImage hands back GPU-side texture memory; calling
-- it twice for the same file means the card sits in VRAM twice and
-- the two copies are different objects to Lua. The path is already
-- the natural key — two entities drawing "assets/lab_walk.png" mean
-- the same picture — so the cache is a plain table keyed by path.
--
-- The same argument covers cut-up images: a SpriteSheet wraps one
-- image with one cutting scheme, so (path + frame size) is its key.
--
-- Sprites are pixel art: `nearest` filtering is the difference
-- between crisp blocks and smeared gray mush when scaled up. Set at
-- load so every consumer gets it right — one knob, one place.

local SpriteSheet = require("src.graphics.SpriteSheet")

local ImageManager = {}

local images = {} -- path -> Image
local sheets = {} -- "path WxH" -> SpriteSheet

function ImageManager.load(path)
    local image = images[path]
    if not image then
        image = love.graphics.newImage(path)
        image:setFilter("nearest", "nearest")
        images[path] = image
    end
    return image
end

function ImageManager.sheet(path, frameW, frameH)
    local key = ("%s %dx%d"):format(path, frameW, frameH)
    local sheet = sheets[key]
    if not sheet then
        sheet = SpriteSheet.new(ImageManager.load(path), frameW, frameH)
        sheets[key] = sheet
    end
    return sheet
end

return ImageManager
