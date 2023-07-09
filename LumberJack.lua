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
LumberJack.showDebug = false
LumberJack.allowBushCutting = true
LumberJack.bushCuttingFlag = true
LumberJack.initialised = false
-- LumberJack.superStrengthActivatesCutAnywhere = true
-- LumberJack.canCutLogsAnywhere = true
-- alternative to individual bool permissions: cut levels: 0=only accessible, 1=logs anywhere, 2=anything anywhere with superStrength, 3=anything anywhere

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
	-- preparation for mode where you can cut logs anywhere, but not necessarily trees
	-- local isSplit = getIsSplitShapeSplit(shape)
	-- local isStatic = getRigidBodyType(shape) == RigidBodyType.STATIC
	-- local isLog = isSplit and not isStatic
	-- -- local isStump = isSplit and isStatic -- not needed here
	-- -- local isTree = not isSplit and not isStatic -- not needed here
	-- local canCutAnywhere = LumberJack.cutAnywhere or (LumberJack.superStrengthActivatesCutAnywhere and LumberJack.superStrength)
	-- local canCutBecauseLog = LumberJack.canCutLogsAnywhere and isLog
	-- return canCutTrees and ((canChainsaw and canCutAnywhere) or canAccess or canCutBecauseLog)
	return canCutTrees and ((canChainsaw and LumberJack.cutAnywhere) or canAccess)
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

function LumberJack.getNonMowableDecoFunction()
	local functionData = LumberJack.nonMowableDecoFunction

	if functionData == nil then
		local decoFoliages = nil

		if g_currentMission.foliageSystem ~= nil then
			decoFoliages = g_currentMission.foliageSystem:getDecoFoliages()
		end

		local terrainRootNode = g_currentMission.terrainRootNode

		if decoFoliages ~= nil and #decoFoliages > 0 then
			functionData = {
				decoModifiers = {},
				decoFilters = {}
			}

			for index, decoFoliage in pairs(decoFoliages) do
				DebugUtil.printTableRecursively(decoFoliage, tostring(index)..":", 0,2)
				if decoFoliage.terrainDataPlaneId ~= nil and not decoFoliage.mowable then

					local decoModifier = DensityMapModifier.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)

					decoModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)

					local decoFilter = DensityMapFilter.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)

					decoFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

					functionData.decoModifiers[index] = decoModifier
					functionData.decoFilters[index] = decoFilter
				end
			end

			LumberJack.nonMowableDecoFunction = functionData
		end
	end

	return functionData
end

function LumberJack:removeNonMowableDeco(startWorldX, startWorldZ, dirX, dirZ)
	local functionData = LumberJack.getNonMowableDecoFunction()

	if functionData ~= nil then
		for index, decoFilter in pairs(functionData.decoFilters) do
			local decoModifier = functionData.decoModifiers[index]

			if decoModifier ~= nil and decoFilter ~= nil then
				decoModifier:setParallelogramWorldCoords(startWorldX+dirX, startWorldZ+dirZ, startWorldX + dirZ, startWorldZ - dirX, startWorldX - dirZ, startWorldZ + dirX, DensityCoordType.POINT_POINT_POINT)
				decoModifier:executeSet(0, decoFilter)
			end
		end
	end

end

function LumberJack:hasNonMowableDeco(startWorldX, startWorldZ, dirX, dirZ)
	--local a,b,c = FSDensityMapUtil.getBushDensity(startWorldX+dirX, startWorldZ+dirZ, startWorldX + dirZ, startWorldZ - dirX, startWorldX - dirZ, startWorldZ + dirX)
	--DebugUtil.drawDebugParallelogram(startWorldX+dirX, startWorldZ+dirZ, dirZ-dirX, -dirX-dirZ, -dirZ-dirX, dirX-dirZ, 0.1, 1,0,0, 1, false)

	local bushId = getTerrainDataPlaneByName(g_currentMission.terrainRootNode, "decoBush")
	local bits = getDensityAtWorldPos(bushId, startWorldX, 0, startWorldZ)
--	Logging.info("hasNonMowableDeco: %f %f", bitAND(bits, 15), bitShiftRight(bits,4))

	return bitAND(bits, 15) == 3
end


