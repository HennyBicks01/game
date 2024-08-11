local Upgrades = {}

Upgrades.all = {
    {
        name = "Double Shot",
        description = "Fire two bullets at once",
        effect = function(player)
            player.doubleShot = true
        end
    },
    {
        name = "Piercing Shot",
        description = "Bullets pierce through one enemy",
        effect = function(player)
            player.piercingShot = (player.piercingShot or 0) + 1
        end
    },
    {
        name = "Speed Boost",
        description = "Increase movement speed",
        effect = function(player)
            player.speed = player.speed * 1.2
        end
    },
    {
        name = "Homing Shot",
        description = "Bullets home in on nearby enemies",
        effect = function(player)
            player.homingShot = true
        end
    },
    {
        name = "Rapid Fire",
        description = "Increase fire rate",
        effect = function(player)
            player.fireRate = (player.fireRate or 1) * 1.3
        end
    },
    {
        name = "Bullet Size",
        description = "Increase bullet size",
        effect = function(player)
            player.bulletSize = (player.bulletSize or 1) * 1.2
        end
    }
}

function Upgrades:getRandomUpgrades()
    local shuffled = {}
    for i, v in ipairs(self.all) do
        shuffled[i] = v
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return {shuffled[1], shuffled[2], shuffled[3]}
end

function Upgrades:draw(upgrades, selectedIndex)
    local cardWidth, cardHeight = 200, 300
    local spacing = 50
    local totalWidth = cardWidth * 3 + spacing * 2
    local startX = (love.graphics.getWidth() - totalWidth) / 2
    local startY = (love.graphics.getHeight() - cardHeight) / 2

    for i, upgrade in ipairs(upgrades) do
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

function Upgrades:selectUpgrade(upgrades, index, player)
    if index >= 1 and index <= #upgrades then
        upgrades[index].effect(player)
        return true
    end
    return false
end

return Upgrades