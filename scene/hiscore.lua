-- Requirements
local composer = require "composer"
local fx = require "com.ponywolf.ponyfx" 
local tiled = require "com.ponywolf.ponytiled"
local json = require "json" 

local hiscore, scores, ui

local function splitNum(line, separator)
  separator = separator or ","
  local items = {}
  for str in string.gmatch(line, "([^"..separator.."]+)") do
    items[#items+1] = tonumber(str or "0")
  end
  return items
end

-- Variables local to scene
local scene = composer.newScene()

function scene:create( event )
  local sceneGroup = self.view -- add display objects to this group

  -- Load our highscore tiled map
  local uiData = json.decodeFile( system.pathForFile( "scene/menu/ui/highScore.json", system.ResourceDirectory ) )
  hiscore = tiled.new( uiData, "scene/menu/ui" )
  hiscore.x, hiscore.y = display.contentCenterX - hiscore.designedWidth/2, display.contentCenterY - hiscore.designedHeight/2
  hiscore.extensions = "scene.menu.lib."
  hiscore:extend("button", "label")

  function ui(event)
    local phase = event.phase
    local name = event.buttonName
    print (phase, name)
    if phase == "released" then 
      if name == "restart" then
        fx.fadeOut( function()
            composer.hideOverlay()
            composer.gotoScene( "scene.refresh", { params = {} } )
          end )
      end
    end
    return true	
  end

  sceneGroup:insert(hiscore)

end

function scene:show( event )
  local phase = event.phase
  local params = event.params or {}
  if ( phase == "will" ) then
    -- refesh scores
    scores = system.getPreference( "app", "scores", "string" )
    scores = splitNum(scores)
    print (scores[1],scores[2],scores[3],scores[4])    
    -- update in UI
    scores[4] = params.myScore -- add my score into the mix
    print (scores[1],scores[2],scores[3],scores[4])    
    table.sort(scores, function(a, b) return tonumber(a) > tonumber(b) end) -- sort the scores
    print (scores[1],scores[2],scores[3],scores[4])
    for i = 1, 3 do -- take the top three
      hiscore:findObject("score"..i).text = scores[i]-- put them in the UI
    end
    hiscore:findObject("myScore").text = params.myScore -- note myScore  
  elseif ( phase == "did" ) then
		Runtime:addEventListener( "ui", ui)		    
  end
end

function scene:hide( event )
  local phase = event.phase
  if ( phase == "will" ) then
		Runtime:removeEventListener( "ui", ui)		    
    local appPreferences = { scores = table.concat(scores, "," ) }
    system.setPreferences( "app", appPreferences )
  elseif ( phase == "did" ) then

  end
end

function scene:destroy( event )
  --collectgarbage()
end

scene:addEventListener("create")
scene:addEventListener("show")
scene:addEventListener("hide")
scene:addEventListener("destroy")

return scene