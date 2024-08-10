local Game = {}

function Game:new()
    local game = setmetatable({}, { __index = self })
    game:load()
    return game
end

function Game:load()
    self.players = {
        {
            x = 400,
            y = 300,
            radius = 20,
            speed = 200,
            color = {1, 0, 0}  -- Red
        },
        {
            x = 200,
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

    -- Send update to server if moved
    if moved then
        local updateData = {x = player.x, y = player.y, index = self.localPlayerIndex}
        if _G.server then
            print("Server sending update:", self.localPlayerIndex, player.x, player.y)
            _G.server:sendToAll('update', updateData)
        elseif _G.client then
            print("Client sending update:", self.localPlayerIndex, player.x, player.y)
            _G.client:send('update', updateData)
        end
    end
end

function Game:updateOtherPlayer(data)
    if not self.players then return end  -- Safety check
    if data.index ~= self.localPlayerIndex then
        self.players[data.index].x = data.x
        self.players[data.index].y = data.y
        print("Updating other player:", data.index, data.x, data.y)
    end
end

function Game:draw()
    if not self.players then return end  -- Safety check
    for i, player in ipairs(self.players) do
        love.graphics.setColor(unpack(player.color))
        love.graphics.circle('fill', player.x, player.y, player.radius)
    end
    
    -- Draw player indices
    love.graphics.setColor(1, 1, 1)
    for i, player in ipairs(self.players) do
        love.graphics.print(i, player.x - 5, player.y - 8)
    end
end

return Game