-- game.scene.sparks 

-- Extends a image object to be a pickup

local M = {}

function M.new(object)

  local instance = display.newCircle(object.parent, object.x, object.y, 4)
  instance.isVisible = false
  instance._x = instance.x
  instance._y = instance.y
  
  local function enterFrame()
     display.remove(instance.line)
   if not (instance._x and instance._y and instance.x and instance.y) then
      Runtime:removeEventListener("enterFrame", enterFrame)  
      return
    end
    instance.line = display.newLine(object.parent, instance._x, instance._y, instance.x, instance.y)
    instance.line.strokeWidth = 8
    instance.frames = (instance.frames or 0) + 1
    object:toFront()
    if instance.frames > 90 then
      display.remove(instance)
    end
    instance._x = instance.x
    instance._y = instance.y
  end

  physics.addBody(instance, "dynamic", { radius = 1, bounce = 0.4, density = 13 , filter = { groupIndex = -1 }})
  instance:applyLinearImpulse(math.random()-0.85,math.random()-0.5)

  function instance:finalize()
    display.remove(instance.line)
    Runtime:removeEventListener("enterFrame", enterFrame)  
  end

  Runtime:addEventListener("enterFrame", enterFrame)  
  return instance
end

return M