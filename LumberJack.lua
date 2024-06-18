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
LumberJack.stumpGrindingPossible = false
LumberJack.useChainsawFlag = false
LumberJack.destroyFoliageSize = 2
LumberJack.bushCuttingPossible = false
LumberJack.splitShape = 0
LumberJack.maxWoodchips = 2000
LumberJack.showDebug = false
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
	
	local isAllowed = canCutTrees and ((canChainsaw and LumberJack.cutAnywhere) or canAccess)
	if isAllowed then
		return true
	else
		return superFunc(self, x, y, z, shape)
	end

end

function LumberJack:testTooLow(superFunc, shape, minY, maxY, minZ, maxZ)
	return false
end

-- DETECT SPLITSHAPES FROM CHAINSAW CALLBACK
function LumberJack:cutRaycastCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= 0 and hitObjectId ~= nil then
		LumberJack.selectorOnGround = hitObjectId==g_currentMission.terrainRootNode																	 
		if LumberJack.hitObjectId ~= hitObjectId then
			if getHasClassId(hitObjectId, ClassIds.MESH_SPLIT_SHAPE) then
				LumberJack.hitObjectId = hitObjectId
			else
				LumberJack.hitObjectId = 0
			end
		end
	end
end

function LumberJack:updateCutRaycast(superFunc)
	self.cutFocusDistance = -1

	local x, y, z = getWorldTranslation(self.player.cameraNode)
	local dx, dy, dz = unProject(0.52, 0.4, 1)
	dx, dy, dz = dx-x, dy-y, dz-z
	dx, dy, dz = MathUtil.vector3Normalize(dx, dy, dz)
	local treeCollisionMask = CollisionFlag.DEFAULT + CollisionFlag.STATIC_WORLD + CollisionFlag.VEHICLE

	raycastClosest(x, y, z, dx, dy, dz, "cutRaycastCallback", self.cutDetectionDistance, self, treeCollisionMask)
	
	if self.cutFocusDistance == -1 then
		LumberJack.hitObjectId = 0

		local r = self.cutDetectionDistance
		local x0, y0, z0 = x+(dx*r), y+(dy*r), z+(dz*r)
		LumberJack.moveChainsawCameraFocus(self, x0, y0, z0)
		
		local Y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x0, y0, z0)
		LumberJack.selectorOnGround = y0 < Y+0.01
	end
end

function LumberJack:chainsawUpdateRingSelector(shape)
	if shape ~= nil and shape ~= 0 then
		LumberJack.chainsawShape = shape
	end
end

