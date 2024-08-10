local sock = require('sock')

local Multiplayer = {}

Multiplayer.HOST_PORT = 22122
Multiplayer.CLIENT_PORT = 22123

function Multiplayer.hostGame(game, setStatusMessage)
    local server = sock.newServer('127.0.0.1', Multiplayer.HOST_PORT)
    local hostCode = love.math.random(1000, 9999)
    
    server:on('connect', function(data, client)
        print("Client connected to server")
    end)

    server:on('join', function(data, client)
        print("Received join request with code: " .. tostring(data.code))
        setStatusMessage("Received join request with code: " .. tostring(data.code), 2)
        if tonumber(data.code) == hostCode then
            client:send('joined', {x = game.players[2].x, y = game.players[2].y})
            setStatusMessage("Player joined the game!", 2)
            print("Player joined as player 2")
        else
            client:send('wrongCode')
            setStatusMessage("Wrong code received: " .. tostring(data.code), 2)
        end
    end)
    
    server:on('update', function(data, client)
        print("Server received update:", data.index, data.x, data.y)
        game:updateOtherPlayer(data)
        server:sendToAllBut(client, 'update', data)  -- Send to all clients except the sender
    end)
    
    server:on('error', function(msg)
        print("Server error: " .. tostring(msg))
        setStatusMessage("Server error: " .. tostring(msg), 5)
    end)

    game:load()
    game.localPlayerIndex = 1  -- Set the local player as the first player
    setStatusMessage("Hosting game. Waiting for player... Code: " .. hostCode, 10)

    return server, hostCode
end

function Multiplayer.joinGame(game, setStatusMessage, code)
    local client = sock.newClient('127.0.0.1', Multiplayer.HOST_PORT, Multiplayer.CLIENT_PORT)
    
    client:on('connect', function()
        print("Connected to server")
        setStatusMessage("Connected to server. Joining game...", 2)
        client:send('join', {code = code})
    end)
    
    client:on('joined', function(data)
        game:load()
        game.localPlayerIndex = 2  -- Set the local player as the second player
        game.players[2].x = data.x
        game.players[2].y = data.y
        setStatusMessage("Joined game successfully!", 2)
        print("Joined game as player 2, initial position:", data.x, data.y)
    end)
    
    client:on('update', function(data)
        print("Client received update:", data.index, data.x, data.y)
        game:updateOtherPlayer(data)
    end)

    client:on('disconnect', function()
        print("Disconnected from server")
        setStatusMessage("Disconnected from server", 3)
    end)

    client:on('wrongCode', function()
        print("Wrong join code entered")
        setStatusMessage("Wrong join code entered", 3)
        client:disconnect()
    end)

    client:on('error', function(msg)
        print("Client error: " .. tostring(msg))
        setStatusMessage("Error: " .. tostring(msg), 5)
    end)

    client:connect()
    setStatusMessage("Connecting to server...", 5)

    return client
end

return Multiplayer