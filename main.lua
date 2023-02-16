function love.load()
    math.randomseed(os.time()) -- this adds random seed to math.random to make spawns more dinamic, uses user time as argument
    -- import all sprites images
    sprites = {}
    sprites.background = love.graphics.newImage('sprites/background.png')
    sprites.bullet = love.graphics.newImage('sprites/bullet.png')
    sprites.player = love.graphics.newImage('sprites/player.png')
    sprites.zombie = love.graphics.newImage('sprites/zombie.png')

    -- keep track of player's every input 
    player = {}
    player.x = love.graphics.getWidth()/2
    player.y = love.graphics.getHeight()/2
    player.speed = 180
    player.injuredSpeed = 300
    player.injured = false

    gameFont = love.graphics.newFont(30)

    zombies = {} -- table for all the enemies
    bullets = {} -- table for all the bullets

    gameState = 1
    score = 0
    maxTime = 2
    timer = maxTime
end

------------------------------------------------------------------------------

function love.update(dt)
--player's movement
    -- keyboard input
    if gameState == 2 then

        local moveSpeed = player.speed
        if player.injured == true then
            moveSpeed = player.injuredSpeed
        end
        
        if love.keyboard.isDown("d") and player.x < love.graphics.getWidth() then
            player.x = player.x + moveSpeed*dt -- this compensates if the frame rate drops (same distance at the same amount of time)
        end
        if love.keyboard.isDown("a") and player.x > 0 then
            player.x = player.x - moveSpeed*dt
        end
        if love.keyboard.isDown("w") and player.y > 0 then
            player.y = player.y - moveSpeed*dt
        end
        if love.keyboard.isDown("s") and player.y < love.graphics.getHeight() then
            player.y = player.y + moveSpeed*dt
        end
    end
--zombies's movement
    -- iterate through each zombie
    for i,z in ipairs(zombies) do
        z.x = z.x + ( math.cos(zombiePlayerAngle(z)) * z.speed * dt )
        z.y = z.y + ( math.sin(zombiePlayerAngle(z)) * z.speed * dt )

        -- Zombie/player collision
        if distanceBetween(z.x, z.y, player.x, player.y) < 20 then
            -- if player is not injured delete the zombie and set player.injured true
            if player.injured == false then
                player.injured = true
                z.dead = true
            else
                --otherwise player is injured delete all zombies, set player.injured = false and set gameState = 1
                for i, z in ipairs(zombies) do
                    zombies[i] = nil
                    gameState = 1
                    player.injured = false
                    player.x = love.graphics.getWidth()/2
                    player.y = love.graphics.getHeight()/2
                end
            end
        end
    end

-- bullets
    
    for i,b in ipairs(bullets) do
        b.x = b.x + ( math.cos(b.direction) * b.speed * dt )
        b.y = b.y + ( math.sin(b.direction) * b.speed * dt )       
    end

    -- deleting bullets from last to first (to avoid problems)
    for i=#bullets, 1, -1 do -- for loop that goes from #bullets (which is the total number of elements of this table) and go decreasing by 1 to 1.
        local b = bullets[i]
        if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() or b.dead == true then -- last statement is the collision bullet
            table.remove(bullets, i)
        end
    end

-- zombies and bullets collision
    for i,z in ipairs(zombies) do -- compare every zombie to every bullet (nested loop)
        for j,b in ipairs(bullets) do
            if distanceBetween(z.x, z.y, b.x, b.y) < 20 then
                z.dead = true
                b.dead = true
                score = score + 1
            end
        end
    end

    for i=#zombies, 1, -1 do
        local z = zombies[i]
        if z.dead == true then
            table.remove(zombies, i)
        end
    end

-- Zombie Spawn time
    if gameState == 2 then
        timer = timer - dt
        if timer <= 0 then -- every maxTime we are getting a new zombie
            spawnZombie()
            maxTime = 0.95 * maxTime -- this will reduce each time it loops the time between spawns
            timer = maxTime -- reset the timer
        end
    end
end

---------------------------------------------------------------------------

function love.draw()
    -- set background
    love.graphics.draw(sprites.background, 0, 0)

    if gameState == 1 then
        love.graphics.setFont(gameFont)
        love.graphics.printf("Click anywhere to begin", 0, 50, love.graphics.getWidth(), "center")
    end

    if player.injured == true then
        love.graphics.setColor(1,0,0)
    end
    love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, sprites.player:getWidth()/2, sprites.player:getWidth()/2)

    -- prevent other sprites to change color
    love.graphics.setColor(1,1,1)
    -- cycle through zombies table to spawn zombie(s)
    for i, z in ipairs(zombies) do -- z is each zombie table in zombies table
        love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
    end

    for i, b in ipairs(bullets) do
        love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.35, nil, sprites.bullet:getWidth()/2, sprites.bullet:getHeight()/2)
    end

    if gameState == 2 then
        love.graphics.setFont(gameFont)
        love.graphics.print("Score: " .. score, 10, 10)
    end
end

------------------------------------------------------------------------------

function love.mousepressed (x, y, button, istouch, presses)
    if button == 1 and gameState == 2 then
        spawnBullet()
    elseif button == 1 and gameState == 1 then
        gameState = 2
        maxTime = 2
        timer = maxTime
        score = 0
    end
end

function playerMouseAngle() -- this is a math function to get the angle between 2 points (player location and mouse)
    return math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX()) + math.pi
end

function zombiePlayerAngle(enemy) -- same logic that player Mouse Angle but we need a parameter to call each zombie in draw function (enemy instead of zombie)
    return math.atan2(enemy.y - player.y, enemy.x - player.x) + math.pi
end

function spawnZombie() 
    local zombie = {} -- local variable (single zombie object) in this function 

    zombie.x = 0
    zombie.y = 0
    zombie.speed = 100
    zombie.dead = false -- variable to keep track if these elements need to be destroyed

    local side = math.random(1, 4) --one of the side game windows
    if side == 1 then -- left side
        zombie.x = -30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 2 then -- right side
        zombie.x = (love.graphics.getWidth() + 30)
        zombie.y = math.random(0,love.graphics.getHeight())
    elseif side == 3 then -- top
        zombie.x = math.random(0,love.graphics.getWidth())
        zombie.y = -30
    elseif side == 4 then -- bottom
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = (love.graphics.getHeight() + 30)
    end

    table.insert(zombies, zombie)
end

function spawnBullet()
    local bullet = {}
    bullet.x = player.x
    bullet.y = player.y
    bullet.speed = 500
    bullet.direction = playerMouseAngle()--use the playermouseangle to define the direction
    bullet.dead = false
    table.insert(bullets, bullet)
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 )
end