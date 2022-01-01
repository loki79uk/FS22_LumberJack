-- ============================================================= --
-- LUMBERJACK MOD
-- ============================================================= --
LumberJack = {};
source(g_currentModDirectory .. 'DeleteShapeEvent.lua');

addModEventListener(LumberJack);

-- ALLOW CHAINSAW CUTTING ANYWHERE ON THE MAP
function LumberJack:isCuttingAllowed(superFunc, x, y, z)
	return true
end

-- ADD SHORTCUT KEY SELECTION TO OPTIONS MENU
function LumberJack:registerActionEvents()
	local _, actionEventId = g_inputBinding:registerActionEvent('LUMBERJACK_STRENGTH', self, LumberJack.toggleStrength, true, true, false, true);
	g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
	g_inputBinding:setActionEventActive(actionEventId, true)
    g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("menu_TOGGLE_STRENGTH"))
	
	--print("registerActionEvents")
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

-- APPEND PLAYER UPDATE STREAMS FOR MUTIPLAYER 
function LumberJack.prependPlayerReadUpdateStream(self, streamId, timestamp, connection)
    if not connection:getIsServer() then
        -- server code (read data from client)
        if connection == self.networkInformation.creatorConnection then
			self.superStrengthEnabled = streamReadBool(streamId)
            self.maxPickableObjectMass = streamReadFloat32(streamId)
        end
    end
end
function LumberJack.prependPlayerWriteUpdateStream(self, streamId, connection, dirtyMask)
	if connection:getIsServer() and self.isOwner then
        -- client code (send data to server)
		if self.superStrengthEnabled == nil then
			self.superStrengthEnabled = LumberJack.superStrength
		end
		streamWriteBool(streamId, self.superStrengthEnabled)
		if self.maxPickableObjectMass == nil then
			self.maxPickableObjectMass = LumberJack.normalStrengthValue
		end
		streamWriteFloat32(streamId, self.maxPickableObjectMass)
    end
end

--REPLACE ALL INSTANCES OF Player.MAX_PICKABLE_OBJECT_MASS TO ENABLE CLIENT SUPERSETRENGTH IN MULTIPLAYER
function LumberJack.playerThrowObject(self, superFunc, noEventSend)
	if self.maxPickableObjectMass ~= nil then
		Player.MAX_PICKABLE_OBJECT_MASS = self.maxPickableObjectMass
	end
	return superFunc(self, noEventSend)
end
function LumberJack.playerStatePickupIsAvailable(self, superFunc)
	if self.player.maxPickableObjectMass ~= nil then
		Player.MAX_PICKABLE_OBJECT_MASS = self.player.maxPickableObjectMass
	end
	return superFunc(self)
end
function LumberJack.playerStateThrowIsAvailable(self, superFunc)
	if self.player.maxPickableObjectMass ~= nil then
		Player.MAX_PICKABLE_OBJECT_MASS = self.player.maxPickableObjectMass
	end
	return superFunc(self)
end

-- DETECT SUPER STRENGTH CONSOLE COMMAND
function LumberJack.playerConsoleCommand(self, superFunc)
	superFunc(self)
	if g_currentMission.player.superStrengthEnabled then
		LumberJack.lockStrength = true
		LumberJack.superStrength = true
		g_currentMission.player.maxPickableObjectMass = LumberJack.superStrengthValue
	else
		LumberJack.lockStrength = false
		LumberJack.superStrength = false
		g_currentMission.player.maxPickableObjectMass = LumberJack.normalStrengthValue
	end
end

