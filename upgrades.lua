local Upgrades = {}

Upgrades.list = {
    {
        name = "Double Shot",
        description = "Fire two bullets at once",
        effect = function(player)
            player.doubleShot = true
        end
    },
    {
        name = "Piercing Shot",
        description = "Bullets pierce through enemies",
        effect = function(player)
            player.piercingShot = true
        end
    },
    {
        name = "Speed Boost",
        description = "Increase movement speed",
        effect = function(player)
            player.speed = player.speed * 1.2
        end
    }
}

function Upgrades:draw(selectedIndex)
    local cardWidth, cardHeight = 200, 300
    local spacing = 50
    local totalWidth = cardWidth * 3 + spacing * 2
    local startX = (love.graphics.getWidth() - totalWidth) / 2
    local startY = (love.graphics.getHeight() - cardHeight) / 2

    for i, upgrade in ipairs(self.list) do
        local x = startX + (i-1) * (cardWidth + spacing)
        love.graphics.setColor(1, 1, 1)
        if i == selectedIndex then
            love.graphics.setColor(1, 1, 0)
        end
        love.graphics.rectangle("line", x, startY, cardWidth, cardHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(upgrade.name, x, startY + 20, cardWidth, "center")
        love.graphics.printf(upgrade.description, x + 10, startY + 60, cardWidth - 20, "center")
    end
end

function Upgrades:selectUpgrade(index, player)
    if index >= 1 and index <= #self.list then
        self.list[index].effect(player)
        return true
    end
    return false
end

return Upgrades