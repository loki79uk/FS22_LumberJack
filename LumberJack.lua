-- ============================================================= --
-- LUMBERJACK MOD
-- ============================================================= --
LumberJack = {}
LumberJack.name = g_currentModName
LumberJack.path = g_currentModDirectory
LumberJack.cutAnywhere = true
LumberJack.createWoodchips = false
LumberJack.superStrength = false
LumberJack.lockStrength = false
LumberJack.doubleTap = 0
LumberJack.doubleTapTime = 0
LumberJack.doubleTapThreshold = 500
LumberJack.superStrengthValue = 1000
LumberJack.normalStrengthValue = 0.2
LumberJack.superDistanceValue = 12
LumberJack.normalDistanceValue = 3
LumberJack.maxWalkingSpeed = 4
LumberJack.maxRunningSpeed = 9
LumberJack.minCutDistance = 0.1
LumberJack.maxCutDistance = 6.0
LumberJack.defaultCutDuration = 4
LumberJack.stumpGrindingTime = 0
LumberJack.stumpGrindingFlag = false
LumberJack.useChainsawFlag = false
LumberJack.splitShape = 0
LumberJack.maxWoodchips = 2000
LumberJack.showDebug = true
LumberJack.initialised = false

source(g_currentModDirectory .. 'LumberJackSettings.lua')
source(g_currentModDirectory .. 'events/DeleteShapeEvent.lua')
source(g_currentModDirectory .. 'events/ToggleSawdustEvent.lua')
source(g_currentModDirectory .. 'events/CreateSawdustEvent.lua')
source(g_currentModDirectory .. 'events/SuperStrengthEvent.lua')

addModEventListener(LumberJack)

-- ALLOW CHAINSAW CUTTING ANYWHERE ON THE MAP
function LumberJack:isCuttingAllowed(superFunc, x, y, z, shape)
	local canCutTrees = g_currentMission:getHasPlayerPermission("cutTrees")
	local canChainsaw = g_currentMission:getHasPlayerPermission("chainsawSettings")
	local canAccess = g_currentMission.accessHandler:canFarmAccessLand(self.player.farmId, x, z)
	
	return canCutTrees and ((canChainsaw and LumberJack.cutAnywhere) or canAccess)
end

-- DETECT SPLITSHAPES FROM CHAINSAW CALLBACK
function LumberJack:cutRaycastCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= 0 and hitObjectId ~= nil then
		if LumberJack.hitObjectId ~= hitObjectId then
			if getHasClassId(hitObjectId, ClassIds.MESH_SPLIT_SHAPE) then
				-- print("hitObjectId: " .. hitObjectId)
				LumberJack.hitObjectId = hitObjectId
			else
				LumberJack.hitObjectId = 0
			end
		end
	end
end

function LumberJack:updateCutRaycast()
	if self.cutFocusDistance == -1 then
		LumberJack.hitObjectId = 0
	end
end

-- NEW ALTERNATIVE TO "FIND SPLIT SHAPE"
function LumberJack:setSplitShape(rigidBodyType)
	local objectId = LumberJack.hitObjectId
	
	if objectId~=nil and objectId~=0 and entityExists(objectId) 
	and getRigidBodyType(objectId) == rigidBodyType then
		if LumberJack.splitShape ~= objectId then
			local isSplit = getIsSplitShapeSplit(objectId)
			print("SET ObjectId = " .. objectId)
			LumberJack.splitShape = objectId
		end
	else
		if LumberJack.splitShape ~= 0 then
			print("RESET " .. tostring(LumberJack.splitShape))
			LumberJack.splitShape = 0
		end
	end
end

-- ALLOW TREE SPRAYING ANYWHERE ON THE MAP
function LumberJack:isSprayingAllowed(superFunc, shape)
	return g_currentMission:getHasPlayerPermission("cutTrees")
end

-- ADD SHORTCUT KEY SELECTION TO OPTIONS MENU
function LumberJack:registerActionEvents()
	local _, actionEventId = g_inputBinding:registerActionEvent('LUMBERJACK_STRENGTH', self, LumberJack.toggleStrength, true, true, false, true)
	g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
	g_inputBinding:setActionEventActive(actionEventId, true)
    g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("menu_TOGGLE_STRENGTH"))
