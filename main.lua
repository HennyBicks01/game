local Game = require('game')
local Multiplayer = require('multiplayer')
local Menu = require('menu')

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
    debugFile = io.open("log\\debug_" .. os.time() .. ".log", "w")
    
    -- Redirect print function to write to the debug file
    local oldPrint = print
    print = function(...)
        oldPrint(...)
        if debugFile then
            debugFile:write(table.concat({...}, "\t") .. "\n")
            debugFile:flush()  -- Ensure it's written immediately
        end
    end

    love.window.setMode(800, 600, {resizable=true, vsync=true})
end

function love.update(dt)
    if gameState == 'menu' then
        Menu:update()
    elseif gameState == 'playing' or gameState == 'hosting' or gameState == 'joined' then
        game:update(dt)
        if gameState == 'hosting' then
            server:update()
        elseif gameState == 'joined' then
            client:update()
        end
    end

    -- Update status message timer
    if statusTimer > 0 then
        statusTimer = statusTimer - dt
        if statusTimer <= 0 then
            statusMessage = ''
        end
    end
end

function love.draw()
    if gameState == 'menu' then
        Menu:draw()
    elseif gameState == 'hosting' then
        love.graphics.printf("Host Code: " .. hostCode, 0, 50, 800, "center")
        game:draw()
    elseif gameState == 'joining' then
        love.graphics.printf("Enter Join Code:", 0, 250, 800, "center")
        love.graphics.printf(joinCode, 0, 300, 800, "center")
    elseif gameState == 'playing' or gameState == 'joined' then
        game:draw()
    end

    -- Draw status message
    if statusMessage ~= '' then
        love.graphics.setColor(1, 1, 0)  -- Yellow color for visibility
        love.graphics.printf(statusMessage, 0, 550, 800, "center")
        love.graphics.setColor(1, 1, 1)  -- Reset color
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if gameState == 'menu' then
        local action = Menu:mousepressed(x, y, button)
        if action == 'singleplayer' then
            gameState = 'playing'
            game:load()
        elseif action == 'host' then
            server, hostCode = Multiplayer.hostGame(game, setStatusMessage)
            gameState = 'hosting'
        elseif action == 'join' then
            gameState = 'joining'
            joinCode = ''  -- Reset join code when entering join mode
        end
    elseif gameState == 'playing' or gameState == 'hosting' or gameState == 'joined' then
        if button == 1 then
            game:shoot(x, y)
        end
        game:mousepressed(x, y, button)
    end
end

function love.keypressed(key)
    if key == 'escape' and (gameState == 'playing' or gameState == 'hosting' or gameState == 'joined') then
        gameState = 'menu'
        if client then client:disconnect() end
        if server then server:destroy() end
        client = nil
        server = nil
    elseif gameState == 'joining' then
        if key == 'return' then
            client = Multiplayer.joinGame(game, setStatusMessage, joinCode)
            gameState = 'joined'
        elseif key == 'backspace' then
            joinCode = joinCode:sub(1, -2)
        elseif #joinCode < 4 and tonumber(key) then
            joinCode = joinCode .. key
        end
    end
end

function love.gamepadpressed(joystick, button)
    if gameState == 'menu' then
        if button == 'dpup' or button == 'dpdown' then
            Menu:navigateOptions(button == 'dpup' and -1 or 1)
        elseif button == 'a' then
            local action = Menu:selectOption()
            handleMenuAction(action)
        end
    elseif gameState == 'upgrade' then
        if button == 'dpleft' or button == 'dpright' then
            game:navigateUpgrades(button == 'dpleft' and -1 or 1)
        elseif button == 'a' then
            game:selectUpgrade()
        end
    end
end

function love.gamepadaxis(joystick, axis, value)
    if gameState == 'menu' then
        if axis == 'lefty' then
            if value > 0.5 and Menu.selectedIndex < #Menu.buttons then
                Menu:navigateOptions(1)
            elseif value < -0.5 and Menu.selectedIndex > 1 then
                Menu:navigateOptions(-1)
            end
        end
    end
end

function handleMenuAction(action)
    if action == 'singleplayer' then
        gameState = 'playing'
        game:load()
    elseif action == 'host' then
        server, hostCode = Multiplayer.hostGame(game, setStatusMessage)
        gameState = 'hosting'
    elseif action == 'join' then
        gameState = 'joining'
        joinCode = ''
    end
end

function love.quit()
    if debugFile then
        debugFile:close()
    end
    if client then client:disconnect() end
    if server then server:destroy() end
end

function setStatusMessage(message, duration)
    statusMessage = message
    statusTimer = duration or 3  -- Default duration of 3 seconds
end