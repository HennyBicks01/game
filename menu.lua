local Menu = {}

Menu.buttons = {
    singleplayer = {x = 300, y = 100, width = 200, height = 50, text = "Singleplayer"},
    host = {x = 300, y = 200, width = 200, height = 50, text = "Host Game"},
    join = {x = 300, y = 300, width = 200, height = 50, text = "Join Game"}
}

function Menu:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Dot Game", 0, 50, 800, "center")
    
    for _, button in pairs(self.buttons) do
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
        love.graphics.printf(button.text, button.x, button.y + 15, button.width, "center")
    end
end

function Menu:update()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    for _, button in pairs(self.buttons) do
        button.x = (windowWidth - button.width) / 2
    end
    self.buttons.singleplayer.y = windowHeight * 0.2
    self.buttons.host.y = windowHeight * 0.4
    self.buttons.join.y = windowHeight * 0.6
end

function Menu:mousepressed(x, y, button)
    if button == 1 then
        for name, btn in pairs(self.buttons) do
            if x > btn.x and x < btn.x + btn.width and y > btn.y and y < btn.y + btn.height then
                return name  -- Return the name of the clicked button
            end
        end
    end
    return nil
end

return Menu