-- LUMBERJACK FUNCTIONS:
function LumberJack:loadMap(name)
	--print("Load Mod: 'LumberJack'")
	LumberJack.superStrength = false
	LumberJack.lockStrength = false
	LumberJack.doubleTap = 0
	LumberJack.doubleTapTime = 0
	LumberJack.superStrengthValue = 999
	LumberJack.normalStrengthValue = 0.2
	LumberJack.stumpGrindingTime = 0
	LumberJack.stumpGrindingFlag = false
	LumberJack.useChainsawFlag = false
	LumberJack.splitShapeId = 0
	LumberJack.showDebug = false
	LumberJack.initialised = false

	-- ALLOW CHAINSAW CUTTING ANYWHERE ON THE MAP
	Chainsaw.isCuttingAllowed = Utils.overwrittenFunction(Chainsaw.isCuttingAllowed, LumberJack.isCuttingAllowed)
	
	-- ADD SHORTCUT KEY SELECTION TO OPTIONS MENU
	Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, LumberJack.registerActionEvents)
	
	-- MULTIPLAYER SUPER STRENGTH FIX
	Player.readUpdateStream = Utils.prependedFunction(Player.readUpdateStream, LumberJack.prependPlayerReadUpdateStream)
	Player.writeUpdateStream = Utils.prependedFunction(Player.writeUpdateStream, LumberJack.prependPlayerWriteUpdateStream)
	Player.throwObject = Utils.overwrittenFunction(Player.throwObject, LumberJack.playerThrowObject)
	PlayerStatePickup.isAvailable = Utils.overwrittenFunction(PlayerStatePickup.isAvailable, LumberJack.playerStatePickupIsAvailable)
	PlayerStateThrow.isAvailable = Utils.overwrittenFunction(PlayerStateThrow.isAvailable, LumberJack.playerStateThrowIsAvailable)
	
	-- CATCH CONSOLE COMMAND
	Player.consoleCommandToggleSuperStrongMode = Utils.overwrittenFunction(Player.consoleCommandToggleSuperStrongMode, LumberJack.playerConsoleCommand)
	
end
function LumberJack:deleteMap()
end
function LumberJack:mouseEvent(posX, posY, isDown, isUp, button)
end
function LumberJack:keyEvent(unicode, sym, modifier, isDown)
end
function LumberJack:draw()
end

function LumberJack:toggleStrength(name, state)
	if g_currentMission.player.isEntered and not g_gui:getIsGuiVisible() then
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
					g_currentMission.player.maxPickableObjectMass = LumberJack.normalStrengthValue
					g_currentMission.player.superStrengthEnabled = LumberJack.superStrength
				end
			else
				if state == 1 then
					--print("SUPER STRENGTH ON")
					LumberJack.superStrength = true
					g_currentMission.player.maxPickableObjectMass = LumberJack.superStrengthValue
					g_currentMission.player.superStrengthEnabled = LumberJack.superStrength
				end
			end
		end
		
	end
end

