local Game = require('game')
local Multiplayer = require('multiplayer')

local gameState = 'menu'
local game = Game:new()  -- Create a new game instance
local client
local server
local hostCode
local joinCode = ''
local statusMessage = ''
local statusTimer = 0

local debugFile

function love.load()
    -- Open a unique debug file for each instance
    debugFile = io.open("debug_" .. os.time() .. ".txt", "w")
    
    -- Redirect print function to write to the debug file
    local oldPrint = print
    print = function(...)
        oldPrint(...)
        if debugFile then
            debugFile:write(table.concat({...}, "\t") .. "\n")
            debugFile:flush()  -- Ensure it's written immediately
        end
    end

    love.window.setMode(800, 600)
    
    buttons = {
        singleplayer = {x = 300, y = 150, width = 200, height = 50, text = "Singleplayer"},
        host = {x = 300, y = 250, width = 200, height = 50, text = "Host Game"},
        join = {x = 300, y = 350, width = 200, height = 50, text = "Join Game"}
    }
end

function love.update(dt)
    if gameState == 'playing' then
        game:update(dt)
    elseif gameState == 'hosting' then
        print("Updating server")
        server:update()
        game:update(dt)
    elseif gameState == 'joined' then
        print("Updating client")
        client:update()
        game:update(dt)
    end

    -- Update status message timer
    if statusTimer > 0 then
        statusTimer = statusTimer - dt
        if statusTimer <= 0 then
            statusMessage = ''
        end
    end

    -- Make sure to update client/server even when not in 'hosting' or 'joined' state
    if client then 
        print("Updating client (always)")
        client:update() 
    end
    if server then 
        print("Updating server (always)")
        server:update() 
    end
end


function love.draw()
    if gameState == 'menu' then
        drawMenu()
    elseif gameState == 'hosting' then
        love.graphics.printf("Host Code: " .. hostCode, 0, 50, 800, "center")
        game:draw()
    elseif gameState == 'joining' then
        love.graphics.printf("Enter Join Code:", 0, 250, 800, "center")
        love.graphics.printf(joinCode, 0, 300, 800, "center")
    elseif gameState == 'joined' or gameState == 'playing' then
        game:draw()
    end

    -- Draw status message
    if statusMessage ~= '' then
        love.graphics.setColor(1, 1, 0)  -- Yellow color for visibility
        love.graphics.printf(statusMessage, 0, 550, 800, "center")
        love.graphics.setColor(1, 1, 1)  -- Reset color
    end
end

function setStatusMessage(message, duration)
    statusMessage = message
    statusTimer = duration or 3  -- Default duration of 3 seconds
end

function drawMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Dot Game", 0, 100, 800, "center")
    
    for _, button in pairs(buttons) do
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
        love.graphics.printf(button.text, button.x, button.y + 15, button.width, "center")
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if gameState == 'menu' and button == 1 then
        for name, btn in pairs(buttons) do
            if x > btn.x and x < btn.x + btn.width and y > btn.y and y < btn.y + btn.height then
                if name == 'singleplayer' then
                    gameState = 'playing'
                    game:load()
                elseif name == 'host' then
                    hostGame()
                elseif name == 'join' then
                    gameState = 'joining'
                    joinCode = ''  -- Reset join code when entering join mode
                end
            end
        end
    end
end

function love.keypressed(key)
    if key == 'escape' and (gameState == 'playing' or gameState == 'hosting' or gameState == 'joined') then
        gameState = 'menu'
        if client then client:disconnect() end
        if server then server:destroy() end
        _G.client = nil
        _G.server = nil
    elseif gameState == 'joining' then
        if key == 'return' then
            client = Multiplayer.joinGame(game, setStatusMessage, joinCode)
            _G.client = client  -- Set the global client variable
            gameState = 'joined'
        elseif key == 'backspace' then
            joinCode = joinCode:sub(1, -2)
        elseif #joinCode < 4 and tonumber(key) then
            joinCode = joinCode .. key
        end
    end
end

function hostGame()
    server, hostCode = Multiplayer.hostGame(game, setStatusMessage)
    _G.server = server  -- Set the global server variable
    gameState = 'hosting'
end

function love.quit()
    if debugFile then
        debugFile:close()
    end
    if client then client:disconnect() end
    if server then server:destroy() end
end