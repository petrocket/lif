local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local DamageIndicatorComponent = {
	Properties = {
		Debug = true,
		FlashDuration = 2.0,
		FlashRate = 0.5,
	},
	Events = {
		[Events.OnHealthChanged] = {}
	}
}

function DamageIndicatorComponent:OnActivate()
	Utilities:InitLogging(self, "DamageIndicatorComponent")
	Utilities:BindEvents(self, self.Events)
	
	self.tickHandler = nil
end

function DamageIndicatorComponent:OnTick(deltaTime, scriptTime)
end

function DamageIndicatorComponent:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
end

function DamageIndicatorComponent.Events.OnHealthChanged:OnEventBegin(value)
	-- amount should be between 0 and 1
	self.Component:Log(tostring(value))
	UiImageBus.Event.SetFillAmount(self.Component.entityId, value)
end


return DamageIndicatorComponent