function LumberJack:resetRingSelector(dt)
	local x,y,z = getTranslation(self.ringSelector)
	local _,scale,_ = getScale(self.ringSelector)
	local parent = getParent(self.ringSelector)

	-- target position
	local tx,ty,tz = localToLocal(self.chainsawCameraFocus, parent, 0, 0, -0.3)

	-- move center of ring selector to ground level, if it would be below
	local wx,wy,wz = localToWorld(parent, tx,ty,tz)
	local yg=getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx,0,wz)
	if wy < yg then
		tx,ty,tz = worldToLocal(parent, wx,yg,wz)
	end

	-- difference between current and target
	local dx,dy,dz,ds = tx-x, ty-y, tz-z, 1-scale

	local len = math.sqrt(dx*dx+dy*dy+dz*dz+ds*ds)

	-- if we are almost there, snap to target
	if len<0.01 then
		LumberJack.resetRingSelectorSpeed=nil
		setTranslation(self.ringSelector, tx,ty,tz)
		setScale(self.ringSelector, 1,1,1)
		return
	end

	-- get movement speed
	local speed=LumberJack.resetRingSelectorSpeed
	if speed==nil then
		speed=0.0006*dt
	end

	-- if we would overshoot, snap to target
	if speed>=len then
		speed=len
		LumberJack.resetRingSelectorSpeed=nil
		setTranslation(self.ringSelector, tx,ty,tz)
		setScale(self.ringSelector, 1,1,1)
		return
	end

	-- calculate new position and scale
	-- we should probably incorporate dt into the factor to make it framerate independent
	local f=speed/len
	x,y,z,scale=x+dx*f,y+dy*f,z+dz*f,scale+ds*f

	-- increase speed for next step
	LumberJack.resetRingSelectorSpeed=speed+0.0006*dt

	setScale(self.ringSelector, 1, scale, scale)
	setTranslation(self.ringSelector, x,y,z)
end

