-- game.scene.pickUp 

-- Extends a image object to be a pickup

local M = {}

local composer = require "composer"

function M.new(instance)
  local scene = composer.getScene(composer.getSceneName("current"))
  
  function instance:collision( event )

    local phase, other = event.phase, event.other
    local map = self.parent.parent -- assume the map is the parent's parent 

    if phase == "began" and event.other.isBoard then
      scene.score:add(100)
      local function remove() 
        display.remove(self)
      end
      self.strokeWidth = 4
      self:setFillColor(0 , 0 , 0, 0)
      transition.to( self, { alpha = 0, rotation = 90 + 45, xScale = 3, yScale = 3, time = 666, transition = easing.outQuad, 
          onComplete = remove
        })
    end
  end

  physics.addBody(instance, "dynamic", { isSensor = true })
  instance.gravityScale = 0
  instance:addEventListener("collision")

  timer.performWithDelay(33, function() 
      if instance.y then
        instance._y = instance.y 
        transition.from(instance, { y=(instance._y or instance.y)-16, transition=easing.outBounce, time=500, iterations=-1 })  
      end
    end)

  instance.isCoin = true

  return instance
end

return M