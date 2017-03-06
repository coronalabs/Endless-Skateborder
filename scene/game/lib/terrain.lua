-- game.scene.hero 

-- Our hero class

local M = {}

local color = require "com.ponywolf.ponycolor"
local pickUp = require "scene.game.lib.pickUp"
local physics = require "physics"

local lastWidth, lastAngle = 0, 0
local imgDir = "scene/game/img/"
local buildingImages = { "row1A.png", "row1B.png", "row1C.png" }
local decorImages = { "hydrant.png","construction.png","sign.png","signs.png","mailbox.png", "meter.png", "paperbox.png", "streetLight.png","trash.png",}
local function dist(dx,dy) return math.sqrt ( dx * dx + dy * dy ) end

function M.new(world, buildings, x, y, flat, groundColor, buildingColor)
  -- color choices
  groundColor, buildingColor = groundColor or "00272B", buildingColor or "8479A7"
  
  -- randomize the run and the drop
  local run = flat and 1024 or (math.random(4)-1) * 128
  local drop = flat and 0 or (math.random(7)-4) * (96/2)
  if drop < 0 then drop = 0 end

  -- build a "chunk" of the map
  local instance = display.newGroup()

  -- build a random building
  if not flat and (math.random(10) < 6) then 
    local building =  display.newImageRect(buildings, imgDir .. buildingImages[math.random(#buildingImages)],768,768)
    building.anchorX, building.anchorY = 1, 1    
    building.x, building.y = x, y + 128 + math.random(128)
    building:setFillColor(color.hex2rgb(buildingColor))
    building:toBack()
    buildings:toBack()
  end

  -- build a random decor
  if (math.random(10) < 8) and drop == 0 and run > 0 then 
    local decor = display.newImage(world, imgDir .. decorImages[math.random(#decorImages)])
    decor.xScale, decor.yScale = 0.5, 0.5
    decor.anchorX, decor.anchorY = 1, 1    
    decor.x, decor.y = x + run/2, y
    decor:setFillColor(color.hex2rgb(groundColor))
    decor:toBack()
  end

  -- build the ground physics
  local ground = display.newLine(x, y, x + run, y + drop)
  physics.addBody(ground, "static", { chain={ 0, 0, run, drop }, friction = 0.0015 })
  instance.run, instance.drop = run, drop
  ground.strokeWidth = 6
  ground:setStrokeColor(color.hex2rgb(groundColor))
  ground.isGround = true

  -- create a silhouette
  local w = dist(run, drop)
  local a = math.deg(math.atan2(drop,run))
  w = drop == 0 and 1024 or w
  w = a < lastAngle and w + lastWidth or w
  local silhouette = display.newImageRect(imgDir .. "ground_256x256.png", w, 1024)
  silhouette.anchorX, silhouette.anchorY = 1, 0
  silhouette.rotation = a 
  silhouette.x, silhouette.y = x + run, y + drop
  silhouette:setFillColor(color.hex2rgb(groundColor))

  -- create a rail
  local rail
  if math.random(5) == 1 and run > 0 and not flat then
    rail = display.newLine(x, y, x, y-96, x + run - 6, y + drop-96, x + run - 6, y + drop)
    physics.addBody(rail, "static", { chain={ 0, -96, run, drop-96 }, friction = 0.0, bounce = 0 })
    rail.strokeWidth = 12
    rail:setStrokeColor(color.hex2rgb(groundColor))
    rail.isRail = true
    rail:toBack()

    -- make rail collision only happen from the top down w/ speed > 15
    function rail:preCollision(event)
      local _, y = event.x, math.floor(event.y)
      if event.contact and event.other.isBoard then 
        local vx, _ = event.other:getLinearVelocity()        
        if y < 9 or vx < 10 or event.other.isUpsideDown then
          event.contact.isEnabled = false
        else
          event.contact.bounce = 0
        end
      elseif event.other.isHero and event.contact then
        event.contact.isEnabled = false
      end
    end
    rail:addEventListener("preCollision")      
  end

  -- create some coins
  local coin
  if math.random(2) == 1 and run > 0  then
    coin = display.newRect(x+w/2, y-80 - (rail and 128 or 0), 24, 24)
    coin:rotate(45)
    coin = pickUp.new(coin)
  end

  -- put everything into the world
  instance:insert(ground)
  if rail then instance:insert(rail) end    
  instance:insert(silhouette)
  if coin then instance:insert(coin) end

  -- into the scrolling group
  world:insert(instance)

  -- remember last chunck
  lastWidth, lastAngle = w, silhouette.rotation

  return instance
end

return M