-- NEW ALTERNATIVE TO "FIND SPLIT SHAPE"
function LumberJack:getSplitShape()
	local objectId = LumberJack.hitObjectId

	if objectId~=nil and objectId~=0 and entityExists(objectId) then
		if getHasClassId(objectId, ClassIds.MESH_SPLIT_SHAPE) then
			if getSplitType(objectId) ~= 0 then
				local isSplit = getIsSplitShapeSplit(objectId)
				local isStatic = getRigidBodyType(objectId) == RigidBodyType.STATIC
				local isDynamic = getRigidBodyType(objectId) == RigidBodyType.DYNAMIC
				
				local isTree = isStatic and not isSplit
				local isStump = isStatic and isSplit
				local isBranch = isDynamic and isSplit
			
				return objectId, isTree, isStump, isBranch
			end
		end
	end
	return 0
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

	-- THIS PART required for super strength at the start of a new game
	self.inputInformation.registrationList[InputAction.LUMBERJACK_STRENGTH] = {
		text = g_i18n:getText("menu_TOGGLE_STRENGTH"),
		triggerAlways = false,
		triggerDown = true,
		eventId = actionEventId,
		textVisibility = true,
		triggerUp = true,
		callback = LumberJack.toggleStrength,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT
	}
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
		LumberJack.originalSwimmingSpeed = self.motionInformation.maxSwimmingSpeed
	end
	
	if g_currentMission:getHasPlayerPermission("superSpeed") then
	
		self.motionInformation.maxRunningSpeed = LumberJack.maxRunningSpeed
		if self:hasHandtoolEquipped() and self.inputInformation.runAxis ~= 0 then
			self.motionInformation.maxWalkingSpeed = LumberJack.maxRunningSpeed
		else
			self.motionInformation.maxWalkingSpeed = LumberJack.maxWalkingSpeed
		end
		if self.baseInformation.isInWater and self.inputInformation.runAxis ~= 0 then
			self.motionInformation.maxSwimmingSpeed = LumberJack.maxRunningSpeed*0.5
		else
			self.motionInformation.maxSwimmingSpeed = LumberJack.maxWalkingSpeed*0.8
		end
		if self.inputInformation.moveRight ~= 0 then
			local sidestepFactor = 1/3
			if self.inputInformation.moveForward ~= 0 then
				sidestepFactor = math.sqrt(2)/2
			end
			self.motionInformation.maxWalkingSpeed = self.motionInformation.maxWalkingSpeed*sidestepFactor
			self.motionInformation.maxRunningSpeed = self.motionInformation.maxRunningSpeed*sidestepFactor
			self.motionInformation.maxSwimmingSpeed = self.motionInformation.maxSwimmingSpeed*sidestepFactor
		end
	else
		self.motionInformation.maxWalkingSpeed = LumberJack.originalWalkingSpeed
		self.motionInformation.maxRunningSpeed = LumberJack.originalRunningSpeed
		self.motionInformation.maxSwimmingSpeed = LumberJack.originalSwimmingSpeed
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
	Chainsaw.testTooLow = Utils.overwrittenFunction(Chainsaw.testTooLow, LumberJack.testTooLow)
	
	-- ALLOW TREE SPRAYING ANYWHERE ON THE MAP
	if pdlc_forestryPack~=nil and pdlc_forestryPack.SprayCan~=nil then
		pdlc_forestryPack.SprayCan.getIsSprayingAllowed = Utils.overwrittenFunction(pdlc_forestryPack.SprayCan.getIsSprayingAllowed, LumberJack.isSprayingAllowed)
	end

	-- GET OBJECT FROM CHAINSAW RAYCAST
	Chainsaw.updateCutRaycast = Utils.overwrittenFunction(Chainsaw.updateCutRaycast, LumberJack.updateCutRaycast)
	Chainsaw.cutRaycastCallback = Utils.appendedFunction(Chainsaw.cutRaycastCallback, LumberJack.cutRaycastCallback)
	Chainsaw.updateRingSelector = Utils.appendedFunction(Chainsaw.updateRingSelector, LumberJack.chainsawUpdateRingSelector)
	
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

function LumberJack.moveChainsawCameraFocus(hTool, x0, y0, z0)
	if hTool ~= nil and hTool.chainsawCameraFocus then
		local x,y,z = worldToLocal(getParent(hTool.chainsawCameraFocus), x0,y0,z0)
		setTranslation(hTool.chainsawCameraFocus, x,y,z)
	end
end

function LumberJack.resetRingSelector(hTool)
	if hTool ~= nil and hTool.ringSelector then
		local x,y,z = getWorldTranslation(hTool.chainsawCameraFocus)
		setWorldTranslation(hTool.ringSelector, x, y, z)
		setScale(hTool.ringSelector, 1, 1, 1)
	end
end

function LumberJack.updateRingSelector(hTool)
	
	if hTool == nil then
		return
	end

	local x0,y0,z0 = getWorldTranslation(hTool.chainsawCameraFocus)
	local x1,y1,z1 = getWorldTranslation(hTool.player.cameraNode)

	if LumberJack.showDebug then
		DebugUtil.drawDebugNode(hTool.chainsawCameraFocus, "A")
	end
	
	local distance = math.sqrt((x1-x0)^2 + (y1-y0)^2 + (z1-z0)^2)
	local d = distance/hTool.cutDetectionDistance
	setVisibility(hTool.ringSelector, true)
	setShaderParameter(hTool.ringSelector, "colorScale", 0.15*(1+d), 0.15*(1+d), 0.15*(1+d), 1.0, false)
	
end