end

--REPLACE Player.MAX_PICKABLE_OBJECT_DISTANCE FOR CLIENT IN MULTIPLAYER
function LumberJack.playerCheckObjectInRange(self, superFunc)

	if LumberJack.originalPickableObjectDistance == nil then
		LumberJack.originalPickableObjectDistance = Player.MAX_PICKABLE_OBJECT_DISTANCE
	end

	if self.maxPickableObjectDistance ~= nil then
		if g_currentMission:getHasPlayerPermission("superStrength") then
			Player.MAX_PICKABLE_OBJECT_DISTANCE = self.maxPickableObjectDistance
		else
			Player.MAX_PICKABLE_OBJECT_DISTANCE = LumberJack.originalPickableObjectDistance
		end
	end
	
	return superFunc(self)
end

--REPLACE Player.motionInformation.maxWalkingSpeed
function LumberJack.playerGetDesiredSpeed(self, superFunc)

	if LumberJack.originalWalkingSpeed == nil then
		LumberJack.originalWalkingSpeed = self.motionInformation.maxWalkingSpeed
		LumberJack.originalRunningSpeed = self.motionInformation.maxRunningSpeed
	end
	
	if g_currentMission:getHasPlayerPermission("superSpeed") then
		self.motionInformation.maxRunningSpeed = LumberJack.maxRunningSpeed
		if self:hasHandtoolEquipped() and self.inputInformation.runAxis > 0 then
			self.motionInformation.maxWalkingSpeed = LumberJack.maxRunningSpeed
		else
			self.motionInformation.maxWalkingSpeed = LumberJack.maxWalkingSpeed
		end
	else
		self.motionInformation.maxWalkingSpeed = LumberJack.originalWalkingSpeed
		self.motionInformation.maxRunningSpeed = LumberJack.originalRunningSpeed
	end
	
	return superFunc(self)
end

-- DETECT SUPER STRENGTH CONSOLE COMMAND
function LumberJack.playerConsoleCommand(self, superFunc)
	superFunc(self)
	if g_currentMission.player.superStrengthEnabled then
		LumberJack.lockStrength = true
		LumberJack.superStrength = true
		g_currentMission.player.maxPickableMass = LumberJack.superStrengthValue
		g_currentMission.player.maxPickableObjectDistance = LumberJack.superDistanceValue
	else
		LumberJack.lockStrength = false
		LumberJack.superStrength = false
		g_currentMission.player.maxPickableMass = LumberJack.normalStrengthValue
		g_currentMission.player.maxPickableObjectDistance = LumberJack.normalDistanceValue
	end
end

-- LUMBERJACK FUNCTIONS:
function LumberJack:loadMap(name)
	--print("Load Mod: 'LumberJack'")
	
	-- ALLOW CHAINSAW CUTTING ANYWHERE ON THE MAP
	Chainsaw.isCuttingAllowed = Utils.overwrittenFunction(Chainsaw.isCuttingAllowed, LumberJack.isCuttingAllowed)
	
	-- ALLOW TREE SPRAYING ANYWHERE ON THE MAP
	if pdlc_forestryPack~=nil and pdlc_forestryPack.SprayCan~=nil then
		pdlc_forestryPack.SprayCan.getIsSprayingAllowed = Utils.overwrittenFunction(pdlc_forestryPack.SprayCan.getIsSprayingAllowed, LumberJack.isSprayingAllowed)
	end

	-- GET OBJECT FROM CHAINSAW RAYCAST
	Chainsaw.updateCutRaycast = Utils.appendedFunction(Chainsaw.updateCutRaycast, LumberJack.updateCutRaycast)
	Chainsaw.cutRaycastCallback = Utils.appendedFunction(Chainsaw.cutRaycastCallback, LumberJack.cutRaycastCallback)
	
	-- ADD SHORTCUT KEY SELECTION TO OPTIONS MENU
	Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, LumberJack.registerActionEvents)
	
	-- MULTIPLAYER SUPER STRENGTH FIX
	Player.checkObjectInRange = Utils.overwrittenFunction(Player.checkObjectInRange, LumberJack.playerCheckObjectInRange)
	
	-- CATCH CONSOLE COMMAND
	Player.consoleCommandToggleSuperStrongMode = Utils.overwrittenFunction(Player.consoleCommandToggleSuperStrongMode, LumberJack.playerConsoleCommand)
	
	--READ SETTINGS FROM FILE
	LumberJack.readSettings()

