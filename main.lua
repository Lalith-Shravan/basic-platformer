-- Basic 2D Platformer with STI (Simple Tiled Implementation)

local sti = require("libs.sti")
local Player = require("player")

-- Game state
local map
local player
local collisionLayer
local debugMode = false

-- Scaling
local GAME_WIDTH = 240
local GAME_HEIGHT = 160
local SCALE = 4
local canvas

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    canvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)

    -- Load the Tiled map (export as .lua from Tiled)
    local mapPath = "maps/level1.lua"
    if love.filesystem.getInfo(mapPath) then
        map = sti(mapPath)

        -- Find the collision layer (name it "collision" or "solid" in Tiled)
        for _, layer in ipairs(map.layers) do
            if layer.name == "collision" or layer.name == "solid" then
                collisionLayer = layer
                layer.visible = false -- Hide collision layer
                break
            end
        end
    else
        print("No map found at " .. mapPath)
        print("Create a map in Tiled and export as Lua to maps/level1.lua")
    end

    -- Load player tileset
    local playerTileset = nil
    local tilesetPath = "assets/player.png"
    if love.filesystem.getInfo(tilesetPath) then
        playerTileset = love.graphics.newImage(tilesetPath)
    end

    -- Create player (x, y, tileset, frameWidth, frameHeight)
    player = Player.new(100, 100, playerTileset, 8, 8)

    -- Set up animations
    player:setupAnimations({
        idle = {1},
        run = {3, 4},
        jump = {2}
    })
end

function love.update(dt)
    -- Cap delta time to prevent physics issues
    dt = math.min(dt, 1/30)

    if map then
        map:update(dt)
    end

    player:update(dt, collisionLayer, map and map.tilewidth or 8, map and map.tileheight or 8)

    -- Simple camera (center on player)
    if map then
        local camX = player.x - GAME_WIDTH / 2 + player.width / 2
        local camY = player.y - GAME_HEIGHT / 2 + player.height / 2

        -- Clamp camera to map bounds
        local mapPixelWidth = map.width * map.tilewidth
        local mapPixelHeight = map.height * map.tileheight

        camX = math.max(0, math.min(camX, mapPixelWidth - GAME_WIDTH))
        camY = math.max(0, math.min(camY, mapPixelHeight - GAME_HEIGHT))

        map.camX = camX
        map.camY = camY
    end
end

function love.draw()
    -- Draw game to native-resolution canvas
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    love.graphics.push()

    -- Apply camera transform
    if map and map.camX then
        love.graphics.translate(-math.floor(map.camX), -math.floor(map.camY))
    end

    -- Draw map layers
    if map then
        map:drawLayer(map.layers["Background"])
        map:drawLayer(map.layers["collision"])
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
        love.load()
    end
end
