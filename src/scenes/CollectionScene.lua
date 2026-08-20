-- The collection browser scaffold. Lesson 11 arrives with the navigation,
-- paging and detail panel already working so class time can stay on the
-- procedural card picture. Pack reveal is lesson 12: this scene currently
-- enters directly in browse mode.

local Scene = require("src.ecs.Scene")
local SaveFile = require("src.state.SaveFile")
local CardGenerator = require("src.generation.CardGenerator")

local CollectionInputSystem = require("src.systems.CollectionInputSystem")
local CollectionSelectionSystem = require("src.systems.CollectionSelectionSystem")
local CollectionChromeRenderSystem = require("src.systems.CollectionChromeRenderSystem")
local CollectionGridRenderSystem = require("src.systems.CollectionGridRenderSystem")
local CardDetailRenderSystem = require("src.systems.CardDetailRenderSystem")

-- A deterministic fixture only for this lesson. It disappears once the Week
-- scene actually hands Saturday to pack mode; until then, an empty save would
-- make a card-art class with no cards to inspect.
local function lessonGallery()
    local profiles = {
        { int = 20, charm = 5, sense = 10 },
        { int = 6, charm = 18, sense = 8 },
        { int = 7, charm = 8, sense = 20 },
    }
    local rng = love.math.newRandomGenerator(11011)
    local random = function(...) return rng:random(...) end
    local cards = {}
    for _, stats in ipairs(profiles) do
        local pack = CardGenerator.pack(stats, 4, random)
        for _, card in ipairs(pack) do cards[#cards + 1] = card end
    end
    return cards
end

return function(payload)
    local scene = Scene.new("collection")

    local saved = SaveFile.load()
    local runState = saved and saved.runState or {
        week = 1,
        day = 1,
        stats = { int = 1, charm = 1, sense = 1 },
        collection = {},
    }
    if #runState.collection == 0 then
        runState.collection = lessonGallery()
    end
    scene.registry:setResource("runState", runState)

    scene.registry:setResource("collectionView", {
        selected = #runState.collection > 0 and 1 or 0,
        page = 1,
        columns = 4,
        pageSize = 8,
        mode = "browse", -- lesson 12 adds reveal -> browse
    })

    scene:addSystem(CollectionInputSystem)
    scene:addSystem(CollectionSelectionSystem)
    scene:addSystem(CollectionChromeRenderSystem)
    scene:addSystem(CollectionGridRenderSystem)
    scene:addSystem(CardDetailRenderSystem)

    return scene
end