end

function LumberJack:toggleStrength(name, state)
	if g_currentMission.player.isEntered and not g_gui:getIsGuiVisible() then
	
		if g_currentMission:getHasPlayerPermission("superStrength") then

			if state == 1 then
				LumberJack.doubleTap = LumberJack.doubleTap + 1
			end
			
			if LumberJack.lockStrength then
				--print("SUPER STRENGTH LOCKED")
			else
				if LumberJack.superStrength then
					if state == 0 then
						--print("SUPER STRENGTH OFF")
						LumberJack.superStrength = false
						SuperStrengthEvent.sendEvent(LumberJack.superStrength)
					end
				else
					if state == 1 then
						--print("SUPER STRENGTH ON")
						LumberJack.superStrength = true
						SuperStrengthEvent.sendEvent(LumberJack.superStrength)
					end
				end
			end
			
		else
			if LumberJack.superStrength or LumberJack.lockStrength then
				LumberJack.lockStrength = false
				LumberJack.superStrength = false
				SuperStrengthEvent.sendEvent(LumberJack.superStrength)
			end
		end
		
	end
end

function LumberJack:drawDebug(hTool)
	if LumberJack.showDebug then
		local r = hTool.ringSelectorScaleOffset
		local xx0,xy0,xz0 = 1,0,0
		local yx0,yy0,yz0 = 0,1,0
		local zx0,zy0,zz0 = 0,0,1
		local x,y,z = getWorldTranslation(hTool.chainsawSplitShapeFocus)
		local xx,xy,xz = localDirectionToWorld(hTool.chainsawSplitShapeFocus, xx0,xy0,xz0)
		local yx,yy,yz = localDirectionToWorld(hTool.chainsawSplitShapeFocus, yx0,yy0,yz0)
		local zx,zy,zz = localDirectionToWorld(hTool.chainsawSplitShapeFocus, zx0,zy0,zz0)
		local x0 = x + yx*2*r + zx*r
		local y0 = y + yy*2*r + zy*r
		local z0 = z + yz*2*r + zz*r
		Utils.renderTextAtWorldPosition(x0-xx0*r,y0-xy0*r,z0-xz0*r, "-x", getCorrectTextSize(0.012), 0)
		Utils.renderTextAtWorldPosition(x0+xx0*r,y0+xy0*r,z0+xz0*r, "+x", getCorrectTextSize(0.012), 0)
		Utils.renderTextAtWorldPosition(x0-yx0*r,y0-yy0*r,z0-yz0*r, "-y", getCorrectTextSize(0.012), 0)
		Utils.renderTextAtWorldPosition(x0+yx0*r,y0+yy0*r,z0+yz0*r, "+y", getCorrectTextSize(0.012), 0)
		Utils.renderTextAtWorldPosition(x0-zx0*r,y0-zy0*r,z0-zz0*r, "-z", getCorrectTextSize(0.012), 0)
		Utils.renderTextAtWorldPosition(x0+zx0*r,y0+zy0*r,z0+zz0*r, "+z", getCorrectTextSize(0.012), 0)
		drawDebugLine(x0-xx0*r,y0-xy0*r,z0-xz0*r,1,1,1,x0+xx0*r,y0+xy0*r,z0+xz0*r,1,1,1)
		drawDebugLine(x0-yx0*r,y0-yy0*r,z0-yz0*r,1,1,1,x0+yx0*r,y0+yy0*r,z0+yz0*r,1,1,1)
		drawDebugLine(x0-zx0*r,y0-zy0*r,z0-zz0*r,1,1,1,x0+zx0*r,y0+zy0*r,z0+zz0*r,1,1,1)
	end
end

function LumberJack:resetRingSelectorRaycastCallback(hitObjectId, x0, y0, z0, distance)
	local x1,y1,z1 = getWorldTranslation(g_currentMission.player.rootNode)
	LumberJack.chainsawCameraFocus = {x0, y0, z0}
	if LumberJack.showDebug then
		--print("RAYCAST: " .. x0 ..", " .. y0 .. ", " .. z0)
		drawDebugLine(x0,y0,z0,0,1,1,x1,y1,z1,0,1,1)
	end