function LumberJack.getDecoFunctionData()
	local functionData = LumberJack.decoFunctionData

	if functionData == nil then
		local decoFoliages = nil
		
		if g_currentMission.foliageSystem ~= nil then
			decoFoliages = g_currentMission.foliageSystem.paintableFoliages

			print("decoFoliages:")
			DebugUtil.printTableRecursively(decoFoliages, "--", 0, 1)
			
			
			local decoFoliageId = getTerrainDataPlaneByName(g_currentMission.terrainRootNode, "decoFoliage")
			local scale = g_currentMission.terrainSize / getDensityMapSize(decoFoliageId)
			print("Terrain Size: " .. tostring(g_currentMission.terrainSize))
			print("Deco Foliage Size: " .. tostring(getDensityMapSize(decoFoliageId)))
			print("Deco Foliage Scale: " .. tostring(scale))

		end

		local terrainRootNode = g_currentMission.terrainRootNode

		if decoFoliages ~= nil and #decoFoliages > 0 then
			functionData = {
				decoFilters = {},
				decoModifiers = {},
				destroyLayer = {}
			}

			for index, decoFoliage in ipairs(decoFoliages) do
				if decoFoliage.terrainDataPlaneId ~= nil then
					local isBush = string.find(decoFoliage.layerName:lower(), "bush") and true or false

					local decoModifier = DensityMapModifier.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)
					decoModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)

					local decoFilter = DensityMapFilter.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)
					decoFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

					functionData.decoModifiers[decoFoliage.id] = decoModifier
					functionData.decoFilters[decoFoliage.id] = decoFilter
					functionData.destroyLayer[decoFoliage.id] = isBush
				end
			end

			LumberJack.decoFunctionData = functionData
		end
	end

	return functionData
end

function LumberJack:removeDeco(startWorldX, startWorldZ, areaSize, destroyAll)
	local functionData = LumberJack.getDecoFunctionData()
	local decoFoliages = g_currentMission.foliageSystem:getDecoFoliages()

	if functionData ~= nil then
		local h = areaSize/2
		for index, decoFilter in pairs(functionData.decoFilters) do
			if functionData.destroyLayer[index] or destroyAll then
				local decoModifier = functionData.decoModifiers[index]

				if decoModifier ~= nil and decoFilter ~= nil then
					decoModifier:setParallelogramWorldCoords(startWorldX-h, startWorldZ-h, startWorldX+h, startWorldZ-h, startWorldX-h, startWorldZ+h, DensityCoordType.POINT_POINT_POINT)
					decoModifier:executeSet(0, decoFilter)
				end
			end
		end
	end
end

