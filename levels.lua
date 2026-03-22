local sti = require("libs.sti")

local L = {}

local currentLevel = 1
local levelList = {"maps/Level1.lua"}

function L.discoverLevels()
    if love.filesystem.getInfo("maps") then
        for _, fname in ipairs(love.filesystem.getDirectoryItems("maps")) do
            if fname:match("%.lua$") then
                table.insert(levelList, "maps/" .. fname)
            end
        end
        table.sort(levelList)
    end
end

function L.loadCurrentLevel()
    local mapPath = levelList[currentLevel]
    if not mapPath or not love.filesystem.getInfo(mapPath) then
        print("No map found at " .. tostring(mapPath))
        return false
    end
    local map = sti(mapPath)
    local collisionLayer = nil
    local spawnPoint = {x = 100, y = 100}

    for _, layer in ipairs(map.layers) do
        if layer.name == "collision" or layer.name == "solid" then
            collisionLayer = layer
            layer.visible = false
        elseif layer.type == "objectgroup" and layer.name == "Spawn" and layer.objects and #layer.objects >= 1 then
            spawnPoint.x = layer.objects[1].x
            spawnPoint.y = layer.objects[1].y
        elseif layer.type == "objectgroup" and layer.name == "End" and layer.objects and #layer.objects >= 1 then
            local obj = layer.objects[1]
        end
    end
    
    return map, collisionLayer, spawnPoint
end

function L.loadNextLevel()
    if (currentLevel == #levelList) then
        currentLevel = 1
    else
        currentLevel = currentLevel + 1
    end

    return L.loadCurrentLevel()
end

return L