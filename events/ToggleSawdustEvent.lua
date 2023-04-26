-- ============================================================= --
-- TOGGLE SAWDUST EVENT
-- ============================================================= --
ToggleSawdustEvent = {}
ToggleSawdustEvent_mt = Class(ToggleSawdustEvent, Event)

InitEventClass(ToggleSawdustEvent, "ToggleSawdustEvent")

function ToggleSawdustEvent.emptyNew()
	--print("ToggleSawdust - EMPTY NEW")
	local self =  Event.new(ToggleSawdustEvent_mt)
	return self
end

function ToggleSawdustEvent.new(createWoodchips)
	--print("ToggleSawdust - NEW")
	local self = ToggleSawdustEvent.emptyNew()
	self.createWoodchips = createWoodchips
	return self
end

function ToggleSawdustEvent:readStream(streamId, connection)
	--print("ToggleSawdust - READ STREAM")
    if connection:getIsServer() then
        self.createWoodchips = streamReadBool(streamId)
        LumberJack.createWoodchips = self.createWoodchips
    end
end

function ToggleSawdustEvent:writeStream(streamId, connection)
	--print("ToggleSawdust - WRITE STREAM");
	if not connection:getIsServer() then
        streamWriteBool(streamId, self.createWoodchips)
    end
end

function ToggleSawdustEvent.sendEvent(createWoodchips)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlayerPermissionsEvent.new(createWoodchips), false)
		end
	end
end
