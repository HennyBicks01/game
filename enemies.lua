local Enemies = {}

function Enemies:new()
    local enemies = setmetatable({}, { __index = self })
    enemies.list = {}
    enemies.spawnTimer = 0
    enemies.spawnInterval = 2  -- Spawn an enemy every 2 seconds
    enemies.speed = 50  -- Enemy movement speed
    return enemies
end

function Enemies:update(dt, players)
    -- Update spawn timer
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.spawnInterval then
        self:spawn()
        self.spawnTimer = 0
    end

    -- Update existing enemies
    for i = #self.list, 1, -1 do
        local enemy = self.list[i]
        local closestPlayer = self:findClosestPlayer(enemy, players)
        
        if closestPlayer then
            -- Move towards the closest player
            local angle = math.atan2(closestPlayer.y - enemy.y, closestPlayer.x - enemy.x)
            enemy.x = enemy.x + math.cos(angle) * self.speed * dt
            enemy.y = enemy.y + math.sin(angle) * self.speed * dt
        end

        -- Remove enemy if it's too far outside the screen
        if self:isOutOfBounds(enemy, 100) then
            table.remove(self.list, i)
        end
    end
end

function Enemies:spawn()
    local side = math.random(1, 4)
    local enemy = {radius = 15}

    -- Spawn enemy slightly outside the frame
    if side == 1 then  -- Top
        enemy.x = math.random(0, love.graphics.getWidth())
        enemy.y = -enemy.radius * 2
    elseif side == 2 then  -- Right
        enemy.x = love.graphics.getWidth() + enemy.radius * 2
        enemy.y = math.random(0, love.graphics.getHeight())
    elseif side == 3 then  -- Bottom
        enemy.x = math.random(0, love.graphics.getWidth())
        enemy.y = love.graphics.getHeight() + enemy.radius * 2
    else  -- Left
        enemy.x = -enemy.radius * 2
        enemy.y = math.random(0, love.graphics.getHeight())
    end

    table.insert(self.list, enemy)
end

function Enemies:findClosestPlayer(enemy, players)
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in ipairs(players) do
        local distance = math.sqrt((player.x - enemy.x)^2 + (player.y - enemy.y)^2)
        if distance < closestDistance then
            closestDistance = distance
            closestPlayer = player
        end
    end

    return closestPlayer
end

function Enemies:isOutOfBounds(enemy, margin)
    return enemy.x < -margin or enemy.x > love.graphics.getWidth() + margin or
           enemy.y < -margin or enemy.y > love.graphics.getHeight() + margin
end

function Enemies:draw()
    love.graphics.setColor(0.5, 0.5, 0.5)  -- Gray color for enemies
    for _, enemy in ipairs(self.list) do
        love.graphics.circle('fill', enemy.x, enemy.y, enemy.radius)
    end
end

return Enemies