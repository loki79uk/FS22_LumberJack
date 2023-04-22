
LumberJack.SETTINGS = {}

LumberJack.menuItems = {
	[1] = 'createWoodchips',
	[2] = 'superStrengthValue',
	[3] = 'normalStrengthValue',
	[4] = 'superDistanceValue',
	[5] = 'normalDistanceValue',
	[6] = 'maxCutDistance',
	[7] = 'defaultCutDuration',
	[8] = 'maxWalkingSpeed',
	[9] = 'maxRunningSpeed'
}

LumberJack.SETTINGS.showDebug = {
-- LumberJack.createWoodchips = false
	['default'] = 1,
	['values'] = {false, true},
	['strings'] = {
		g_i18n:getText("ui_off"),
		g_i18n:getText("ui_on")
	}
}
LumberJack.SETTINGS.createWoodchips = {
-- LumberJack.createWoodchips = false
	['default'] = 1,
	['values'] = {false, true},
	['strings'] = {
		g_i18n:getText("ui_off"),
		g_i18n:getText("ui_on")
	}
}
LumberJack.SETTINGS.superStrengthValue = {
-- LumberJack.superStrengthValue = 1000
	['default'] = 13,
	['values'] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0, math.huge},
	['strings'] = {
		"1 " .. g_i18n:getText("text_TONNE"),
		"2 " .. g_i18n:getText("text_TONNE"),
		"3 " .. g_i18n:getText("text_TONNE"),
		"4 " .. g_i18n:getText("text_TONNE"),
		"5 " .. g_i18n:getText("text_TONNE"),
		"6 " .. g_i18n:getText("text_TONNE"),
		"7 " .. g_i18n:getText("text_TONNE"),
		"8 " .. g_i18n:getText("text_TONNE"),
		"9 " .. g_i18n:getText("text_TONNE"),
		"10 " .. g_i18n:getText("text_TONNE"),
		"20 " .. g_i18n:getText("text_TONNE"),
		"50 " .. g_i18n:getText("text_TONNE"),
		"100 " .. g_i18n:getText("text_TONNE"),
		"200 " .. g_i18n:getText("text_TONNE"),
		"500 " .. g_i18n:getText("text_TONNE"),
		"1000 " .. g_i18n:getText("text_TONNE"),
		g_i18n:getText("text_INFINITE").."!"
	}
}
LumberJack.SETTINGS.normalStrengthValue = {
-- LumberJack.normalStrengthValue = 0.2
	['default'] = 2,
	['values'] = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0},
	['strings'] = {
		"100 "..g_i18n:getText("text_KG"),
		"200 "..g_i18n:getText("text_KG"),
		"300 "..g_i18n:getText("text_KG"),
		"400 "..g_i18n:getText("text_KG"),
		"500 "..g_i18n:getText("text_KG"),
		"600 "..g_i18n:getText("text_KG"),
		"700 "..g_i18n:getText("text_KG"),
		"800 "..g_i18n:getText("text_KG"),
		"900 "..g_i18n:getText("text_KG"),
		"1,000 "..g_i18n:getText("text_KG")
	}
}
LumberJack.SETTINGS.superDistanceValue = {
-- LumberJack.superDistanceValue = 12
	['default'] = 2,
	['values'] = {10, 12, 15, 20, 25, 30, 35, 40, 45, 50},
	['strings'] = {
	"10 "..g_i18n:getText("text_METRE"),
	"12 "..g_i18n:getText("text_METRE"),
	"15 "..g_i18n:getText("text_METRE"),
	"20 "..g_i18n:getText("text_METRE"),
	"25 "..g_i18n:getText("text_METRE"),
	"30 "..g_i18n:getText("text_METRE"),
	"35 "..g_i18n:getText("text_METRE"),
	"40 "..g_i18n:getText("text_METRE"),
	"45 "..g_i18n:getText("text_METRE"),
	"50 "..g_i18n:getText("text_METRE")
	}
}
LumberJack.SETTINGS.normalDistanceValue = {
-- LumberJack.normalDistanceValue = 3
	['default'] = 1,
	['values'] = {3, 4, 5, 6, 7, 8},
	['strings'] = {
	"3 "..g_i18n:getText("text_METRE"),
	"4 "..g_i18n:getText("text_METRE"),
	"5 "..g_i18n:getText("text_METRE"),
	"6 "..g_i18n:getText("text_METRE"),
	"7 "..g_i18n:getText("text_METRE"),
	"8 "..g_i18n:getText("text_METRE"),
	}
}
LumberJack.SETTINGS.maxCutDistance = {
-- LumberJack.maxCutDistance = 6.0
	['default'] = 6,
	['values'] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
	['strings'] = {
	"1 "..g_i18n:getText("text_METRE"),
	"2 "..g_i18n:getText("text_METRE"),
	"3 "..g_i18n:getText("text_METRE"),
	"4 "..g_i18n:getText("text_METRE"),
	"5 "..g_i18n:getText("text_METRE"),
	"6 "..g_i18n:getText("text_METRE"),
	"7 "..g_i18n:getText("text_METRE"),
	"8 "..g_i18n:getText("text_METRE"),
	"9 "..g_i18n:getText("text_METRE"),
	"10 "..g_i18n:getText("text_METRE"),
	"11 "..g_i18n:getText("text_METRE"),
	"12 "..g_i18n:getText("text_METRE")
	}
}
LumberJack.SETTINGS.defaultCutDuration = {
-- LumberJack.defaultCutDuration = 4
	['default'] = 4,
	['values'] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
	['strings'] = {
	"1 "..g_i18n:getText("text_SECOND"),
	"2 "..g_i18n:getText("text_SECOND"),
	"3 "..g_i18n:getText("text_SECOND"),
	"4 "..g_i18n:getText("text_SECOND"),
	"5 "..g_i18n:getText("text_SECOND"),
	"6 "..g_i18n:getText("text_SECOND"),
	"7 "..g_i18n:getText("text_SECOND"),
	"8 "..g_i18n:getText("text_SECOND"),
	"9 "..g_i18n:getText("text_SECOND"),
	"10 "..g_i18n:getText("text_SECOND"),
	"11 "..g_i18n:getText("text_SECOND"),
	"12 "..g_i18n:getText("text_SECOND")
	}
}
LumberJack.SETTINGS.maxWalkingSpeed = {
-- LumberJack.maxWalkingSpeed = 4
	['default'] = 1,
	['values'] = {4.0,4.4,4.8,5.2,5.6,6.0,6.4,6.8,7.2,7.6,8.0},
	['strings'] = {
	"100%",
	"110%",
	"120%",
	"130%",
	"140%",
	"150%",
	"160%",
	"170%",
	"180%",
	"190%",
	"200%"
	}
}
LumberJack.SETTINGS.maxRunningSpeed = {
-- LumberJack.maxRunningSpeed = 9
	['default'] = 1,
	['values'] = {9.0,9.9,10.8,11.7,12.6,13.5,14.4,15.3,16.2,17.1,18.0},
	['strings'] = {
	"100%",
	"110%",
	"120%",
	"130%",
	"140%",
	"150%",
	"160%",
	"170%",
	"180%",
	"190%",
	"200%"
	}
}

