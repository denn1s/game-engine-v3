-- A SpriteSheet is the knowledge of how one image is cut into frames.
-- A sheet is a GRID, so a frame needs two indices:
--
--   row   = which animation this strip is   (idle, walk-down, walk-left...)
--   frame = which picture inside that strip (1, 2, 3...)
--
-- Both are 1-based Lua indices; LÖVE wants the pixel offset of the
-- cell's top-left corner. That subtraction is all there is to learn:
--
--   x = (frame - 1) * frameW      y = (row - 1) * frameH
--
-- A Quad is then a saved rectangle inside the texture: "when drawing,
-- pretend the image starts here and is this big". The texture is
-- shared; a quad costs almost nothing. They are cached because
-- newQuad every frame would build garbage for the collector.

local SpriteSheet = {}
SpriteSheet.__index = SpriteSheet

function SpriteSheet.new(image, frameW, frameH)
    assert(image:getWidth() % frameW == 0, "sheet width is not a whole number of frames")
    assert(image:getHeight() % frameH == 0, "sheet height is not a whole number of frames")
    return setmetatable({
        image = image,
        frameW = frameW,
        frameH = frameH,
        cols = image:getWidth() / frameW,
        rows = image:getHeight() / frameH,
        quads = {},
    }, SpriteSheet)
end

function SpriteSheet:quad(frame, row)
    assert(frame >= 1 and frame <= self.cols, "frame outside the sheet")
    assert(row >= 1 and row <= self.rows, "row outside the sheet")
    local key = row * self.cols + frame
    local q = self.quads[key]
    if not q then
        q = love.graphics.newQuad(
            (frame - 1) * self.frameW,
            (row - 1) * self.frameH,
            self.frameW, self.frameH,
            self.image:getDimensions())
        self.quads[key] = q
    end
    return q
end

-- The pixel rectangle of a cell — for overlays and readouts that point
-- at the sheet itself. Same subtraction, exposed as a function so the
-- math lives in exactly one place.
function SpriteSheet:cellRect(frame, row)
    return (frame - 1) * self.frameW, (row - 1) * self.frameH, self.frameW, self.frameH
end

return SpriteSheet
