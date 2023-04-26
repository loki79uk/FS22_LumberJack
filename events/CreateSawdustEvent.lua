-- ============================================================= --
-- CREATE SAWDUST EVENT
-- ============================================================= --
CreateSawdustEvent = {}
CreateSawdustEvent_mt = Class(CreateSawdustEvent, Event)

InitEventClass(CreateSawdustEvent, "CreateSawdustEvent")

function CreateSawdustEvent.emptyNew()
	--print("CreateSawdust - EMPTY NEW")
	local self =  Event.new(CreateSawdustEvent_mt)
	return self
end

function CreateSawdustEvent.new(player, amount)
	--print("CreateSawdust - NEW")
	local self = CreateSawdustEvent.emptyNew()
	self.player = player
	self.amount = amount or 0
	return self
end

function CreateSawdustEvent:readStream(streamId, connection)
	--print("CreateSawdust - READ STREAM")
    if not connection:getIsServer() then
        self.player = NetworkUtil.readNodeObject(streamId)
        self.amount = streamReadInt32(streamId)
		
		local currentTool = self.player.baseInformation.currentHandtool
        LumberJack:createSawdust(currentTool, self.amount, true)
		
    end
end

function CreateSawdustEvent:writeStream(streamId, connection)
	--print("CreateSawdust - WRITE STREAM");
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.player)
        streamWriteInt32(streamId, self.amount)
    end
end

function CreateSawdustEvent.sendEvent(player, amount, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server == nil then
			g_client:getServerConnection():sendEvent(CreateSawdustEvent.new(player, amount))
		end
	end
end