-- tiledObject template

-- Use this as a template to extend a tiled object with functionality

local M = {}

local function decodeTiledColor(hex)
  hex = hex or "#FF888888"
  hex = hex:gsub("#","")
  local function hexToFloat(part)
    part = part or "00"
    part = part == "" and "00" or part
    return tonumber("0x".. (part or "00")) / 255
  end
  local a, r, g, b =  hexToFloat(hex:sub(1,2)), hexToFloat(hex:sub(3,4)), hexToFloat(hex:sub(5,6)) , hexToFloat(hex:sub(7,8)) 
  return r,g,b,a
end

function M.new(instance)
  if not instance then error("ERROR: Expected display object") end  
  
  -- remember inital object
  local tiledObject = instance

  -- set defaults
  local text = tiledObject.text or " "
  local font = tiledObject.font or native.systemFont
  local size = tonumber(tiledObject.size or "20")
  local stroked = tiledObject.stroked
  local sr,sg,sb,sa = decodeTiledColor(tiledObject.strokeColor or "000000CC")
  local align = tiledObject.align or "center"
  local color = tiledObject.color or "FFFFFFFF"
  local params = { parent = tiledObject.parent,
    x = tiledObject.x, y = tiledObject.y,
    text = text, font = font, fontSize = size,
    align = align, width = tiledObject.width } 

  if stroked then
    local newStrokeColor = {
      highlight = { r=sr, g=sg, b=sb, a=sa },
      shadow = { r=sr, g=sg, b=sb, a=sa }
    }
    instance = display.newEmbossedText(params)
    instance:setFillColor(decodeTiledColor(color))
    instance:setEmbossColor(newStrokeColor)
  else
    instance = display.newText(params)
  end
  
  -- push the rest of the properties
  instance.rotation = tiledObject.rotation 
  instance.name = tiledObject.name 
  instance.type = tiledObject.type
  instance.alpha = tiledObject.alpha 
  
  display.remove(tiledObject)
  return instance
end

return M