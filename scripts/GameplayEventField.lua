local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local GameplayEventField = {
	Properties = {
		Debug = true,
		Event = "",
		Prefix = "",
		Suffix = "",
		Global = false,
	},
}

function GameplayEventField:OnActivate()
	Utilities:InitLogging(self, "GameplayEventField")	
	if self.Properties.Global then
		self.listener = GameplayNotificationBus.Connect(self, GameplayNotificationId(EntityId(0), self.Properties.Event, "float"))
	else
		self.listener = GameplayNotificationBus.Connect(self, GameplayNotificationId(self.entityId, self.Properties.Event, "float"))
	end
end

function GameplayEventField:OnEventBegin(value)
	UiTextBus.Event.SetText(self.entityId, self.Properties.Prefix .. tostring(value) .. self.Properties.Suffix)
end

function GameplayEventField:OnDeactivate()
	if self.listener ~= nil then
		self.listener:Disconnect()
		self.listener = nil
	end
end


return GameplayEventField