end

function LumberJack.drawDebugRingSelector(x0, y0, z0, x1, y1, z1, r, g, b)
	r, g, b = r or 1, g or 1, b or 1
	if LumberJack.showDebug then
		drawDebugLine(x0,y0,z0,r,g,b,x1,y1-0.005,z1,r,g,b)
		drawDebugLine(x0,y0,z0,r,g,b,x1,y1+0.005,z1,r,g,b)
	end
end

function LumberJack.moveRingSelector(hTool, x0, y0, z0)
	LumberJack.moveChainsawCameraFocus(hTool, x0, y0, z0)
	local x,y,z = worldToLocal(getParent(hTool.ringSelector), x0,y0,z0)
	setTranslation(hTool.ringSelector, x,y,z)
	setScale(hTool.ringSelector, 1, 1, 1)
end

function LumberJack.moveChainsawCameraFocus(hTool, x0, y0, z0)
	local x,y,z = worldToLocal(getParent(hTool.chainsawCameraFocus), x0,y0,z0)
	setTranslation(hTool.chainsawCameraFocus, x,y,z)
end

function LumberJack.updateRingSelector(hTool, dt)
	
	if hTool == nil then
		return
	end

	local x0,y0,z0 = getWorldTranslation(hTool.chainsawCameraFocus)
	local x1,y1,z1 = getWorldTranslation(hTool.player.cameraNode)

	if x0==0 and y0==0 and z0==0 then

		local x, y, z = getWorldTranslation(hTool.player.cameraNode)
		local dx, dy, dz = unProject(0.52, 0.4, 1)
		dx, dy, dz = MathUtil.vector3Normalize(dx, dy, dz)
		local collisionMask = CollisionFlag.STATIC_WORLD + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER
		raycastClosest(x, y, z, dx, dy, dz, "resetRingSelectorRaycastCallback", hTool.cutDetectionDistance, LumberJack, collisionMask)	
		
		local dx0, dy0, dz0 = unProject(0.52, 0.4, 1)
		x0 = (LumberJack.chainsawCameraFocus[1] or 0) + dx0
		y0 = (LumberJack.chainsawCameraFocus[2] or 0) + dy0
		z0 = (LumberJack.chainsawCameraFocus[3] or 0) + dz0

		local distance = math.sqrt((x1-x0)^2 + (y1-y0)^2 + (z1-z0)^2)
		local r = hTool.cutDetectionDistance/distance
		x0 = r*x0 + (1-r)*x1
		y0 = r*y0 + (1-r)*y1
		z0 = r*z0 + (1-r)*z1
		--print("LINE OF SIGHT: " .. x0 ..", " .. y0 .. ", " .. z0)
		
		LumberJack.moveRingSelector(hTool, x0, y0, z0)
		LumberJack.drawDebugRingSelector(x0, y0, z0, x1, y1, z1, 1, 0, 0)

	else
		
		local Y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x0,y0,z0)
		if y0 < Y+0.01 then
			y0 = Y+0.01
			LumberJack.moveRingSelector(hTool, x0, y0, z0)
		end
		
		LumberJack.drawDebugRingSelector(x0, y0, z0, x1, y1, z1, 0, 0, 1)
		LumberJack.chainsawCameraFocus = {x0, y0, z0}
	end
	
	setVisibility(hTool.ringSelector, true)
	
	local distance = math.sqrt((x1-x0)^2 + (y1-y0)^2 + (z1-z0)^2)
	local d = distance/hTool.cutDetectionDistance
	print("D: " .. d)
	
	setShaderParameter(hTool.ringSelector, "colorScale", 1, 1, 1, 1.0, false)
	
end