-- HELPER FUNCTIONS
function LumberJack.setValue(id, value)
	LumberJack[id] = value
end

function LumberJack.getValue(id)
	return LumberJack[id]
end

function LumberJack.getStateIndex(id)
	local value = LumberJack.getValue(id) 
	local values = LumberJack.SETTINGS[id].values
	if type(value) == 'number' then
		local index = LumberJack.SETTINGS[id].default
		local initialdiff = math.huge
		for i, v in pairs(values) do
			local currentdiff = math.abs(v - value)
			if currentdiff < initialdiff then
				initialdiff = currentdiff
				index = i
			end 
		end
		return index
	else
		for i, v in pairs(values) do
			if value == v then
				return i
			end 
		end
	end
	print(id .. " USING DEFAULT")
	return LumberJack.SETTINGS[id].default
end

-- READ/WRITE SETTINGS
function LumberJack.writeSettings()

	local key = "lumberjack"
	local userSettingsFile = Utils.getFilename("modSettings/LumberJack.xml", getUserProfileAppPath())
	
	local xmlFile = createXMLFile("settings", userSettingsFile, key)
	if xmlFile ~= 0 then
	
		local function setXmlValue(id)
			local xmlValueKey = "lumberjack." .. id .. "#value"
			local value = LumberJack.getValue(id)
			if type(value) == 'number' then
				setXMLFloat(xmlFile, xmlValueKey, value)
			elseif type(value) == 'boolean' then
				setXMLBool(xmlFile, xmlValueKey, value)
			end
		end
		
		for _, id in pairs(LumberJack.menuItems) do
			setXmlValue(id)
		end

		saveXMLFile(xmlFile)
		delete(xmlFile)
	end
