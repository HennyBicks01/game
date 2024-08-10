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
    if not self.players then return end  -- Safety check
    local player = self.players[self.localPlayerIndex]
    local moved = false
    local oldX, oldY = player.x, player.y
    
    -- Move the dot based on key presses
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

    -- Keep the dot within the screen boundaries
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
            print("Server sending update:", self.localPlayerIndex, player.x, player.y)
            _G.server:sendToAll('update', updateData)
        elseif _G.client then
            print("Client sending update:", self.localPlayerIndex, player.x, player.y)
            _G.client:send('update', updateData)
        end
        print("Local player moved from", oldX, oldY, "to", player.x, player.y)
    end
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
    
    -- Draw player positions for debugging
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("P1: " .. math.floor(self.players[1].x) .. ", " .. math.floor(self.players[1].y), 10, 10)
    if self.players[2] then
        love.graphics.print("P2: " .. math.floor(self.players[2].x) .. ", " .. math.floor(self.players[2].y), 10, 30)
    end
end

return Game