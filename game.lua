local Enemies = require('enemies')
local Upgrades = require('upgrades')
local Player = require('player')

local Game = {}

function Game:new()
    local game = setmetatable({}, { __index = self })
    game:load()
    return game
end

function Game:load()
    self.players = {
        Player:new(200, 300, {1, 0, 0}, true)  -- Red, local player
    }
    self.localPlayerIndex = 1
    self.bulletSpeed = 400
    self.bulletRadius = 5
    self.enemies = Enemies:new()
    self.gameState = 'countdown'
    self.countdown = 3
    self.countdownTimer = 1
    self.waveTimer = 60  -- 1 minute per wave
    self.waveNumber = 1
    self.upgrades = Upgrades
    self.currentUpgrades = {}
    self.selectedUpgrade = 1
end

function Game:addPlayer(x, y)
    table.insert(self.players, Player:new(x, y, {0, 0, 1}, false))  -- Blue, remote player
end

function Game:update(dt)
    if self.gameState == 'countdown' then
        self.countdownTimer = self.countdownTimer - dt
        if self.countdownTimer <= 0 then
            self.countdown = self.countdown - 1
            self.countdownTimer = 1
            if self.countdown == 0 then
                self.gameState = 'playing'
            end
        end
    elseif self.gameState == 'playing' then
        self.waveTimer = self.waveTimer - dt
        if self.waveTimer <= 0 then
            self.gameState = 'upgrade'
            self.waveNumber = self.waveNumber + 1
            self.waveTimer = 60
            self.currentUpgrades = self.upgrades:getRandomUpgrades()
            self.selectedUpgrade = 1
        end

        -- Update players
        for i, player in ipairs(self.players) do
            local moved, oldX, oldY = player:update(dt, love.graphics.getWidth(), love.graphics.getHeight(), self.enemies.list)
            if moved and i == self.localPlayerIndex then
                local updateData = {x = player.x, y = player.y, index = i}
                if _G.server then
                    _G.server:sendToAll('update', updateData)
                elseif _G.client then
                    _G.client:send('update', updateData)
                end
            end
        end

        -- Update bullets
        for _, player in ipairs(self.players) do
            for j, bullet in ipairs(player.bullets) do
                bullet.x = bullet.x + bullet.dx * dt
                bullet.y = bullet.y + bullet.dy * dt
                
                -- Remove bullets that are off-screen
                if bullet.x < 0 or bullet.x > love.graphics.getWidth() or
                   bullet.y < 0 or bullet.y > love.graphics.getHeight() then
                    table.remove(player.bullets, j)
                end
            end
        end

        -- Send update if moved
        if moved then
            local updateData = {x = player.x, y = player.y, index = self.localPlayerIndex}
            if _G.server then
                _G.server:sendToAll('update', updateData)
            elseif _G.client then
                _G.client:send('update', updateData)
            end
        end

        -- Update enemies
        self.enemies:update(dt, self.players)

        -- Check for collisions between bullets and enemies
        for _, player in ipairs(self.players) do
            for i = #player.bullets, 1, -1 do
                local bullet = player.bullets[i]
                for j = #self.enemies.list, 1, -1 do
                    local enemy = self.enemies.list[j]
                    if self:checkCollision(bullet, enemy) then
                        if bullet.piercing > 0 then
                            bullet.piercing = bullet.piercing - 1
                        else
                            table.remove(player.bullets, i)
                        end
                        table.remove(self.enemies.list, j)
                        break
                    end
                end
            end
        end
    end
end

function Game:checkCollision(bullet, enemy)
    local dx = bullet.x - enemy.x
    local dy = bullet.y - enemy.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (bullet.size + enemy.radius)
end

function Game:updateOtherPlayer(data)
    if not self.players then return end  -- Safety check
    if data.index ~= self.localPlayerIndex then
        local oldX, oldY = self.players[data.index].x, self.players[data.index].y
        self.players[data.index].x = data.x
        self.players[data.index].y = data.y
        print("Updated other player", data.index, "from", oldX, oldY, "to", data.x, data.y)
    else
        print("Received update for local player, ignoring")
    end
