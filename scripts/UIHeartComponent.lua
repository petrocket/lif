local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local HeartComponent = {
	Properties = {
		Debug = true,
		ContainerImage = EntityId(),
	},
	Events = {
		[Events.OnSetHealthAmount] = {},
		[Events.OnSetTreasureAmount] = {}
	}
}

function HeartComponent:OnActivate()
	Utilities:InitLogging(self, "UIHeartComponent")
	Utilities:BindEvents(self, self.Events)
end

function HeartComponent:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
end

function HeartComponent.Events.OnSetHealthAmount:OnEventBegin(value)
	-- amount should be between 0 and 1
	self.Component:Log("SetFillAmount " .. tostring(value))
	UiImageBus.Event.SetFillAmount(self.Component.entityId, value)
end

function HeartComponent.Events.OnSetTreasureAmount:OnEventBegin(value)
	-- amount should be between 0 and 1
	self.Component:Log("OnSetTreasureAmount " .. tostring(value))
	UiImageBus.Event.SetFillAmount(self.Component.Properties.ContainerImage, value)
end


return HeartComponent