function LumberJack:checkForStump(hitObjectId)
	if hitObjectId == nil or hitObjectId == 0 then
		return
	end

	local isSplitShape = getHasClassId(hitObjectId, ClassIds.MESH_SPLIT_SHAPE)
	if not isSplitShape then
		return
	end

	local isSplit = getIsSplitShapeSplit(hitObjectId)
	local isStatic = getRigidBodyType(hitObjectId) == RigidBodyType.STATIC
	local isStump = isSplit and isStatic
	-- but with superStrength we also want to grind logs or full trees away
	if isStump or LumberJack.superStrength then
		-- if no object was found so far or the current one is a stump
		-- that means: keep the first found object, or the last found stump
		-- also means: if there is a log and a stump, never choose the log
		if self.splitShape == 0 or isStump then
			self.splitShape = hitObjectId
		end
	end

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
		local chainsawEquipped = false
		if g_currentMission.player:hasHandtoolEquipped() then
			local hTool = g_currentMission.player.baseInformation.currentHandtool

			if hTool ~= nil and hTool.ringSelector ~= nil and hTool.chainsawSplitShapeFocus ~= nil then
				chainsawEquipped = true

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
						-- Find the splitShape from chainsawSplitShapeFocus (lastFoundObject doesn't exist for client in multiplayer)
						local x,y,z = getWorldTranslation(hTool.chainsawSplitShapeFocus)
						local nx,ny,nz = localDirectionToWorld(hTool.chainsawSplitShapeFocus, 1,0,0)
						local yx,yy,yz = localDirectionToWorld(hTool.chainsawSplitShapeFocus, 0,1,0)
						local splitShape, minY, maxY, minZ, maxZ = findSplitShape(x,y,z, nx,ny,nz, yx,yy,yz, 5, 5)
						if splitShape ~=0 then
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
							setVisibility(hTool.ringSelector, true)

							-- hTool.ringSelector will be destroyed and recreated
							-- apparently it also deletes our node, so we need to recreate it
							if LumberJack.overlapNode == nil then
								LumberJack.overlapNode = createTransformGroup("overlapNode")
								link(hTool.ringSelector, LumberJack.overlapNode)
							end

							-- slide ringSelector into default position
							LumberJack.resetRingSelector(hTool, dt)

							-- obtain terrain normal vector
							local cx, _, cz = getWorldTranslation(hTool.ringSelector)
							local tnx,tny,tnz = getTerrainNormalAtWorldPos(g_currentMission.terrainRootNode, cx, 0, cz)

							-- obtain ringSelector normal vector
							local rsnx, rsny, rsnz = MathUtil.vector3Normalize(localDirectionToWorld(hTool.ringSelector, 1,0,0))

							-- calculate ringSelector forward vector, which is perpendicular to world up vector: rsf = up x rsn
							-- would be better to use terrain normal instead of up, but I don't know how to get it
							local rsfx, rsfy, rsfz = MathUtil.crossProduct(tnx,tny,tnz, rsnx,rsny,rsnz)
							-- calculate ringSelector up vector, which is perpendicular to forward and normal: rsu = rnx x rsf
							local rsux, rsuy, rsuz = MathUtil.crossProduct(rsnx,rsny,rsnz, rsfx, rsfy, rsfz)
							-- rotate overlapNode to rsf and rsu, which is in the same place as the ringSelector, only with different rotation
							I3DUtil.setWorldDirection(LumberJack.overlapNode, rsfx,rsfy,rsfz, rsux,rsuy,rsuz)
							-- we did all that mostly to get the correct rotation for the overlapBox
							local rotX, rotY, rotZ = getWorldRotation(LumberJack.overlapNode)
							-- very thin, half height, full depth
							local extendX, extendY, extendZ = .005, .2, .3

							LumberJack.splitShape = 0
							-- we only want the upper half of the ringSelector, and its center is 1/4th in its up direction
							local ox,oy,oz = localToWorld(LumberJack.overlapNode, 0, 0.25, 0)

							rotX,rotY,rotZ = 0,0,0
							extendX,extendY,extendZ = 0.005, 0.005, 0.005
							ox,oy,oz = getWorldTranslation(hTool.ringSelector)

							-- the callback will set LumberJack.splitShape, if it finds a stump
							overlapBox(ox,oy,oz, rotX, rotY, rotZ, extendX, extendY, extendZ, "checkForStump", self, CollisionFlag.TREE, true, true, true)

							if LumberJack.showDebug then
								DebugUtil.drawOverlapBox(ox,oy,oz, rotX, rotY, rotZ, extendX, extendY, extendZ, .3,.3,.3)
							end

							if LumberJack.splitShape~=0 then
								if LumberJack.superStrength then
									LumberJack.stumpGrindingFlag = true
								else
									-- Y of ground at ringSelector center
									local yg=getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, cx, 0, cz)

									local lenBelow, lenAbove = getSplitShapePlaneExtents(LumberJack.splitShape, 0,yg,0, 0, 1, 0)
									if lenAbove < 0.65 then
										LumberJack.stumpGrindingFlag = true
									else
										LumberJack.stumpGrindingFlag = false
										if LumberJack.showDebug then
											g_currentMission:addExtraPrintText("stump too tall")
										end
									end
									if LumberJack.showDebug then
										g_currentMission:addExtraPrintText(string.format("below:%.3f   above:%.3f", lenBelow,lenAbove))
									end
								end
							else
								LumberJack.stumpGrindingFlag = false
								if LumberJack.showDebug then
									g_currentMission:addExtraPrintText("no stump found")
								end
							end

							if LumberJack.allowBushCutting and not LumberJack.stumpGrindingFlag then
								local dirX, dirZ = MathUtil.getDirectionFromYRotation(g_currentMission.player.rotY)
								local rx, _, rz = getWorldTranslation(hTool.ringSelector)

								LumberJack.bushCuttingFlag = LumberJack:hasNonMowableDeco(rx, rz, dirX, dirZ)
							end

							if (LumberJack.stumpGrindingFlag and g_currentMission:getHasPlayerPermission("cutTrees")) or LumberJack.bushCuttingFlag then
							-- SHOW RED RING SELECTOR
								setShaderParameter(hTool.ringSelector, "colorScale", 0.8, 0.05, 0.05, 1.0, false)
							else
							-- SHOW GREY RING SELECTOR
								setShaderParameter(hTool.ringSelector, "colorScale", 0.15, 0.15, 0.15, 1.0, false)
							end

						else
							-- CHAINSAW HAS FOUND A PLACE TO CUT THE TREE
							local x, y, z, nx, ny, nz, yx, yy, yz = hTool:getCutShapeInformation()
							local shape, _, _, _, _ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, hTool.cutSizeY, hTool.cutSizeZ)

							if shape ~= nil and shape ~= 0 then
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
					elseif LumberJack.bushCuttingFlag and hTool.speedFactor > 0.1 then
						LumberJack.stumpGrindingTime = LumberJack.stumpGrindingTime + dt
						if LumberJack.stumpGrindingTime < 100 then
							g_currentMission.player:lockInput(true)
							hTool.isCutting = true
							hTool:updateParticles()
							hTool.isCutting = false
						else
							local dirX, dirZ = MathUtil.getDirectionFromYRotation(g_currentMission.player.rotY)
							local x, _, z = getWorldTranslation(hTool.ringSelector)
							LumberJack:removeNonMowableDeco(x, z, dirX, dirZ)
							LumberJack.stumpGrindingTime = 0
							LumberJack.bushCuttingFlag = false
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
			end
		end

		if not chainsawEquipped and LumberJack.overlapNode ~= nil then
			LumberJack.overlapNode = nil
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