end

function Game:shoot(x, y)
    local player = self.players[self.localPlayerIndex]
    local angle = player:shoot(x, y, self.bulletSpeed)

    -- Send bullet data to other players
    local bulletData = {
        playerIndex = self.localPlayerIndex,
        x = player.x,
        y = player.y,
        angle = angle,
        doubleShot = player.doubleShot
    }
    if _G.server then
        _G.server:sendToAll('shoot', bulletData)
    elseif _G.client then
        _G.client:send('shoot', bulletData)
    end
end

function Game:addBullet(data)
    if data.playerIndex ~= self.localPlayerIndex then
        local player = self.players[data.playerIndex]
        local createBullet = function(angle)
            return {
                x = data.x,
                y = data.y,
                dx = math.cos(angle) * self.bulletSpeed,
                dy = math.sin(angle) * self.bulletSpeed
            }
        end

        if data.doubleShot then
            local spread = math.pi / 36  -- 5 degree spread
            table.insert(player.bullets, createBullet(data.angle - spread))
            table.insert(player.bullets, createBullet(data.angle + spread))
        else
            table.insert(player.bullets, createBullet(data.angle))
        end
    end
end

function Game:draw()
    if self.gameState == 'countdown' then
        love.graphics.setColor(1, 1, 1)
        local text = self.countdown > 0 and tostring(self.countdown) or "GO!"
        love.graphics.printf(text, 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), "center")
    elseif self.gameState == 'playing' then
        if not self.players then return end  -- Safety check
        for i, player in ipairs(self.players) do
            love.graphics.setColor(unpack(player.color))
            love.graphics.circle('fill', player.x, player.y, player.radius)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(i, player.x - 5, player.y - 8)

            -- Draw bullets
            love.graphics.setColor(1, 1, 0)  -- Yellow bullets
            for _, bullet in ipairs(player.bullets) do
                love.graphics.circle('fill', bullet.x, bullet.y, self.bulletRadius)
            end
        end
        
        -- Draw enemies
        self.enemies:draw()
        
        -- Draw timer and wave number
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(string.format("Wave: %d", self.waveNumber), 10, 10, 200, "left")
        love.graphics.printf(string.format("Time: %.0f", self.waveTimer), 0, 10, love.graphics.getWidth(), "center")
    elseif self.gameState == 'upgrade' then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Choose an Upgrade", 0, 50, love.graphics.getWidth(), "center")
        self.upgrades:draw(self.currentUpgrades, self.selectedUpgrade)
    end
end

function Game:keypressed(key)
    if self.gameState == 'upgrade' then
        if key == 'left' then
            self.selectedUpgrade = math.max(1, self.selectedUpgrade - 1)
        elseif key == 'right' then
            self.selectedUpgrade = math.min(3, self.selectedUpgrade + 1)
        elseif key == 'return' then
            self:selectUpgrade(self.selectedUpgrade)
        end
    end
end

function Game:mousepressed(x, y, button)
    if self.gameState == 'upgrade' and button == 1 then
        local cardWidth, cardHeight = 200, 300
        local spacing = 50
        local totalWidth = cardWidth * 3 + spacing * 2
        local startX = (love.graphics.getWidth() - totalWidth) / 2
        local startY = (love.graphics.getHeight() - cardHeight) / 2

        for i = 1, 3 do
            local cardX = startX + (i-1) * (cardWidth + spacing)
            local cardY = startY
            if x >= cardX and x <= cardX + cardWidth and y >= cardY and y <= cardY + cardHeight then
                self:selectUpgrade(i)
                break
            end
        end
    end
end

function Game:selectUpgrade(index)
    if self.upgrades:selectUpgrade(self.currentUpgrades, index, self.players[self.localPlayerIndex]) then
        self.gameState = 'countdown'
        self.countdown = 3
        self.countdownTimer = 1
    end
end

return Game