local M = {}

function M.hex2rgb(hex)
  local function hex2float(num,a,b)
    return tonumber("0x"..hex:sub(a,b)) / 255
  end
  hex = hex:gsub("#","")
  if string.len(hex) == 3 then
    return hex2float(hex,1,1) * 17, hex2float(hex,2,2) * 17, hex2float(hex,3,3) * 17
  elseif string.len(hex) == 6 then
    return hex2float(hex,1,2), hex2float(hex,3,4), hex2float(hex,5,6), 1
  elseif string.len(hex) == 8 then
    return hex2float(hex,1,2), hex2float(hex,3,4), hex2float(hex,5,6), hex2float(hex,7,8)
  end
end

function M.hls2rgb(h, l, s, a)
  local r, g, b, q, p
  local third = 1/3 -- or 0.3333  
  local function hue2rgb(p, q, t)
    if t < 0   then t = t + 1 end
    if t > 1   then t = t - 1 end
    if t < 1/6 then return p + (q - p) * 6 * t end
    if t < 1/2 then return q end
    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
    return p
  end  
  if s == 0 then
    r, g, b = l, l, l
  else
    if l < 0.5 then
      q = l * (1 + s)
    else
      q = l + s - l * s
    end
    p = 2 * l - q
  end
  return hue2rgb(p, q, h + third), hue2rgb(p, q, h), hue2rgb(p, q, h - third), a or 1
end

return M