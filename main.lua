local Player = require("player")
local levelManager = require("levels")

-- Game state
local map
local player
local collisionLayer
local debugMode = false

local spawnPoint

-- Scaling
local GAME_WIDTH = 240
local GAME_HEIGHT = 160
local SCALE = 4
local canvas

function love.load()

    love.graphics.setDefaultFilter("nearest", "nearest")

    canvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)

    -- Load player tileset
    local playerTileset = nil
    local tilesetPath = "assets/player.png"
    if love.filesystem.getInfo(tilesetPath) then
        playerTileset = love.graphics.newImage(tilesetPath)
    end
    
    levelManager.discoverLevels()
    -- Load first level
    map, collisionLayer, spawnPoint = levelManager.loadCurrentLevel()
    player = Player.new(spawnPoint.x, spawnPoint.y, playerTileset, 8, 8)
    player:setupAnimations({
        idle = {1},
        run = {3, 4},
        jump = {2}
    })
end

function love.update(dt)
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
    if player.onEnd then
        map, collisionLayer, spawnPoint = levelManager.loadNextLevel()
        player.x = spawnPoint.x
        player.y = spawnPoint.y
        player.vx = 0
        player.vy = 0
    end
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.push()

    if map then
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
    end

    player:draw()

    love.graphics.pop()
    love.graphics.setCanvas()

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
        levelManager.loadLevel()
        player.x = spawnPoint.x
        player.y = spawnPoint.y
        player.vx = 0
        player.vy = 0
    end
end