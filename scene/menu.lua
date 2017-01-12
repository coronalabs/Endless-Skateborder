
-- Include modules/libraries
local composer = require( "composer" )
local fx = require( "com.ponywolf.ponyfx" )
local tiled = require( "com.ponywolf.ponytiled" )
local json = require( "json" )

-- Variables local to scene
local menu, bgMusic, ui

-- Create a new Composer scene
local scene = composer.newScene()

local function key(event)
	-- go back to menu if we are not already there
	if event.phase == "up" and event.keyName == "escape" then
		if not (composer.getSceneName("current") == "scene.menu") then
			fx.fadeOut(function ()
					composer.gotoScene("scene.menu")
				end)
		end
	end
end

-- This function is called when scene is created
function scene:create( event )

	local sceneGroup = self.view  -- Add scene display objects to this group

	-- stream music
	bgMusic = audio.loadStream( "scene/menu/sfx/titletheme.wav" )
	local buttonSound = audio.loadSound( "scene/game/sfx/bail.wav" )

	-- Load our UI
	local uiData = json.decodeFile( system.pathForFile( "scene/menu/ui/title.json", system.ResourceDirectory ) )
	menu = tiled.new( uiData, "scene/menu/ui" )
	menu.x, menu.y = display.contentCenterX - menu.designedWidth/2, display.contentCenterY - menu.designedHeight/2

	menu.extensions = "scene.menu.lib."
	menu:extend("button", "label")

	function ui(event)
		local phase = event.phase
		local name = event.buttonName
		print (phase, name)
		if phase == "released" then
			audio.play(buttonSound)
			if name == "start" then
				fx.fadeOut( function()
						composer.gotoScene( "scene.game", { params = {} } )
					end )
			elseif name == "help" then
				menu:findLayer( "help" ).isVisible = not menu:findLayer( "help" ).isVisible
			end
		end
		return true	
	end

	-- Transtion in logo
	transition.from( menu:findObject( "logo" ), { xScale = 2.5, yScale = 2.5, time = 333, transition = easing.outQuad } )

	-- Add streaks
	local streaks = fx.newStreak()
	streaks.x, streaks.y = display.contentCenterX, display.contentCenterY
	streaks:toBack()
	streaks.alpha = 0.1

	sceneGroup:insert( menu )

	-- escape key
	Runtime:addEventListener("key", key)
end

-- This function is called when scene comes fully on screen
function scene:show( event )
	local phase = event.phase
	if ( phase == "will" ) then
		fx.fadeIn()
	elseif ( phase == "did" ) then
		-- add UI listener
		Runtime:addEventListener( "ui", ui)		
		timer.performWithDelay( 10, function()
				audio.play( bgMusic, { loops = -1, channel = 2 } )
				audio.fade({ channel = 1, time = 333, volume = 1.0 } )
			end)	
	end
end

-- This function is called when scene goes fully off screen
function scene:hide( event )

	local phase = event.phase
	if ( phase == "will" ) then
		-- remove UI listener
		Runtime:removeEventListener( "ui", ui)		
	elseif ( phase == "did" ) then
		audio.fadeOut( { channel = 2, time = 1500 } )
	end
end

-- This function is called when scene is destroyed
function scene:destroy( event )
	audio.stop()  -- Stop all audio
	audio.dispose( bgMusic )  -- Release music handle
	Runtime:removeEventListener("key", key)
end

scene:addEventListener( "create" )
scene:addEventListener( "show" )
scene:addEventListener( "hide" )
scene:addEventListener( "destroy" )

return scene