function LumberJack:update(dt)
	-- Dedicated Server has no player
	if g_currentMission.player==nil or g_currentMission.player.controllerIndex==0 then
		return
	end

	if g_currentMission.player.isEntered and not g_gui:getIsGuiVisible() then
	
		-- CHANGE GLOBAL VALUES ON FIRST RUN
		if (g_gameStateManager:getGameState()==GameState.PLAY and LumberJack.initialised==false) then
			-- print("*** LumberJack - DEV VERSION ***")
		
			LumberJack.playerID = g_currentMission.player.controllerIndex
			g_currentMission.player.maxPickableMass = LumberJack.normalStrengthValue
			g_currentMission.player.maxPickableObjectDistance = LumberJack.normalDistanceValue
			
			-- enable active objects debugging output:
			if LumberJack.showDebug then
				if g_currentMission:getIsServer() then
					g_server.showActiveObjects = true
				end
			end

			if g_modIsLoaded['FS22_PlayerSpeed']
			or g_modIsLoaded['FS22_QuickCamera']
			then
				print("LUMBERJACK SPEED DISABLED")
				LumberJack.menuItems.maxWalkingSpeed = nil
				LumberJack.menuItems.maxRunningSpeed = nil
				LumberJack.SETTINGS.maxWalkingSpeed.disabled = true
				LumberJack.SETTINGS.maxRunningSpeed.disabled = true
			else
				-- change values from default
				Player.getDesiredSpeed = Utils.overwrittenFunction(
					Player.getDesiredSpeed, LumberJack.playerGetDesiredSpeed)
			end

			LumberJack.initialised = true
		end

		-- DETECT DOUBLE TAP SUPER STRENGTH KEY
		if LumberJack.doubleTap ~= 0 then
			if LumberJack.doubleTap == 1 then
				LumberJack.doubleTapTime = LumberJack.doubleTapTime + dt
				if LumberJack.doubleTapTime > LumberJack.doubleTapThreshold then
					LumberJack.doubleTap = 0
					LumberJack.doubleTapTime = 0
				end
			else
				--print("DOUBLE TAP")
				LumberJack.lockStrength = not LumberJack.lockStrength
				LumberJack.doubleTap = 0
				LumberJack.doubleTapTime = 0
			end
		end

		-- IF OBSERVING AN OBJECT
		if g_currentMission.player.isObjectInRange then
			-- Display Mass of LAST OBSERVED OBJECT in 'F1' Help Menu
			if not g_currentMission.player:hasHandtoolEquipped() then
				g_currentMission:addExtraPrintText(g_i18n:getText("text_MASS") .. string.format(": %.1f ", 1000*g_currentMission.player.lastFoundObjectMass) .. g_i18n:getText("text_KG"))
			end
		end

		-- CHANGE COLOUR OF THE CURSOR/HAND ICON
		if LumberJack.superStrength then
			-- Make hand BRIGHTER when super strength is ON
			g_currentMission.player.aimOverlay:setColor(1, 1, 1, 1.0)
			g_currentMission.player.pickedUpObjectOverlay:setColor(1, 1, 1, 1.0)
		else
			if g_currentMission.player.isObjectInRange and g_currentMission.player.lastFoundObjectMass > g_currentMission.player.maxPickableMass then
				-- Make hand RED when objects are too heavy to pick up
				g_currentMission.player.pickedUpObjectOverlay:setColor(1.0, 0.1, 0.1, 0.5)
			else
				-- Make cursor/hand GREY for everything else
				g_currentMission.player.pickedUpObjectOverlay:setColor(1, 1, 1, 0.3)
			end
			g_currentMission.player.aimOverlay:setColor(1, 1, 1, 0.3)
		end
		
		-- DESTROY SMALL LOGS WHEN USING THE CHAINSAW --
		if g_currentMission.player:hasHandtoolEquipped() then
			local hTool = g_currentMission.player.baseInformation.currentHandtool
		
			if hTool ~= nil and hTool.ringSelector ~= nil and hTool.chainsawSplitShapeFocus ~= nil then
			
				if not LumberJack.equipChainsawFlag then
					-- RESET WHEN USING A CHAINSAW FOR THE FIRST TIME
					LumberJack.equipChainsawFlag = true
					LumberJack.moveRingSelector(hTool, 0, 0, 0)
					LumberJack.updateRingSelector(hTool, dt)
				end
			
				if LumberJack.originalDefaultCutDuration == nil then
					LumberJack.originalDefaultCutDuration = hTool.defaultCutDuration
					LumberJack.originalMinCutDistance = hTool.minCutDistance
					LumberJack.originalMaxCutDistance = hTool.maxCutDistance
					LumberJack.originalMaxModelTranslation = hTool.maxModelTranslation
					LumberJack.originalCutDetectionDistance = hTool.cutDetectionDistance
				end
			
				if g_currentMission:getHasPlayerPermission('chainsawSettings') then
					-- INCREASE CUTTING SPEED
					hTool.defaultCutDuration = LumberJack.defaultCutDuration
					
					-- INCREASE CUT DISTANCE
					hTool.minCutDistance = LumberJack.minCutDistance
					hTool.maxCutDistance = LumberJack.maxCutDistance
					hTool.maxModelTranslation = LumberJack.maxCutDistance
					if LumberJack.maxCutDistance < LumberJack.originalCutDetectionDistance then
						hTool.cutDetectionDistance = LumberJack.originalCutDetectionDistance
					else
						hTool.cutDetectionDistance = LumberJack.maxCutDistance
					end
				else
					hTool.defaultCutDuration = LumberJack.originalDefaultCutDuration
					hTool.minCutDistance = LumberJack.originalMinCutDistance
					hTool.maxCutDistance = LumberJack.originalMaxCutDistance
					hTool.maxModelTranslation = LumberJack.originalMaxModelTranslation
					hTool.cutDetectionDistance = LumberJack.originalCutDetectionDistance
				end
				
				-- DESTROY SMALL LOGS WHEN USING THE CHAINSAW --
				if hTool.isCutting then
					--print("CHAINSAW CUTTING")				
					if not LumberJack.useChainsawFlag then
						LumberJack:setSplitShape(RigidBodyType.DYNAMIC)
						if LumberJack.splitShape~=0 and entityExists(LumberJack.splitShape) then
							local splitShape = LumberJack.splitShape
							if getVolume(splitShape) < 0.100 then
							-- DELETE THE SHAPE if too small to worry about (e.g. felling wedge or thin branch)
								LumberJack:deleteSplitShape(splitShape)
							end
						end
						LumberJack.useChainsawFlag = true
					end
					
					LumberJack:createSawdust(hTool)

				else
					--print("CHAINSAW NOT CUTTING")		
					if hTool.ringSelector ~= nil and hTool.ringSelector ~= 0 then	
						if getVisibility(hTool.ringSelector) == false then
						
							--setVisibility(hTool.ringSelector, true)
							LumberJack.updateRingSelector(hTool, dt)

							LumberJack:setSplitShape(RigidBodyType.STATIC)
							if LumberJack.splitShape~=0 and entityExists(LumberJack.splitShape) then
								if LumberJack.superStrength then
									LumberJack.stumpGrindingFlag = true
								else
									local x0,y0,z0 = getWorldTranslation(LumberJack.splitShape)
									local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x0, y0, z0)
									local lenBelow, lenAbove = getSplitShapePlaneExtents(LumberJack.splitShape, 0,y,0, 0,1,0)

									if lenAbove < 0.65 then
										LumberJack.stumpGrindingFlag = true
									else
										LumberJack.stumpGrindingFlag = false
										if LumberJack.showDebug then
											g_currentMission:addExtraPrintText("tree/stump too tall")
										end
									end
									if LumberJack.showDebug then
										g_currentMission:addExtraPrintText(string.format("below:%.3f   above:%.3f", lenBelow,lenAbove))
									end
								end
							else
								if LumberJack.splitShape ~= 0 then
									print("NONE FOUND ObjectId = " .. LumberJack.splitShape)
									LumberJack.splitShape = 0
								end  
								LumberJack.stumpGrindingFlag = false
								if LumberJack.showDebug then
									g_currentMission:addExtraPrintText("no split shape found")
								end
							end

							if LumberJack.stumpGrindingFlag and g_currentMission:getHasPlayerPermission("cutTrees") then
							-- SHOW RED RING SELECTOR
								setShaderParameter(hTool.ringSelector, "colorScale", 0.8, 0.05, 0.05, 1.0, false)
							end
							
						else
							-- CHAINSAW HAS FOUND A PLACE TO CUT THE TREE
							LumberJack:setSplitShape(RigidBodyType.DYNAMIC)
							if LumberJack.splitShape~=0 and entityExists(LumberJack.splitShape) then
								local shape = LumberJack.splitShape
								if getVolume(shape) < 0.100 then
									-- SHOW RED RING SELECTOR if too small to worry about (e.g. felling wedge or thin branch)
									setShaderParameter(hTool.ringSelector, "colorScale", 0.8, 0.05, 0.05, 1.0, false)
								end
								
								local cutStartX, cutStartY, cutStartZ, cutEndX, cutEndY, cutEndZ = hTool:getCutStartEnd()
								local x0, y0, z0 = (cutStartX+cutEndX)/2, (cutStartY+cutEndY)/2, (cutStartZ+cutEndZ)/2
								local below, above = getSplitShapePlaneExtents(shape, x0, y0, z0, localDirectionToWorld(shape, 0, 1, 0))
								g_currentMission:addExtraPrintText(g_i18n:getText("infohud_length") .. string.format(":   %.1fm  |  %.1fm", above, below))
			
								if LumberJack.showDebug then
									drawDebugLine(cutStartX,cutStartY,cutStartZ,1,1,1,cutEndX,cutEndY,cutEndZ,1,1,1)
								end
							end
						end
					end
					
					-- local x,y,z = getTranslation(hTool.ringSelector)
					-- print("LOCAL ringSelector: " .. x ..", " .. y .. ", " .. z)
					-- x,y,z = getTranslation(hTool.chainsawCameraFocus)
					-- print("LOCAL chainsawCameraFocus: " .. x ..", " .. y .. ", " .. z)
					-- x,y,z = getTranslation(hTool.chainsawSplitShapeFocus)
					-- print("LOCAL chainsawSplitShapeFocus: " .. x ..", " .. y .. ", " .. z)
					-- x,y,z = getWorldTranslation(hTool.ringSelector)
					-- print("WORLD ringSelector: " .. x ..", " .. y .. ", " .. z)
					-- x,y,z = getWorldTranslation(hTool.chainsawCameraFocus)
					-- print("WORLD chainsawCameraFocus: " .. x ..", " .. y .. ", " .. z)
					-- x,y,z = getWorldTranslation(hTool.chainsawSplitShapeFocus)
					-- print("WORLD chainsawSplitShapeFocus: " .. x ..", " .. y .. ", " .. z)
					
					-- GRIND STUMPS USING THE CHAINSAW --
					if LumberJack.stumpGrindingFlag and hTool.speedFactor > 0.1 and g_currentMission:getHasPlayerPermission("cutTrees") then
						LumberJack.stumpGrindingTime = LumberJack.stumpGrindingTime + dt
						if LumberJack.stumpGrindingTime < 3000 then
							-- STUMP GRINDING
							g_currentMission.player:lockInput(true)
							local cutPosition = {getWorldTranslation(hTool.ringSelector)}
							local cutTranslation = {worldToLocal(getParent(hTool.graphicsNode), cutPosition[1], cutPosition[2], cutPosition[3])}
							setTranslation(hTool.graphicsNode, cutTranslation[1]/3, cutTranslation[2]/3, cutTranslation[3]/3)
							hTool.isCutting = true
							hTool:updateParticles()
							LumberJack:createSawdust(hTool, 0, cutPosition)
							hTool.isCutting = false
						else
							-- DELETE THE SHAPE
							LumberJack:deleteSplitShape(LumberJack.splitShape)
							LumberJack.splitShape = 0
							LumberJack.stumpGrindingTime = 0
							LumberJack.stumpGrindingFlag = false
							g_currentMission.player:lockInput(false)
						end
						
					else
						LumberJack.stumpGrindingTime = 0
						g_currentMission.player:lockInput(false)
					end
					
					if LumberJack.useChainsawFlag then
						LumberJack.useChainsawFlag = false
						if hTool.waitingForResetAfterCut then
							LumberJack:createSawdust(hTool, -1)
						else
							LumberJack:createSawdust(hTool, -2)
						end
					end

				end
			else
				LumberJack.equipChainsawFlag = false
			end
		else
			LumberJack.equipChainsawFlag = false
		end
	end	
	