function LumberJack:seekAndDestroyFoliage(startWorldX, startWorldZ, destroy)

	local functionData = LumberJack.getDecoFunctionData()
	local decoFoliageId = getTerrainDataPlaneByName(g_currentMission.terrainRootNode, "decoFoliage")
	local numChannels = getTerrainDetailNumChannels(decoFoliageId)
	--print("DensityMapFilename: " .. getDensityMapFilename(decoFoliageId))
	
	if destroy and LumberJack.destroyAllFoiliage then
		LumberJack:removeDeco(startWorldX, startWorldZ, LumberJack.destroyFoliageSize, destroy)
	end
	
	local function decimalToBinary(number, desiredLength)
		local binaryString = ""
		local num = math.floor(number)

		repeat
			local remainder = num % 2
			binaryString = remainder .. binaryString
			num = math.floor(num / 2)
		until num == 0

		local currentLength = #binaryString
		local paddingLength = math.max(0, desiredLength - currentLength)

		if paddingLength > 0 then
			binaryString = string.rep("0", paddingLength) .. binaryString
		end

		return binaryString
	end


	local foundAny = false
	local squareSize  = 0.05
	local areaSize = LumberJack.destroyFoliageSize
    local numSquares = math.ceil(areaSize / squareSize)
    local offset = (areaSize - (numSquares * squareSize)) / 2
    for i = 0, numSquares-1 do
        for j = 0, numSquares-1 do
		
			local found = false
            local rx = startWorldX-areaSize/2 + i*squareSize + offset
            local rz = startWorldZ-areaSize/2 + j*squareSize + offset
			
			local bits = getDensityAtWorldPos(decoFoliageId, rx+squareSize/2, 0, rz+squareSize/2)
			local value = bitAND(bits, 2^numChannels - 1)
			
			--print(value .. " = " .. decimalToBinary(value, numChannels) .. " / " .. decimalToBinary(bitShiftRight(bits, numChannels), 6))

			--bitAND(densityBits, 2^numChannels - 1)
			--bitAND(bitShiftRight(densityBits, groundTypeFirstChannel), 2^groundTypeNumChannels - 1)
			
			if functionData.destroyLayer[value] or (LumberJack.destroyAllFoiliage and value > 0) then
				found = true
				foundAny = true
			end

			if found and destroy then
				LumberJack:removeDeco(rx, rz, squareSize)
			end
			
			if LumberJack.showDebug then
				local d = 0.025*squareSize
				if found then
					DebugUtil.drawDebugAreaRectangle(rx+d,0,rz+d, rx+squareSize-d,0,rz+d, rx+d,0,rz+squareSize-d, true, 0,0,1)
				end
			end
      
        end
    end
	
	if LumberJack.showDebug then
		local n=LumberJack.destroyFoliageSize
		local scale = g_currentMission.terrainSize / getDensityMapSize(decoFoliageId)
		DebugUtil.drawDebugAreaRectangle(startWorldX-n/2,0,startWorldZ-n/2, startWorldX+n/2,0,startWorldZ-n/2, startWorldX-n/2,0,startWorldZ+n/2, true, 1,1,1)
		
		for x = -n, n do
			for z = -n, n do
				local rx,rz = math.floor((startWorldX+x*scale)/scale)*scale, math.floor((startWorldZ+z*scale)/scale)*scale
				local bits = getDensityAtWorldPos(decoFoliageId, startWorldX+x*scale, 0, startWorldZ+z*scale)
				local value = bitAND(bits, 2^numChannels - 1)
				local shift = bitShiftRight(bits, numChannels)
				
				local d = 0.025
				local yg = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, rx+scale/2,0,rz+scale/2)
				if functionData.destroyLayer[value] or (LumberJack.destroyAllFoiliage and value > 0) then
					DebugUtil.drawDebugAreaRectangle(rx+d,0,rz+d, rx+scale-d,0,rz+d, rx+d,0,rz+scale-d, true, 0,1,0)
					Utils.renderTextAtWorldPosition(rx+scale/2, yg+0.1, rz+scale/2, string.format("%d - %d", value, shift), getCorrectTextSize(0.012), 0, {1,1,1})
				else
					DebugUtil.drawDebugAreaRectangle(rx+d,0,rz+d, rx+scale-d,0,rz+d, rx+d,0,rz+scale-d, true, 0.15,0.15,0.15)
					Utils.renderTextAtWorldPosition(rx+scale/2, yg+0.1, rz+scale/2, string.format("%d - %d", value, shift), getCorrectTextSize(0.012), 0, {0.3,0.3,0.3})
				end
			end
		end
	end
	
	if LumberJack.showDebug and foundAny then
		g_currentMission:addExtraPrintText("Bush")
	end
	
	return foundAny
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
					LumberJack.resetRingSelector(hTool)
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
						if LumberJack.chainsawShape and entityExists(LumberJack.chainsawShape) then
							local splitShape = LumberJack.chainsawShape
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
						
							LumberJack.updateRingSelector(hTool)

							-- STUMP GRINDING
							LumberJack.stumpGrindingPossible = false
							if not LumberJack.bushCuttingActive then
								if LumberJack.splitShape ~= LumberJack.hitObjectId then
									LumberJack.resetRingSelector(hTool)
									
									local splitShape, isTree, isStump, isBranch = LumberJack:getSplitShape()
									if splitShape and entityExists(splitShape) then
										LumberJack.splitShape = splitShape
										LumberJack.isTree = isTree
										LumberJack.isStump = isStump
										LumberJack.isBranch = isBranch
									else
										LumberJack.splitShape = 0
									end
								end
								
								if LumberJack.splitShape and entityExists(LumberJack.splitShape) then
								
									if LumberJack.showDebug then
										if LumberJack.isStump then
											g_currentMission:addExtraPrintText("Stump")
										elseif LumberJack.isTree then
											g_currentMission:addExtraPrintText("Tree")
										elseif LumberJack.isBranch then
											g_currentMission:addExtraPrintText("Branch")
										end
									end

									if LumberJack.superStrength then
										local rx, _, rz = getWorldTranslation(hTool.ringSelector)
										LumberJack.stumpGrindingPossible = hTool:isCuttingAllowed(rx, 0, rz)
									else
										if LumberJack.isStump then
											local x0,y0,z0 = getWorldTranslation(LumberJack.splitShape)
											local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x0, y0, z0)
											local lenBelow, lenAbove = getSplitShapePlaneExtents(LumberJack.splitShape, 0,y,0, 0,1,0)

											if lenAbove < 1 then
												local rx, _, rz = getWorldTranslation(hTool.ringSelector)
												LumberJack.stumpGrindingPossible = hTool:isCuttingAllowed(rx, 0, rz)
											else
												if LumberJack.showDebug then
													g_currentMission:addExtraPrintText("Stump is too tall")
												end
											end
											if LumberJack.showDebug then
												g_currentMission:addExtraPrintText(string.format("below:%.3f   above:%.3f", lenBelow,lenAbove))
											end
										else
											g_currentMission:addExtraPrintText("DO SOMETHIONG HERE..")
										end
									end
								else
									if LumberJack.showDebug then
										g_currentMission:addExtraPrintText("no split shape found")
									end
								end
							end
							
							-- BUSH GRINDING
							if LumberJack.destroyFoliageSize == 0 or LumberJack.stumpGrindingPossible or not LumberJack.selectorOnGround then
								LumberJack.bushCuttingPossible = false
							elseif hTool.speedFactor < 0.1 or LumberJack.superStrength then
								local rx, _, rz = getWorldTranslation(hTool.ringSelector)
								LumberJack.bushCuttingPossible = hTool:isCuttingAllowed(rx, 0, rz) and LumberJack:seekAndDestroyFoliage(rx, rz)
							end


							if LumberJack.stumpGrindingPossible then
							-- SHOW RED RING SELECTOR
								setShaderParameter(hTool.ringSelector, "colorScale", 0.8, 0.05, 0.05, 1.0, false)
							elseif LumberJack.bushCuttingPossible then
							-- SHOW GREEN RING SELECTOR
								setShaderParameter(hTool.ringSelector, "colorScale", 0.2, 0.8, 0.05, 1.0, false)										  
							end
							
						else
							-- CHAINSAW HAS FOUND A PLACE TO CUT THE TREE
							if LumberJack.chainsawShape and entityExists(LumberJack.chainsawShape) then
								local shape = LumberJack.chainsawShape
								if getVolume(shape) < 0.100 then
									-- SHOW RED RING SELECTOR if too small to worry about (e.g. felling wedge or thin branch)
									setShaderParameter(hTool.ringSelector, "colorScale", 0.8, 0.05, 0.05, 1.0, false)
								else
									-- SHOW DIMENSIONS AFTER NEW CUT
									local cutStartX, cutStartY, cutStartZ, cutEndX, cutEndY, cutEndZ = hTool:getCutStartEnd()
									local x0, y0, z0 = (cutStartX+cutEndX)/2, (cutStartY+cutEndY)/2, (cutStartZ+cutEndZ)/2
									local below, above = getSplitShapePlaneExtents(shape, x0, y0, z0, localDirectionToWorld(shape, 0, 1, 0))
									g_currentMission:addExtraPrintText(g_i18n:getText("infohud_length") .. string.format(":   %.1fm  |  %.1fm", below, above))
				
									if LumberJack.showDebug then
										drawDebugLine(cutStartX,cutStartY,cutStartZ,1,1,1,cutEndX,cutEndY,cutEndZ,1,1,1)
									end
								end
							end
						end
					end
					
					-- GRIND STUMPS USING THE CHAINSAW --
					if LumberJack.stumpGrindingPossible and hTool.speedFactor > 0.1 then
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
							LumberJack.stumpGrindingPossible = false
							g_currentMission.player:lockInput(false)
						end
					elseif LumberJack.bushCuttingPossible and hTool.speedFactor > 0.1 then
						LumberJack.bushCuttingActive = true
						LumberJack.stumpGrindingTime = LumberJack.stumpGrindingTime + dt
						if (LumberJack.superStrength and LumberJack.stumpGrindingTime < 100)
						or (not LumberJack.superStrength and LumberJack.stumpGrindingTime < 1000) then
							if not LumberJack.superStrength then
								g_currentMission.player:lockInput(true)
							end
							hTool.isCutting = true
							hTool:updateParticles()
							hTool.isCutting = false
						else
							local x, _, z = getWorldTranslation(hTool.ringSelector)
							LumberJack:seekAndDestroyFoliage(x, z, true)
							LumberJack.stumpGrindingTime = 0
							LumberJack.bushCuttingPossible = false
							g_currentMission.player:lockInput(false)
						end												   
						
					else
						LumberJack.stumpGrindingTime = 0
						g_currentMission.player:lockInput(false)
						if hTool.speedFactor < 0.1 then
							LumberJack.bushCuttingActive = false
						end
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
				
				if LumberJack.useChainsawFlag and not LumberJack.stumpGrindingPossible then
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

	if shape ~= nil and shape ~= 0 then
		if g_currentMission:getIsServer() then

			local volume = getVolume(shape)
			local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(shape))
			local amount = volume * splitType.volumeToLiter * splitType.woodChipsPerLiter / 5
			if amount > LumberJack.maxWoodchips then amount = LumberJack.maxWoodchips end
			local hTool = g_currentMission.player.baseInformation.currentHandtool
			local cutPosition = {getWorldTranslation(shape)}
			LumberJack:createSawdust(hTool, amount, cutPosition)
		
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
