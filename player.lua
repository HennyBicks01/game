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
    player.piercingShot = 0
    player.homingShot = true
    player.fireRate = 1
    player.bulletSize = 1
    player.isLocal = isLocal
    return player
end

function Player:update(dt, width, height, enemies)
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

        -- Update bullets
        for i = #self.bullets, 1, -1 do
            local bullet = self.bullets[i]
            
            if self.homingShot then
                local closestEnemy = self:findClosestEnemy(bullet, enemies)
                if closestEnemy then
                    local dx = closestEnemy.x - bullet.x
                    local dy = closestEnemy.y - bullet.y
                    local distanceToEnemy = math.sqrt(dx^2 + dy^2)
                    
                    if distanceToEnemy <= 300 then
                        local angle = math.atan2(dy, dx)
                        local homingStrength = 10
                        
                        -- Calculate target velocity
                        local targetDx = math.cos(angle) * bullet.speed
                        local targetDy = math.sin(angle) * bullet.speed
                        
                        -- Gradually adjust bullet direction towards the target
                        bullet.dx = bullet.dx + (targetDx - bullet.dx) * homingStrength * dt
                        bullet.dy = bullet.dy + (targetDy - bullet.dy) * homingStrength * dt
                        
                        -- Normalize the velocity to maintain constant speed
                        local speed = math.sqrt(bullet.dx^2 + bullet.dy^2)
                        bullet.dx = bullet.dx / speed * bullet.speed
                        bullet.dy = bullet.dy / speed * bullet.speed
                    end
                end
            end
            
            bullet.x = bullet.x + bullet.dx * dt
            bullet.y = bullet.y + bullet.dy * dt
            
            -- Remove bullets that are off-screen
            if bullet.x < 0 or bullet.x > width or bullet.y < 0 or bullet.y > height then
                table.remove(self.bullets, i)
            end
        end

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
            dy = math.sin(angle) * bulletSpeed,
            speed = bulletSpeed,
            piercing = self.piercingShot,
            size = 5 * self.bulletSize -- Base bullet size is 5
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

function Player:findClosestEnemy(bullet, enemies)
    local closestEnemy = nil
    local closestDistance = math.huge

    for _, enemy in ipairs(enemies) do
        local distance = math.sqrt((enemy.x - bullet.x)^2 + (enemy.y - bullet.y)^2)
        if distance < closestDistance then
            closestDistance = distance
            closestEnemy = enemy
        end
    end

    return closestEnemy
end

function Player:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle('fill', self.x, self.y, self.radius)
    
    -- Draw bullets
    love.graphics.setColor(1, 1, 0) -- Yellow bullets
    for _, bullet in ipairs(self.bullets) do
        love.graphics.circle('fill', bullet.x, bullet.y, bullet.size)
    end
end

return Player