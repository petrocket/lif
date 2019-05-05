local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local TriggerGameplayEvent = {
	Properties = {
		Debug = true,
		Event = "",
		Value = "",
		TriggerWhileInside = true,
		Global = false,
		DestroyOnTrigger = false,
	},
}

function TriggerGameplayEvent:OnActivate()
	Utilities:InitLogging(self, "TriggerGameplayEvent")	
	self.listener = TriggerAreaNotificationBus.Connect(self, self.entityId)
	self.tickListener = nil
end

function TriggerGameplayEvent:OnTick(deltaTime, scriptTime)
	-- todo continuous damage
end

function TriggerGameplayEvent:OnTriggerAreaEntered(entityId)
	if entityId ~= nil and entityId:IsValid() then
		self:Log("OnTriggerAreaEntered firing " .. tostring(self.Properties.Event))
		
		if self.Properties.Global then
			Events:GlobalEvent(self.Properties.Event, self.Properties.Value)
		else
			Events:Event(entityId, self.Properties.Event, self.Properties.Value)
		end
		
		if self.Properties.DestroyOnTrigger then
			GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entityId)
		end
	end
end

function TriggerGameplayEvent:OnTriggerAreaExited(entityId)

end

function TriggerGameplayEvent:OnDeactivate()
	if self.listener ~= nil then
		self.listener:Disconnect()
		self.listener = nil
	end
end


return TriggerGameplayEvent