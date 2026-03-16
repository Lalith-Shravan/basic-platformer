local Player = {}
Player.__index = Player

function Player.new(x, y, tileset, frameWidth, frameHeight)
    local self = setmetatable({}, Player)

    -- Position and dimensions
    self.x = x or 100
    self.y = y or 100
    self.width = frameWidth or 32
    self.height = frameHeight or 32

    -- Physics
    self.vx = 0
    self.vy = 0
    self.speed = 50
    self.jumpForce = -120
    self.gravity = 250
    self.onGround = false

    -- Collision box offset (adjust if sprite has padding)
    self.collider = {
        offsetX = 1,
        offsetY = 0,
        width = (frameWidth or 8) - 2,
        height = frameHeight or 8
    }

    -- Animation
    self.tileset = tileset
    self.frameWidth = frameWidth or 32
    self.frameHeight = frameHeight or 32
    self.frames = {}
    self.animations = {}
    self.currentAnim = "idle"
    self.currentFrame = 1
    self.animTimer = 0
    self.animSpeed = 0.25
    self.facingRight = true

    return self
end

-- Set up animation frames from tileset
-- frameData format: { idle = {1, 2}, run = {3, 4, 5, 6}, jump = {7} }
-- Frame numbers are 1-indexed tile positions in the tileset
function Player:setupAnimations(frameData)
    if not self.tileset then return end

    local imgWidth = self.tileset:getWidth()
    local cols = math.floor(imgWidth / self.frameWidth)

    for animName, frameIndices in pairs(frameData) do
        self.animations[animName] = {}
        for _, frameIndex in ipairs(frameIndices) do
            local col = (frameIndex - 1) % cols
            local row = math.floor((frameIndex - 1) / cols)
            local quad = love.graphics.newQuad(
                col * self.frameWidth,
                row * self.frameHeight,
                self.frameWidth,
                self.frameHeight,
                self.tileset:getDimensions()
            )
            table.insert(self.animations[animName], quad)
        end
    end
end

function Player:setAnimation(name)
    if self.currentAnim ~= name and self.animations[name] then
        self.currentAnim = name
        self.currentFrame = 1
        self.animTimer = 0
    end
end

function Player:update(dt, collisionLayer, tileWidth, tileHeight)
    -- Horizontal input
    self.vx = 0
    if love.keyboard.isDown("left", "a") then
        self.vx = -self.speed
        self.facingRight = false
    end
    if love.keyboard.isDown("right", "d") then
        self.vx = self.speed
        self.facingRight = true
    end

    -- Apply gravity
    self.vy = self.vy + self.gravity * dt

    -- Update position with collision
    self:moveWithCollision(dt, collisionLayer, tileWidth, tileHeight)

    -- Update animation state
    if not self.onGround then
        self:setAnimation("jump")
    elseif self.vx ~= 0 then
        self:setAnimation("run")
    else
        self:setAnimation("idle")
    end

    -- Update animation frame
    if self.animations[self.currentAnim] then
        self.animTimer = self.animTimer + dt
        if self.animTimer >= self.animSpeed then
            self.animTimer = 0
            self.currentFrame = self.currentFrame + 1
            if self.currentFrame > #self.animations[self.currentAnim] then
                self.currentFrame = 1
            end
        end
    end
end

function Player:moveWithCollision(dt, collisionLayer, tw, th)
    if not collisionLayer then
        -- No collision layer, just move freely
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
        return
    end

    -- Horizontal movement
    local newX = self.x + self.vx * dt
    if not self:checkCollision(newX, self.y, collisionLayer, tw, th) then
        self.x = newX
    else
        self.vx = 0
    end

    -- Vertical movement
    local newY = self.y + self.vy * dt
    if not self:checkCollision(self.x, newY, collisionLayer, tw, th) then
        self.y = newY
    else
        if self.vy > 0 then
            -- Snap to ground
            self.y = math.floor((self.y + self.collider.height) / th) * th - self.collider.height
        end
        self.vy = 0
    end

    -- Ground probe: check 1 pixel below feet
    self.onGround = self:checkCollision(self.x, self.y + 1, collisionLayer, tw, th)
end

function Player:checkCollision(x, y, collisionLayer, tw, th)
    local col = self.collider

    -- Get the tiles the player's collision box overlaps
    local left = math.floor((x + col.offsetX) / tw)
    local right = math.floor((x + col.offsetX + col.width - 1) / tw)
    local top = math.floor((y + col.offsetY) / th)
    local bottom = math.floor((y + col.offsetY + col.height - 1) / th)

    for ty = top, bottom do
        for tx = left, right do
            local tile = self:getTile(collisionLayer, tx, ty)
            if tile then
                return true
            end
        end
    end

    return false
end

function Player:getTile(layer, x, y)
    if x < 0 or y < 0 then return nil end
    if y + 1 > #layer.data then return nil end
    if x + 1 > #layer.data[y + 1] then return nil end
    return layer.data[y + 1][x + 1]
end

function Player:jump()
    if self.onGround then
        self.vy = self.jumpForce
        self.onGround = false
    end
end

function Player:draw()
    local scaleX = self.facingRight and 1 or -1
    local drawX = math.floor(self.x)
    local drawY = math.floor(self.y)
    local offsetX = self.facingRight and 0 or self.frameWidth

    if self.tileset and self.animations[self.currentAnim] then
        local quad = self.animations[self.currentAnim][self.currentFrame]
        love.graphics.draw(
            self.tileset,
            quad,
            drawX + offsetX,
            drawY,
            0,
            scaleX,
            1
        )
    else
        -- Fallback rectangle if no tileset
        love.graphics.setColor(0.2, 0.6, 1)
        love.graphics.rectangle("fill", drawX, drawY, self.width, self.height)
        love.graphics.setColor(1, 1, 1)
    end
end

function Player:drawDebug()
    -- Draw collision box
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle("line",
        self.x + self.collider.offsetX,
        self.y + self.collider.offsetY,
        self.collider.width,
        self.collider.height
    )
    love.graphics.setColor(1, 1, 1)
end

return Player