end

function LumberJack.readSettings()

	local userSettingsFile = Utils.getFilename("modSettings/LumberJack.xml", getUserProfileAppPath())
	
	if g_server == nil and LumberJack.menuItems[1] == 'createWoodchips' then
		table.remove(LumberJack.menuItems, 1)
	end
	
	if not fileExists(userSettingsFile) then
		print("CREATING user settings file: "..userSettingsFile)
		LumberJack.writeSettings()
		return
	end
	
	local xmlFile = loadXMLFile("lumberjack", userSettingsFile)
	if xmlFile ~= 0 then
	
		local function getXmlValue(id)
			local setting = LumberJack.SETTINGS[id]
			if setting then
				local xmlValueKey = "lumberjack." .. id .. "#value"
				local value = LumberJack.getValue(id)
				if type(value) == 'number' then
					value = getXMLFloat(xmlFile, xmlValueKey)
				elseif type(value) == 'boolean' then
					value = getXMLBool(xmlFile, xmlValueKey)
				end
				LumberJack.setValue(id, value)
			end
		end
		
		print("LUMBERJACK SETTINGS")
		if g_client and not g_dedicatedServer then
			for _, id in pairs(LumberJack.menuItems) do
				getXmlValue(id)
				print("  " .. tostring(id) .. ":     " .. tostring(LumberJack[id]))
			end
		else
			local id = 'createWoodchips'
			getXmlValue(id)
			print("  " .. tostring(id) .. ":     " .. tostring(LumberJack[id]))
		end

		delete(xmlFile)
	end
	
end

function LumberJack:onMenuOptionChanged(state, menuOption)
	
	local id = menuOption.id
	local setting = LumberJack.SETTINGS
	local value = setting[id].values[state]
	
	if value ~= nil then
		print("SET " .. id .. " = " .. tostring(value))
		LumberJack.setValue(id, value)
	end

	if id == 'superStrengthValue' or  id == 'normalStrengthValue' or
	   id == 'superDistanceValue' or  id == 'normalDistanceValue' then
		SuperStrengthEvent.sendEvent(LumberJack.superStrength)
	end

	LumberJack.writeSettings()
end

-- APPEND GERNERAL MAIN MENU SETTINGS PAGE 
function LumberJack.onMenuSettingsFrameOpen(self)

	if not LumberJack.createdGUI then
		LumberJack.createdGUI = true
		
		local function addMenuOption(id, original)
			
			local original = original or self.checkAutoHelp
			local callback = "onMenuOptionChanged"
			local i18n_title = "setting_lumberJack_" .. id
			local i18n_tooltip = "toolTip_lumberJack_" .. id
			local options = LumberJack.SETTINGS[id].strings
		
			local menuOption = original:clone()
			menuOption.target = LumberJack
			menuOption.id = id
			
			menuOption:setCallback("onClickCallback", callback)
			menuOption:setDisabled(false)

			local settingTitle = menuOption.elements[4]
			local toolTip      = menuOption.elements[6]

			settingTitle:setText(g_i18n:getText(i18n_title))
			toolTip:setText(g_i18n:getText(i18n_tooltip))
			menuOption:setTexts({unpack(options)})
			
			menuOption:setState(LumberJack.getStateIndex(id))

			return menuOption
		end

		local title = TextElement.new()
		title:applyProfile("settingsMenuSubtitle", true)
		title:setText(g_i18n:getText("menu_LUMBERJACK_TITLE"))
		self.boxLayout:addElement(title)
		
		for _, id in pairs(LumberJack.menuItems) do
			self.boxLayout:addElement(addMenuOption(id))
		end

		self.boxLayout:invalidateLayout()
	end
end