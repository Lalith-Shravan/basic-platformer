-- Basic 2D Platformer with STI (Simple Tiled Implementation)

local sti = require("libs.sti")
local Player = require("player")

-- Game state
local map
local player
local collisionLayer
local debugMode = false

local levelList = {}
local currentLevel = 1
local spawnPoint = {x = 100, y = 100}
local endRect = nil

-- Scaling
local GAME_WIDTH = 240
local GAME_HEIGHT = 160
local SCALE = 4
local canvas

function loadLevel(idx)
    local mapPath = levelList[idx]
    if not mapPath or not love.filesystem.getInfo(mapPath) then
        print("No map found at " .. tostring(mapPath))
        return false
    end
    map = sti(mapPath)
    collisionLayer = nil
    spawnPoint = {x = 100, y = 100}
    endRect = nil
    -- Find layers
    for _, layer in ipairs(map.layers) do
        if layer.name == "collision" or layer.name == "solid" then
            collisionLayer = layer
            layer.visible = false
        elseif layer.type == "objectgroup" and layer.name == "Spawn" and layer.objects and #layer.objects >= 1 then
            spawnPoint.x = layer.objects[1].x
            spawnPoint.y = layer.objects[1].y
        elseif layer.type == "objectgroup" and layer.name == "End" and layer.objects and #layer.objects >= 1 then
            local obj = layer.objects[1]
            endRect = {x = obj.x, y = obj.y, w = obj.width, h = obj.height}
        end
    end
    return true
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    canvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)
    -- Load player tileset
    local playerTileset = nil
    local tilesetPath = "assets/player.png"
    if love.filesystem.getInfo(tilesetPath) then
        playerTileset = love.graphics.newImage(tilesetPath)
    end
    -- Discover levels in maps/ directory if none specified
    if #levelList == 0 and love.filesystem.getInfo("maps") then
        for _, fname in ipairs(love.filesystem.getDirectoryItems("maps")) do
            if fname:match("%.lua$") then
                table.insert(levelList, "maps/" .. fname)
            end
        end
        table.sort(levelList)
    end
    -- Load first level
    loadLevel(currentLevel)
    player = Player.new(spawnPoint.x, spawnPoint.y, playerTileset, 8, 8)
    player:setupAnimations({
        idle = {1},
        run = {3, 4},
        jump = {2}
    })
end

function checkEndCollision()
    
    if not endRect then return false end
    local px, py, pw, ph = player.x, player.y, player.width, player.height
    return px < endRect.x + endRect.w and px + pw > endRect.x and py < endRect.y + endRect.h and py + ph > endRect.y
end

function love.update(dt)
    -- Cap delta time to prevent physics issues
    dt = math.min(dt, 1/30)

    if map then
        map:update(dt)
    end

    -- Find spawn and end object layers for centralized collision
    local spawnLayer, endLayer, spikesLayer
    if map and map.layers then
        for _, layer in ipairs(map.layers) do
            if layer.name == "Spawn" and layer.type == "objectgroup" then spawnLayer = layer end
            if layer.name == "End" and layer.type == "objectgroup" then endLayer = layer end
            if layer.name == "Spikes" and layer.type == "objectgroup" then spikesLayer = layer end
        end
    end
    player.spawnLayer = spawnLayer
    player.endLayer = endLayer
    player.spikesLayer = spikesLayer
    player:update(dt, collisionLayer, map and map.tilewidth or 8, map and map.tileheight or 8)

    -- If player touched spikes, reset to spawn
    if player.onSpikes and spawnPoint then
        player.x = spawnPoint.x
        player.y = spawnPoint.y
        player.vx = 0
        player.vy = 0
    end

    -- Level end check
    if checkEndCollision() then
        if currentLevel < #levelList then
            currentLevel = currentLevel + 1
            loadLevel(currentLevel)
            player.x = spawnPoint.x
            player.y = spawnPoint.y
            player.vx = 0
            player.vy = 0
        end
    end

    -- Camera system removed: no camera calculations needed
end

function love.draw()
    -- Draw game to native-resolution canvas
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    love.graphics.push()
    -- Camera system removed: no translation needed

    -- Draw map layers
    if map then
        -- Draw Background, collision, Spawn, End, and Spikes layers if present
        local bgLayer, colLayer, spawnLayer, endLayer, spikesLayer
        for _, layer in ipairs(map.layers) do
            if layer.name == "Background" then bgLayer = layer end
            if layer.name == "collision" then colLayer = layer end
            if layer.name == "Spawn" and layer.type == "objectgroup" then spawnLayer = layer end
            if layer.name == "End" and layer.type == "objectgroup" then endLayer = layer end
            if layer.name == "Spikes" and layer.type == "objectgroup" then spikesLayer = layer end
        end
        if bgLayer then map:drawLayer(bgLayer) end
        if colLayer then map:drawLayer(colLayer) end
        if spawnLayer then map:drawLayer(spawnLayer) end
        if endLayer then map:drawLayer(endLayer) end
        if spikesLayer then map:drawLayer(spikesLayer) end

        -- fallback visual markers for spawn/end when in debug mode
        if debugMode then
            love.graphics.setColor(0, 1, 0, 0.6)
            if spawnPoint then love.graphics.rectangle("line", spawnPoint.x, spawnPoint.y, 8, 8) end
            love.graphics.setColor(1, 0, 0, 0.6)
            if endRect then love.graphics.rectangle("line", endRect.x, endRect.y, endRect.w, endRect.h) end
            love.graphics.setColor(1, 1, 1)
        end
    else
        love.graphics.setColor(0.2, 0.2, 0.3)
        love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)
        love.graphics.setColor(0.4, 0.3, 0.2)
        love.graphics.rectangle("fill", 0, 500, GAME_WIDTH, 100)
        love.graphics.setColor(1, 1, 1)
    end

    -- Draw player
    player:draw()

    if debugMode then
        player:drawDebug()
    end

    love.graphics.pop()
    love.graphics.setCanvas()

    -- Draw the canvas scaled up to the window
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, 0, 0, 0, SCALE, SCALE)
end

function love.keypressed(key)
    if key == "space" or key == "up" or key == "w" then
        player:jump()
    end

    if key == "f1" then
        debugMode = not debugMode
    end

    if key == "escape" then
        love.event.quit()
    end

    if key == "r" then
        loadLevel(currentLevel)
        player.x = spawnPoint.x
        player.y = spawnPoint.y
        player.vx = 0
        player.vy = 0
    end
end