function LumberJack:update(dt)
	-- Dedicated Server has no player
	if g_currentMission.player==nil then
		return
	end
	
	-- CHANGE GLOBAL VALUES ON FIRST RUN
	if (g_gameStateManager:getGameState()==GameState.PLAY and LumberJack.initialised==false) then
		LumberJack.playerID = g_currentMission.player.controllerIndex
		g_currentMission.player.maxPickableObjectMass = LumberJack.normalStrengthValue
		
		-- enable active objects debugging output:
		if LumberJack.showDebug then
			if g_server ~= nil then
				g_server.showActiveObjects = true
			end
		end

		-- Only change values from default
		if Player.MAX_PICKABLE_OBJECT_DISTANCE == 3.00 then
			Player.MAX_PICKABLE_OBJECT_DISTANCE = 12.00
		end
		if g_currentMission.player.minCutDistance == 0.50 then
			g_currentMission.player.minCutDistance = 0.10
		end
		if g_currentMission.player.maxCutDistance == 2.00 then
			g_currentMission.player.maxCutDistance = 6.00
		end
		LumberJack.initialised = true
	end
	
	if g_currentMission.player.isEntered and not g_gui:getIsGuiVisible() then

		-- DETECT DOUBLE TAP SUPER STRENGTH KEY
		if LumberJack.doubleTap ~= 0 then
			if LumberJack.doubleTap == 1 then
				LumberJack.doubleTapTime = LumberJack.doubleTapTime + dt
				if LumberJack.doubleTapTime > 500 then
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
			if g_currentMission.player.isObjectInRange and g_currentMission.player.lastFoundObjectMass > g_currentMission.player.maxPickableObjectMass then
				-- Make hand RED when objects are too heavy to pick up
				g_currentMission.player.pickedUpObjectOverlay:setColor(1.0, 0.1, 0.1, 0.5)
			else
				-- Make cursor/hand GREY for everything else
				g_currentMission.player.pickedUpObjectOverlay:setColor(1, 1, 1, 0.3)
			end
			g_currentMission.player.aimOverlay:setColor(1, 1, 1, 0.3)
		end
	end
		
	-- DESTROY SMALL LOGS WHEN USING THE CHAINSAW --
	if g_currentMission.player:hasHandtoolEquipped() then
		local hTool = g_currentMission.player.baseInformation.currentHandtool
	
		if hTool ~= nil and hTool.ringSelector ~= nil then

			-- INCRESE CUTTING SPEED x2 (default value is 8.0)
			hTool.defaultCutDuration = 4.0
			
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
							if g_currentMission.missionDynamicInfo.isMultiplayer then
							--print("MULTIPLAYER")
								DeleteShapeEvent.sendEvent(splitShape)
							else
							--print("SINGLE PLAYER")
								g_currentMission:removeKnownSplitShape(splitShape)
								delete(splitShape)
							end
						end
					end
					LumberJack.useChainsawFlag = true
				end
			else
				-- print("CHAINSAW NOT CUTTING")		
				if hTool.ringSelector ~= nil and hTool.ringSelector ~= 0 then	
					if getVisibility(hTool.ringSelector) == false then
						setVisibility(hTool.ringSelector, true)
						
						-- Find the splitShape from chainsawSplitShapeFocus
						LumberJack.splitShape = 0
						local x,y,z = getWorldTranslation(hTool.chainsawSplitShapeFocus)
						local xx,xy,xz = localDirectionToWorld(hTool.chainsawSplitShapeFocus, 1,0,0)
						local yx,yy,yz = localDirectionToWorld(hTool.chainsawSplitShapeFocus, 0,1,0)
						local zx,zy,zz = localDirectionToWorld(hTool.chainsawSplitShapeFocus, 0,0,1)
						local size = 1.5

						local x0 = x + yx*0.45 + zx*0.3
						local y0 = y + yy*0.45 + zy*0.3
						local z0 = z + yz*0.45 + zz*0.3
						local xx0,xy0,xz0 = 1,0,0
						local yx0,yy0,yz0 = 0,-1,0
						local zx0,zy0,zz0 = 0,0,-1
						if LumberJack.showDebug then
							local r = hTool.ringSelectorScaleOffset
							Utils.renderTextAtWorldPosition(x0-xx0*r,y0-xy0*r,z0-xz0*r, "-x", getCorrectTextSize(0.012), 0)
							Utils.renderTextAtWorldPosition(x0+xx0*r,y0+xy0*r,z0+xz0*r, "+x", getCorrectTextSize(0.012), 0)
							Utils.renderTextAtWorldPosition(x0-yx0*r,y0-yy0*r,z0-yz0*r, "-y", getCorrectTextSize(0.012), 0)
							Utils.renderTextAtWorldPosition(x0+yx0*r,y0+yy0*r,z0+yz0*r, "+y", getCorrectTextSize(0.012), 0)
							Utils.renderTextAtWorldPosition(x0-zx0*r,y0-zy0*r,z0-zz0*r, "-z", getCorrectTextSize(0.012), 0)
							Utils.renderTextAtWorldPosition(x0+zx0*r,y0+zy0*r,z0+zz0*r, "+z", getCorrectTextSize(0.012), 0)
						end

						x = x0 - xx0*size/2 + yx0*0.45 - zx0*size/2
						y = y0 - xy0*size/2 + yy0*0.45 - zy0*size/2
						z = z0 - xz0*size/2 + yz0*0.45 - zz0*size/2
						xx,xy,xz = xx0,xy0,xz0
						yx,yy,yz = yx0,yy0,yz0
						zx,zy,zz = zx0,zy0,zz0
						if LumberJack.showDebug then
							drawDebugLine(x,y,z,1,1,1,x+xx*size,y+xy*size,z+xz*size,1,1,1)
							drawDebugLine(x,y,z,1,1,1,x+zx*size,y+zy*size,z+zz*size,1,1,1)
							drawDebugLine(x+xx*size,y+xy*size,z+xz*size,1,1,1,x+xx*size+zx*size,y+xy*size+zy*size,z+xz*size+zz*size,1,1,1)
							drawDebugLine(x+zx*size,y+zy*size,z+zz*size,1,1,1,x+xx*size+zx*size,y+xy*size+zy*size,z+xz*size+zz*size,1,1,1)
						end
						if LumberJack.splitShape==0 then
							LumberJack.splitShape, _, _, _, _ = findSplitShape(x,y,z, -yx,-yy,-yz, xx,xy,xz, size, size)
							if LumberJack.splitShape~=0 then
							
								if LumberJack.superStrength then
									LumberJack.stumpGrindingFlag = true
								else
									local lenBelow, lenAbove = getSplitShapePlaneExtents(LumberJack.splitShape, x,y,z, -yx,-yy,-yz)
									local _,ly,_ = worldToLocal(LumberJack.splitShape, x,y,z)
									if ly < 0.5 and lenAbove < 1 then
										LumberJack.stumpGrindingFlag = true
									else
										LumberJack.stumpGrindingFlag = false
									end
									if LumberJack.showDebug then
										print(string.format("below:%s   above:%s   ly:%s", tostring(lenBelow),tostring(lenAbove),tostring(ly)))
									end
								end
							else
								LumberJack.stumpGrindingFlag = false
							end
						end

						if LumberJack.stumpGrindingFlag then
						-- SHOW RED RING SELECTOR
							setShaderParameter(hTool.ringSelector, "colorScale", 0.8, 0.05, 0.05, 1.0, false)
						else
						-- SHOW GREY RING SELECTOR
							setShaderParameter(hTool.ringSelector, "colorScale", 0.05, 0.05, 0.05, 1.0, false)
						end
						
					end
				end
				
				-- GRIND STUMPS USING THE CHAINSAW --
				if LumberJack.stumpGrindingFlag and g_currentMission.player.isEntered and not g_gui:getIsGuiVisible()
				and hTool.speedFactor > 0.1 then
					LumberJack.stumpGrindingTime = LumberJack.stumpGrindingTime + dt
					if LumberJack.stumpGrindingTime < 3000 then
						-- STUMP GRINDING
						g_currentMission.player:lockInput(true)
						local cutPosition = {getWorldTranslation(hTool.ringSelector)}
						local cutTranslation = {worldToLocal(getParent(hTool.graphicsNode), cutPosition[1], cutPosition[2], cutPosition[3])}
						setTranslation(hTool.graphicsNode, cutTranslation[1]/3, cutTranslation[2]/3, cutTranslation[3]/3)
						hTool.isCutting = true
						hTool:updateParticles()
						hTool.isCutting = false
					else
						-- DELETE THE SHAPE
						if g_currentMission.missionDynamicInfo.isMultiplayer then
						--print("MULTIPLAYER")
							DeleteShapeEvent.sendEvent(LumberJack.splitShape)
						else
						--print("SINGLE PLAYER")
							g_currentMission:removeKnownSplitShape(LumberJack.splitShape)
							delete(LumberJack.splitShape)
						end
						LumberJack.splitShape = 0
						LumberJack.stumpGrindingTime = 0
						LumberJack.stumpGrindingFlag = false
						g_currentMission.player:lockInput(false)
					end
					
				else
					LumberJack.stumpGrindingTime = 0
					g_currentMission.player:lockInput(false)
				end

				LumberJack.useChainsawFlag = false
			end
		end
	end	
end