end


function LumberJack:createSawdust(hTool, amount, position, noEventSend)

	if LumberJack.createWoodchips and hTool ~= nil and hTool ~= 0 then
		if g_currentMission:getIsServer() then

			local fillTypeIndex = FillType.WOODCHIPS
			local minAmount = g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
		
			local delta
			if amount == -2 then
				delta = 0
				hTool.totalSawdust = 0
			elseif amount == -1 then
				delta = minAmount
			else
				delta = (60/hTool.defaultCutDuration * (math.random(50, 100)/100) * (g_currentDt/1000)) + (amount or 0)
			end
			
			hTool.totalSawdust = hTool.totalSawdust or 0
			hTool.totalSawdust = hTool.totalSawdust + delta

			if hTool.totalSawdust >= minAmount then
			
				local positionNode = hTool.graphicsNode
				local pos = {getWorldTranslation(positionNode)}
				
				if position then
					pos[1] = position[1]
					pos[3] = position[3]
				end
				
				local sx, sy, sz = pos[1], pos[2], pos[3]
				local ex, ey, ez = sx, sy, sz
				
				if LumberJack.useChainsawFlag and not LumberJack.stumpGrindingFlag then
					local rand = math.random(50, 100)/100
					local dx, _, dz = localDirectionToWorld(positionNode, 0, 1, 0)
					sx = sx + (rand * math.min(3, dx))
					sz = sz + (rand * math.min(3, dz))
				end

				local innerRadius = 0
				local outerRadius = DensityMapHeightUtil.getDefaultMaxRadius(fillTypeIndex)
				local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(nil,
					hTool.totalSawdust, fillTypeIndex, sx, sy, sz, ex, ey, ez, innerRadius, outerRadius)
				
				hTool.totalSawdust = hTool.totalSawdust - dropped
				
				if dropped == 0 then
					-- print("COULDN'T DROP SAWDUST HERE")
					hTool.totalSawdust = 0
				end
			end

		else
			CreateSawdustEvent.sendEvent(g_currentMission.player, amount, position, noEventSend)
		end
	end

