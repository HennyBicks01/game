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
            color = {1, 0, 0}  -- Red
        },
        {
            x = 600,
            y = 300,
            radius = 20,
            speed = 200,
            color = {0, 0, 1}  -- Blue
        }
    }
    self.localPlayerIndex = 1
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

    -- Send update if moved
    if moved then
        local updateData = {x = player.x, y = player.y, index = self.localPlayerIndex}
        if _G.server then
            print("Server sending update:", self.localPlayerIndex, player.x, player.y)
            local success = _G.server:sendToAll('update', updateData)
            if success then
                print("Server successfully sent update")
            else
                print("Server failed to send update")
            end
        elseif _G.client then
            print("Client sending update:", self.localPlayerIndex, player.x, player.y)
            local success = _G.client:send('update', updateData)
            if success then
                print("Client successfully sent update")
            else
                print("Client failed to send update")
            end
        else
            print("Neither server nor client is defined")
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

function Game:draw()
    if not self.players then return end  -- Safety check
    for i, player in ipairs(self.players) do
        love.graphics.setColor(unpack(player.color))
        love.graphics.circle('fill', player.x, player.y, player.radius)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(i, player.x - 5, player.y - 8)
    end
    
    -- Draw player positions for debugging
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("P1: " .. math.floor(self.players[1].x) .. ", " .. math.floor(self.players[1].y), 10, 10)
    love.graphics.print("P2: " .. math.floor(self.players[2].x) .. ", " .. math.floor(self.players[2].y), 10, 30)
end

return Game