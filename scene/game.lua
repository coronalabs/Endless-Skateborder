-- Requirements
local composer = require "composer"
local color = require "com.ponywolf.ponycolor"
local physics = require "physics"
local terrains = require "scene.game.lib.terrain"
local boards = require "scene.game.lib.board"
local heroes = require "scene.game.lib.hero"
local sparks = require "scene.game.lib.sparks"
local fx = require "com.ponywolf.ponyfx" 
local scoring = require "scene.game.lib.score" 

-- Variables local to scene
local scene = composer.newScene()
local topSpeed = 1250
local world, board, hero, buildings, background
local terrain, terrainCount, spawnTerrain = {}, 1
local restart, back

function math.clamp(val, min, max) return math.min(math.max(val, min), max) end

local function offScreen(object)
	local bounds = object.contentBounds
	local sox, soy = display.screenOriginX, display.screenOriginY
	if bounds.xMax < sox then return true end
	if bounds.yMax < soy then return true end
	if bounds.xMin > display.actualContentWidth - sox then return true end
	if bounds.yMin > display.actualContentHeight - soy then return true end
	return false
end

function scene:create( event )

	local sceneGroup = self.view -- add display objects to this group
	physics.start()
	physics.setGravity(0,32)

	local sndDir = "scene/game/sfx/"
	scene.sounds = {
		bail = audio.loadSound( sndDir .. "bail.mp3" ),
		jump = audio.loadSound( sndDir .. "jump.mp3" ),
		land = audio.loadSound( sndDir .. "land.mp3" ),
		grind = audio.loadSound( sndDir .. "grind.mp3" ),
		push = audio.loadSound( sndDir .. "push.mp3" ),
		ride = audio.loadSound( sndDir .. "ride.mp3" ),
		coin = audio.loadSound( sndDir .. "coin.mp3" ),  
		thud = audio.loadSound( sndDir .. "thud.mp3" ),  
		ouch = audio.loadSound( sndDir .. "ouch.mp3" ),  
		city = audio.loadSound( sndDir .. "loops/city.mp3" ),			
	}

	-- build a random background
	background = display.newGroup() -- this will hold our background
	sceneGroup:insert(background)

	-- add some of our buildings to the background layer
	for _ = 1, 10 do 
		local buildingImages = { "scene/game/img/row1A.png", "scene/game/img/row1B.png", "scene/game/img/row1C.png" }
		local building = display.newImageRect(background, buildingImages[math.random(#buildingImages)],512,512)
		building.anchorX, building.anchorY = 0.5, 1
		building.x, building.y = math.random(display.actualContentWidth*3), display.actualContentHeight
		building._xScale = math.random()/2 + 0.75
		building.xScale, building.yScale = building._xScale, building._xScale    
		building:setFillColor(color.hex2rgb("6D9DC5"))
	end

	-- the "world" group is our scrolling layer
	world = display.newGroup() -- this will hold our world
	sceneGroup:insert(world)

	-- make a hero
	hero = display.newRect(world, 0, 0, 128, 128) -- create our hero object in our world
	hero = heroes.new(hero, "00272B")

	-- make a skateboard
	board = display.newImageRect(world, "scene/game/img/board_256x64.png",128, 32) -- create a skateboard object in our world
	board = boards.new(board, "00272B")

	-- these buildings ar the closer parallax layer
	buildings = display.newGroup() -- this will hold our buildings
	world:insert(buildings)

	-- create our first bit of world terrain
	terrain[1] = terrains.new(world, buildings, board.x - 128, board.y + 128, true)

	-- makes new, random ground in front of the player, see the terrain.lua class 
	function spawnTerrain()
		local x,y = terrain[#terrain][1].x, terrain[#terrain][1].y
		local run, drop = terrain[#terrain].run, terrain[#terrain].drop
		terrain[#terrain+1] = terrains.new(world, buildings, x+run, y+drop)
		terrain[#terrain]:toBack()
	end

	-- start with 54 "chunks"
	for _=1, 54 do spawnTerrain() end

	local scoreBar = display.newImageRect( sceneGroup, "scene/game/img/ui/scoreBar.png", 384, 192 )  
	scoreBar.x = -display.screenOriginX + display.contentWidth - scoreBar.contentWidth / 2
	scoreBar.y = display.screenOriginY + scoreBar.contentHeight / 2 + 8  

	-- Add our restart button 
	restart = display.newImageRect( sceneGroup, "scene/game/img/ui/replayButton.png", 80, 64 )
	restart.x = -display.screenOriginX + display.contentWidth - restart.contentWidth / 2 - 22
	restart.y = display.screenOriginY + restart.contentHeight / 2 + 18
	restart:setFillColor(0,0,0)

	-- Touch the restart...
	function restart:tap(event)
		self:removeEventListener("tap")
		audio.play(scene.sounds.bail)		
		fx.fadeOut( function()
				composer.gotoScene( "scene.refresh")
			end )
	end

	-- Add our back button 
	back = display.newImageRect( sceneGroup, "scene/game/img/ui/playButton.png", 70, 87 )
	back.x = display.screenOriginX + back.contentWidth / 2 + 22
	back.y = display.screenOriginY + back.contentHeight / 2 + 18
	back.xScale = -1

	-- Touch the back...
	function back:tap(event)
		self:removeEventListener("tap")
		audio.play(scene.sounds.bail)
		fx.fadeOut( function()
				composer.gotoScene( "scene.menu")
			end )
	end

	-- Add our score module 
	scene.score = scoring.new()
	local score = scene.score
	score.x = -display.screenOriginX + display.contentWidth - score.contentWidth / 2 - 32 - restart.width
	score.y = display.screenOriginY + score.height / 2 + 8

	sceneGroup:insert(score)

end

local worldScale = 1
local function enterFrame(event)
	if not board.getLinearVelocity then return false end
	local vx, vy = board:getLinearVelocity()

	-- remove old terrain
	local x = terrain[terrainCount].contentBounds.xMax
	if x < -display.actualContentWidth * 2 then
		display.remove(terrain[terrainCount])
		terrainCount = terrainCount + 1
		spawnTerrain()
	end

	-- recycle old buildings (pass 1)
	for i = 1, buildings.numChildren do 
		local x = buildings[i] and buildings[i].contentBounds.xMax or 0
		--if buildings[i] then buildings[i]:translate(-vx/topSpeed*6,0) end
		if x < -display.actualContentWidth then
			display.remove(buildings[i])
		end
	end

	-- recycle old buildings (pass 2)
	for i = 1, background.numChildren do 
		background[i].rotation = world.rotation * 0.85
		background[i].xScale, background[i].yScale = background[i]._xScale + (worldScale / 2),background[i]._xScale + (worldScale / 2) 
		background[i].x = background[i].x - (6 * (vx / topSpeed) * background[i].xScale )
		local x = background[i].contentBounds.xMax
		if x < -display.actualContentWidth then
			background[i]:translate(display.actualContentWidth*3,0)
		end
	end

	-- how fast are we going?
	if vx > topSpeed then vx = topSpeed end -- terminal velocity
	board:setLinearVelocity(vx,vy)
	
	-- increase volume of wheels based on speed (vx)
	audio.fade( {channel = 3, time = 10, volume = (math.max(vx/topSpeed)-0.5) })	

	-- did the board flip?
	if board.rotation % 360 > 90 and board.rotation % 360 < 270 then 
		board.isUpsideDown = true
		hero:crash(vx, vy)
	end

	-- if we are upside down then timeout to restart?
	if board.isUpsideDown then
		board.timeout = board.timeout + 1
		if (board.timeout > 90) or offScreen(board) then
			Runtime:removeEventListener("enterFrame", enterFrame)
			composer.showOverlay("scene.hiscore", { isModal = true, effect = "fromTop",  params = { myScore = scene.score:get() }} )
		end
	else
		if board.pump and not board.inAir then
			board:applyForce( 0.56, 0, board.x, board.y )
		end
		if board.level then
			board.rotation = board.rotation * 0.75 
		end
		board.timeout = 0
	end

	-- slow down if we are not in the air
	board.linearDamping = board.inAir and 0.15 or 0.01
	board.linearDamping = (board.isUpsideDown and not board.inAir) and 1.95 or board.linearDamping 

	-- sparks
	if board.isSparking then
		-- you can use this sparks class to make any display object spark
		sparks.new(board)
		-- add a bit of randomness with a 2nd spark
		if math.random() < 0.5 then sparks.new(board) end
	end

	-- animate hero
	hero:animate(board, vx, vy)

	-- zoom/rotate
	if board.isUpsideDown then 
		worldScale = worldScale + 0.005
	else
		worldScale = 0.5 * (worldScale + 0.5 * (2 - (vx / topSpeed)))
	end

	-- keep our scale between 0.5 and 1.0
	worldScale = math.clamp(worldScale, 0.60, 1.0)
	world.xScale, world.yScale = worldScale, worldScale

	-- rotate the world based on the scale
	world.rotation = 10 - (worldScale * 10)

	-- easiest way to scroll a map based on a character
	-- find the difference between the hero and the display center
	-- and move the world to compensate
	local hx, hy = hero:localToContent(0,0)
	hx, hy = display.contentCenterX/2 - hx, display.contentCenterY - hy
	world.x, world.y = world.x + hx, world.y + hy
end  

function scene:show( event )
	local phase = event.phase
	if ( phase == "will" ) then
		Runtime:addEventListener("enterFrame", enterFrame)
		fx.fadeIn()
		display.setDefault("background", color.hex2rgb("7CC6FE") )  
	elseif ( phase == "did" ) then
		audio.play(self.sounds.city, { loops = -1, fadein = 750, channel = 1 } )
		audio.play(self.sounds.ride, { loops = -1, fadein = 750, channel = 3 } )		
		restart:addEventListener("tap")
		back:addEventListener("tap")
	end
end

function scene:hide( event )
	local phase = event.phase
	if ( phase == "will" ) then
		audio.fadeOut( { time = 1000 })
	elseif ( phase == "did" ) then
		Runtime:removeEventListener("enterFrame", enterFrame)
	end
end

function scene:destroy( event )
	audio.stop()
	for s,v in pairs( self.sounds ) do
		audio.dispose( v )
		self.sounds[s] = nil
	end
end


scene:addEventListener("create")
scene:addEventListener("show")
scene:addEventListener("hide")
scene:addEventListener("destroy")

return scene