end

function LumberJack:deleteSplitShape(shape, noEventSend)

	if shape ~= nil then
		if g_currentMission:getIsServer() then

			if shape ~= nil and shape ~= 0 then
				local volume = getVolume(shape)
				local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(shape))
				local amount = volume * splitType.volumeToLiter * splitType.woodChipsPerLiter / 5
				if amount > LumberJack.maxWoodchips then amount = LumberJack.maxWoodchips end
				local hTool = g_currentMission.player.baseInformation.currentHandtool
				local cutPosition = {getWorldTranslation(shape)}
				LumberJack:createSawdust(hTool, amount, cutPosition)
			end
		
			g_currentMission:removeKnownSplitShape(shape)
			local isTree = getRigidBodyType(shape) == RigidBodyType.STATIC
			
			if isTree then
				LumberJack.cutShapes = {}
				local x, y, z = getWorldTranslation(shape)
				local nx, ny, nz = 0, 1, 0
				local yx, yy, yz = 1, 0, 0
				local cutSizeY, cutSizeZ = 5, 5
				splitShape(shape, x, y + 0.2, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, "cutSplitShapeCallback", LumberJack)
				g_treePlantManager:removingSplitShape(shape)
				
				if table.getn(LumberJack.cutShapes) == 2 then
					local split0 = LumberJack.cutShapes[1]
					local split1 = LumberJack.cutShapes[2]
					local type0 = getRigidBodyType(split0.shape)
					local type1 = getRigidBodyType(split1.shape)
					local wasTree = (type0 == RigidBodyType.STATIC and type1 == RigidBodyType.DYNAMIC) or
									(type1 == RigidBodyType.STATIC and type0 == RigidBodyType.DYNAMIC)
					if wasTree then
						delete(LumberJack.cutShapes[1].shape)
						delete(LumberJack.cutShapes[2].shape)
					end
				end
			end
			
			if entityExists(shape) then
				delete(shape)
			end
		else
			DeleteShapeEvent.sendEvent(shape)
		end
	end

end

function LumberJack.cutSplitShapeCallback(unused, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
    if shape ~= nil then
		table.insert(LumberJack.cutShapes, {
			shape = shape,
			isBelow = isBelow,
			isAbove = isAbove,
			minY = minY,
			maxY = maxY,
			minZ = minZ,
			maxZ = maxZ
		})
    end
end
