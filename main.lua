local planets = require("planetHandling")

function love.load()
    math.randomseed(os.time())
    width = 650
    height = 650

    love.physics.setMeter(32)
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact, endContact)

    -- Physics settings/flags
    gravityStrength = 3000 
    isThrusting = false

    -- Create the ship
    ship = {}
    ship.body = love.physics.newBody(world, width/4, height/4, "dynamic")
    ship.shape = love.physics.newPolygonShape(12, 10, 0, -15, -12, 10)    
    ship.fixture = love.physics.newFixture(ship.body, ship.shape)
    ship.fixture:setUserData({ id="ship" })

    ship.thrustPower = 25
    ship.turnSpeed = 3 -- radians per second

    ship.body:setAngularDamping(3)
    ship.body:setLinearDamping(0.5)

    -- Make planets
    planets.solar_system = {}
    numPlanets = 7  -- shouldnt exceed the number of audio loops available
    planetMinRadius = 5
    planetMaxRadius = 25
    planets.generateSolarSystem(numPlanets, planetMinRadius, planetMaxRadius, 1000)

    -- Graphics setup
    love.window.setMode(width, height)
end

function love.update(dt)
    world:update(dt)

    -- Gravity well pull
    for _, planet in ipairs(planets.solar_system) do        
        if planet.alive == true then
            local sx, sy = ship.body:getPosition()
            local px, py = planet.body:getPosition()

            local dx = px - sx
            local dy = py - sy
            local distSq = dx * dx + dy * dy

            if distSq > 0.1 then -- prevent divide by zero
                local forceMag = (gravityStrength*planet.shape:getRadius()) / distSq
                local angle = math.atan2(dy, dx)
                local fx = math.cos(angle) * forceMag
                local fy = math.sin(angle) * forceMag
                ship.body:applyForce(fx, fy)
            end
        end
    end

    -- ROTATE LEFT/RIGHT
    if love.keyboard.isDown("left") then
        ship.body:setAngle(ship.body:getAngle() - ship.turnSpeed * dt)
    elseif love.keyboard.isDown("right") then
        ship.body:setAngle(ship.body:getAngle() + ship.turnSpeed * dt)
    end

    -- THRUST FORWARD
    if love.keyboard.isDown("up") then
        local angle = ship.body:getAngle() - math.pi/2
        local fx = math.cos(angle) * ship.thrustPower
        local fy = math.sin(angle) * ship.thrustPower
        ship.body:applyForce(fx, fy)
        isThrusting = true
    else
        isThrusting = false
    end

    -- THRUST BACKWARD
    if love.keyboard.isDown("down") then
        local angle = ship.body:getAngle() - math.pi/2
        local fx = math.cos(angle) * -ship.thrustPower
        local fy = math.sin(angle) * -ship.thrustPower
        ship.body:applyForce(fx, fy)
    end

    -- WRAPAROUND
    local x, y = ship.body:getPosition()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    if x < 0 then
        ship.body:setPosition(screenW, y)
    elseif x > screenW then
        ship.body:setPosition(0, y)
    end

    if y < 0 then
        ship.body:setPosition(x, screenH)
    elseif y > screenH then
        ship.body:setPosition(x, 0)
    end
end

function love.draw()
    -- Draw planet
    for _, planet in ipairs(planets.solar_system) do        
        if planet.alive == true then
            love.graphics.setColor(planet.color)
            love.graphics.circle("fill", planet.body:getX(), planet.body:getY(), planet.shape:getRadius())
            
            if planet.explosionTime then
                planets.destroyPlanet(planet)
            end
        end
    end

    -- Draw ship
    love.graphics.setColor(1, 1, 1)

    love.graphics.push()

    love.graphics.translate(ship.body:getX(), ship.body:getY())
    love.graphics.rotate(ship.body:getAngle())
    love.graphics.polygon("line", ship.shape:getPoints())

    if isThrusting then
        love.graphics.setColor(1, 0.5, 0) -- orange flame
        love.graphics.polygon("fill", 0, 15, 5, 25, -5, 25) -- triangle pointing down
    end

    love.graphics.pop()
end

function beginContact(a, b, coll)
    local aData = a:getUserData()
    local bData = b:getUserData()

    if (aData.id == "planet" and bData.id == "ship") or
       (aData.id == "ship" and bData.id == "planet") then

        for _, planet in ipairs(planets.solar_system) do
            if planet.alive then
                local pData = planet.fixture:getUserData()
                if pData and (pData.index == aData.index or pData.index == bData.index) then
                    planet.explosionTime = love.timer.getTime() -- trigger planet destruction
                end
            end
        end

    end

end

function love.keypressed(key)
    if key == "r" then
        love.audio.stop()
        planets.clearPlanets()
        planets.generateSolarSystem(numPlanets, planetMinRadius, planetMaxRadius, 1000)
    end
end
