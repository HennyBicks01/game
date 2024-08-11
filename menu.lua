local Menu = {}

Menu.buttons = {
    {text = "Singleplayer", action = "singleplayer"},
    {text = "Host Game", action = "host"},
    {text = "Join Game", action = "join"}
}
Menu.selectedIndex = 1

function Menu:update()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    for i, button in ipairs(self.buttons) do
        button.x = (windowWidth - 200) / 2
        button.y = windowHeight * (0.2 + 0.2 * i)
        button.width = 200
        button.height = 50
    end
end

function Menu:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Dot Game", 0, 50, 800, "center")
    
    for i, button in ipairs(self.buttons) do
        if i == self.selectedIndex then
            love.graphics.setColor(1, 1, 0)  -- Highlight selected option
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
        love.graphics.printf(button.text, button.x, button.y + 15, button.width, "center")
    end
end

function Menu:mousepressed(x, y, button)
    if button == 1 then
        for i, btn in ipairs(self.buttons) do
            if btn.x and btn.y and btn.width and btn.height then
                if x > btn.x and x < btn.x + btn.width and y > btn.y and y < btn.y + btn.height then
                    return btn.action
                end
            end
        end
    end
    return nil
end

function Menu:navigateOptions(direction)
    self.selectedIndex = self.selectedIndex + direction
    if self.selectedIndex < 1 then
        self.selectedIndex = #self.buttons
    elseif self.selectedIndex > #self.buttons then
        self.selectedIndex = 1
    end
end

function Menu:selectOption()
    return self.buttons[self.selectedIndex].action
end

return Menu