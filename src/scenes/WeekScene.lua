-- The Week scene: the raising sim. Princess Maker composition — her
-- room in the background, portrait center, the date as a big numeral
-- upper-right, the activity menu on the right, a text box along the
-- bottom. Right now it's an empty stage: the UI systems get built one
-- by one and assembled here.

local Scene = require("src.ecs.Scene")

return function(payload)
    local scene = Scene.new("week")

    return scene
end
