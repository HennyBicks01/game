local Player = {}

function Player:new(x, y, color, isLocal)
    local player = setmetatable({}, { __index = self })
    player.x = x
    player.y = y
    player.radius = 20
    player.speed = 200
    player.color = color
    player.bullets = {}
    player.doubleShot = false
    player.piercingShot = false
    player.isLocal = isLocal
    return player
end

function Player:update(dt, width, height)
    if self.isLocal then
        local moved = false
        local oldX, oldY = self.x, self.y

        if love.keyboard.isDown('w') then
            self.y = self.y - self.speed * dt
            moved = true
        end
        if love.keyboard.isDown('s') then
            self.y = self.y + self.speed * dt
            moved = true
        end
        if love.keyboard.isDown('a') then
            self.x = self.x - self.speed * dt
            moved = true
        end
        if love.keyboard.isDown('d') then
            self.x = self.x + self.speed * dt
            moved = true
        end

        -- Keep the player within the screen boundaries
        self.x = math.max(self.radius, math.min(self.x, width - self.radius))
        self.y = math.max(self.radius, math.min(self.y, height - self.radius))

        return moved, oldX, oldY
    end
    return false
end

function Player:shoot(x, y, bulletSpeed)
    local angle = math.atan2(y - self.y, x - self.x)
    local createBullet = function(angle)
        return {
            x = self.x,
            y = self.y,
            dx = math.cos(angle) * bulletSpeed,
            dy = math.sin(angle) * bulletSpeed
        }
    end

    if self.doubleShot then
        local spread = math.pi / 36  -- 5 degree spread
        table.insert(self.bullets, createBullet(angle - spread))
        table.insert(self.bullets, createBullet(angle + spread))
    else
        table.insert(self.bullets, createBullet(angle))
    end

    return angle
end

function Player:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle('fill', self.x, self.y, self.radius)
end

return Player