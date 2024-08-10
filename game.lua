local Enemies = require('enemies')
local Game = {}

function Game:new()
    local game = setmetatable({}, { __index = self })
    game:load()
    return game
end

function Game:load()
    self.players = {
        {
            x = 200,
            y = 300,
            radius = 20,
            speed = 200,
            color = {1, 0, 0},  -- Red
            bullets = {}
        }
    }
    self.localPlayerIndex = 1
    self.bulletSpeed = 400
    self.bulletRadius = 5
    self.enemies = Enemies:new()
    self.gameState = 'countdown'
    self.countdown = 3
    self.countdownTimer = 1
    self.gameTimer = 60  -- 1 minute game time
    self.gameOver = false
end

function Game:addPlayer(x, y)
    table.insert(self.players, {
        x = x,
        y = y,
        radius = 20,
        speed = 200,
        color = {0, 0, 1},  -- Blue
        bullets = {}
    })
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
    elseif self.gameState == 'playing' and not self.gameOver then
        self.gameTimer = self.gameTimer - dt
        if self.gameTimer <= 0 then
            self.gameOver = true
        end

        -- Update player movement
        local player = self.players[self.localPlayerIndex]
        local moved = false
        local oldX, oldY = player.x, player.y
        
        if love.keyboard.isDown('w') then
            player.y = player.y - player.speed * dt
            moved = true
        end
        if love.keyboard.isDown('s') then
            player.y = player.y + player.speed * dt
            moved = true
        end
        if love.keyboard.isDown('a') then
            player.x = player.x - player.speed * dt
            moved = true
        end
        if love.keyboard.isDown('d') then
            player.x = player.x + player.speed * dt
            moved = true
        end

        -- Keep the player within the screen boundaries
        player.x = math.max(player.radius, math.min(player.x, love.graphics.getWidth() - player.radius))
        player.y = math.max(player.radius, math.min(player.y, love.graphics.getHeight() - player.radius))

        -- Update bullets
        for i, p in ipairs(self.players) do
            for j, bullet in ipairs(p.bullets) do
                bullet.x = bullet.x + bullet.dx * dt
                bullet.y = bullet.y + bullet.dy * dt
                
                -- Remove bullets that are off-screen
                if bullet.x < 0 or bullet.x > love.graphics.getWidth() or
                   bullet.y < 0 or bullet.y > love.graphics.getHeight() then
                    table.remove(p.bullets, j)
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
                        table.remove(player.bullets, i)
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
    return distance < (self.bulletRadius + enemy.radius)
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
    local angle = math.atan2(y - player.y, x - player.x)
    local bullet = {
        x = player.x,
        y = player.y,
        dx = math.cos(angle) * self.bulletSpeed,
        dy = math.sin(angle) * self.bulletSpeed
    }
    table.insert(player.bullets, bullet)

    -- Send bullet data to other players
    local bulletData = {
        playerIndex = self.localPlayerIndex,
        x = bullet.x,
        y = bullet.y,
        dx = bullet.dx,
        dy = bullet.dy
    }
    if _G.server then
        _G.server:sendToAll('shoot', bulletData)
    elseif _G.client then
        _G.client:send('shoot', bulletData)
    end
end

function Game:addBullet(data)
    if data.playerIndex ~= self.localPlayerIndex then
        local bullet = {
            x = data.x,
            y = data.y,
            dx = data.dx,
            dy = data.dy
        }
        table.insert(self.players[data.playerIndex].bullets, bullet)
    end
end

function Game:draw()
    if self.gameState == 'countdown' then
        love.graphics.setColor(1, 1, 1)
        local text = self.countdown > 0 and tostring(self.countdown) or "GO!"
        love.graphics.printf(text, 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), "center")
    elseif self.gameState == 'playing' or self.gameOver then
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
        
        -- Draw timer
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(string.format("Time: %.0f", self.gameTimer), 0, 10, love.graphics.getWidth(), "center")
        
        if self.gameOver then
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("Game Over!", 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), "center")
        end
    end
end

return Game