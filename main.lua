-- Basic 2D Platformer with STI (Simple Tiled Implementation)

local sti = require("libs.sti")
local Player = require("player")

-- Game state
local map
local player
local collisionLayer
local debugMode = false

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load the Tiled map (export as .lua from Tiled)
    -- Make sure to place your exported map in the maps/ folder
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
    -- Replace with your tileset path and dimensions
    local playerTileset = nil
    local tilesetPath = "assets/player.png"
    if love.filesystem.getInfo(tilesetPath) then
        playerTileset = love.graphics.newImage(tilesetPath)
    end

    -- Create player (x, y, tileset, frameWidth, frameHeight)
    player = Player.new(100, 100, playerTileset, 8, 8)

    -- Set up animations
    -- Adjust frame numbers based on your tileset layout
    -- Frame numbers are 1-indexed, counting left-to-right, top-to-bottom
    player:setupAnimations({
        idle = {1, 2},        -- Frames for idle animation
        run = {3, 4},   -- Frames for running
        jump = {1}            -- Frame for jumping
    })
end

function love.update(dt)
    -- Cap delta time to prevent physics issues
    dt = math.min(dt, 1/30)

    if map then
        map:update(dt)
    end

    player:update(dt, collisionLayer)

    -- Simple camera (center on player)
    if map then
        local camX = player.x - love.graphics.getWidth() / 2 + player.width / 2
        local camY = player.y - love.graphics.getHeight() / 2 + player.height / 2

        -- Clamp camera to map bounds
        local mapPixelWidth = map.width * map.tilewidth
        local mapPixelHeight = map.height * map.tileheight

        camX = math.max(0, math.min(camX, mapPixelWidth - love.graphics.getWidth()))
        camY = math.max(0, math.min(camY, mapPixelHeight - love.graphics.getHeight()))

        -- Store camera position for drawing
        map.camX = camX
        map.camY = camY
    end
end

function love.draw()
    love.graphics.push()

    -- Apply camera transform
    if map and map.camX then
        love.graphics.translate(-math.floor(map.camX), -math.floor(map.camY))
    end

    -- Draw map layers
    if map then
        map:drawLayer(map.layers["background"])
        map:drawLayer(map.layers["tiles"])
        -- Add more layers as needed from your Tiled map
    else
        -- Draw placeholder background
        love.graphics.setColor(0.2, 0.2, 0.3)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        -- Draw placeholder ground
        love.graphics.setColor(0.4, 0.3, 0.2)
        love.graphics.rectangle("fill", 0, 500, love.graphics.getWidth(), 100)
        love.graphics.setColor(1, 1, 1)
    end

    -- Draw player
    player:draw()

    if debugMode then
        player:drawDebug()
    end

    love.graphics.pop()

    -- Draw UI (not affected by camera)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Arrow keys / WASD to move, Space to jump", 10, 10)
    love.graphics.print("Press F1 for debug mode", 10, 30)

    if not map then
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.print("No map loaded - create maps/level1.lua in Tiled", 10, 60)
        love.graphics.setColor(1, 1, 1)
    end
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
        -- Restart
        love.load()
    end
end
