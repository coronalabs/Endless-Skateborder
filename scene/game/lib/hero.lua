-- game.scene.hero 

-- Our hero class

local M = {}

local color = require "com.ponywolf.ponycolor"

function M.new(instance, heroColor)

  local top = display.newImageRect(instance.parent, "scene/game/img/body.png", 128, 128) -- create a hero top
  local bottom = display.newImageRect(instance.parent, "scene/game/img/legs.png", 128, 128) -- create a hero bottom
  top:setFillColor(color.hex2rgb(heroColor))
  bottom:setFillColor(color.hex2rgb(heroColor))

  instance.isHero = true
  instance.isVisible = false
  physics.addBody(top, "kinematic", { radius = 48, isSensor = true }) -- collector for our coins
  top.isBoard = true -- make sure we pickup the pickups
  
  local frame = 0
  function instance:animate(board, vx, vy)
    if vy < 0 then vy = 0 end
    if not self.wrecked then
      self.x, self.y = board.x, board.y -64 - (vy / 33) + math.abs(board.rotation/4)
      top.rotation = self.rotation + board.rotation / 6
      bottom.rotation = self.rotation + board.rotation / 3      
      frame = frame + 0.25 -- head bob
    end
    top.x, top.y = self.x, self.y + (math.sin(frame) * 1.5) - 1
    bottom.x, bottom.y = self.x, self.y  
  end

  function instance:reset()
    physics.removeBody(self)
    self.rotation = 0
    self.wrecked = false
  end

  function instance:collision(event)
    if event.other.isGround then
      self.linearDamping = 3.0
    end
  end

  function instance:crash(vx, vy)
    if not self.wrecked then     
      self.wrecked = true
      physics.addBody(self, { bounce = 0, radius = 32, friction = 1 , filter= { groupIndex = -1 } } )
      self:setLinearVelocity(vx ,vy)
      transition.to (top, { rotation = 70, time = 666, transition = easing.outQuad })
      transition.to (bottom, { rotation = 105, time = 333, transition = easing.outQuad })
      self:addEventListener("collision") 
    end
  end

  return instance
end

return M