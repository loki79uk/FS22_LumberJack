-- ============================================================= --
-- DELETE SHAPE EVENT
-- ============================================================= --
DeleteShapeEvent = {}
DeleteShapeEvent_mt = Class(DeleteShapeEvent, Event)

InitEventClass(DeleteShapeEvent, "DeleteShapeEvent")

function DeleteShapeEvent.emptyNew()
	--print("DeleteShape - EMPTY NEW")
	local self =  Event.new(DeleteShapeEvent_mt)
	return self
end

function DeleteShapeEvent.new(splitShapeId)
	--print("DeleteShape - NEW")
	local self = DeleteShapeEvent.emptyNew()
	self.splitShapeId = splitShapeId
	return self
end

function DeleteShapeEvent:readStream(streamId, connection)
	--print("DeleteShape - READ STREAM")
    if not connection:getIsServer() then
        local splitShapeId = readSplitShapeIdFromStream(streamId)
        if splitShapeId ~= 0 then
			--print("DeleteShape CLIENT")
            delete(splitShapeId)
        end
    end
end

function DeleteShapeEvent:writeStream(streamId, connection)
	--print("DeleteShape - WRITE STREAM");
	if connection:getIsServer() then
        writeSplitShapeIdToStream(streamId, self.splitShapeId)
    end
end

function DeleteShapeEvent:run(connection)
	--print("Error: DeleteShapeEvent is not allowed to be executed on a local client")
end

function DeleteShapeEvent.sendEvent(splitShapeId)
	--print("DeleteShape - RUN")
	if g_server ~= nil then
		--print("DeleteShape SERVER")
		delete(splitShapeId)
	else
		g_client:getServerConnection():sendEvent(DeleteShapeEvent.new(splitShapeId))
	end
end