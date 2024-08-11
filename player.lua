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
    player.fireRate = 1  -- Shots per second
    player.fireTimer = 0  -- Timer to track when we can fire next
    player.bulletSize = 1
    player.isLocal = isLocal
    player.damage = 1
    player.bulletSpeed = 400
    return player
end

function Player:update(dt, width, height, enemies)
    if self.isLocal then
        local moved = false
        local oldX, oldY = self.x, self.y

        -- Keyboard input
        if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
            self.y = self.y - self.speed * dt
            moved = true
        end
        if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
            self.y = self.y + self.speed * dt
            moved = true
        end
        if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
            self.x = self.x - self.speed * dt
            moved = true
        end
        if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
            self.x = self.x + self.speed * dt
            moved = true
        end

        -- Controller input
        local joysticks = love.joystick.getJoysticks()
        if #joysticks > 0 then
            local joystick = joysticks[1]  -- Use the first connected joystick
            local leftX = joystick:getAxis(1)
            local leftY = joystick:getAxis(2)
            
            -- Apply deadzone
            if math.abs(leftX) > 0.2 or math.abs(leftY) > 0.2 then
                self.x = self.x + leftX * self.speed * dt
                self.y = self.y + leftY * self.speed * dt
                moved = true
            end
        end

        -- Keep the player within the screen boundaries
        self.x = math.max(self.radius, math.min(self.x, width - self.radius))
        self.y = math.max(self.radius, math.min(self.y, height - self.radius))

        -- Update fire timer
        self.fireTimer = math.max(0, self.fireTimer - dt)

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
    -- Check if we can fire based on the fire rate
    if self.fireTimer <= 0 then
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

        -- Reset the fire timer
        self.fireTimer = 1 / self.fireRate

        return angle
    end
    return nil
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