local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local HealthComponent = {
	Properties = {
		Debug = true,
		HealthAmount = 100.0,
		DamageCooldown = 0.1,
	},
	Events = {
		[Events.OnDamage] = {},
		[Events.OnSetHealthAmount] = {},
		[Events.OnReset] = {global=true},
		[Events.OnStateChange] = {global = true},
	}
}

function HealthComponent:OnActivate()
	Utilities:InitLogging(self, "UIHeartComponent")
	Utilities:BindEvents(self, self.Events)
	self.StartingHealthAmount = self.Properties.HealthAmount
	self:Reset()
end

function HealthComponent:Reset()
	self.HealthAmount = self.StartingHealthAmount
	self.NextDamageTime = 0
	Events:Event(self.entityId, Events.OnHealthChanged, self.HealthAmount)
end

function HealthComponent:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
end

function HealthComponent.Events.OnReset:OnEventBegin(value)
	self.Component:Reset()
end

function HealthComponent.Events.OnStateChange:OnEventBegin(newState)
	-- save our health amount when starting and ending a level
	if newState == "InGame" or newState == "ExitLevel" then
		self.Component.StartingHealthAmount = self.Component.HealthAmount
	end
end

function HealthComponent.Events.OnSetHealthAmount:OnEventBegin(amount)
	self.Component.HealthAmount = amount
	Events:Event(self.Component.entityId, Events.OnHealthChanged, self.Component.HealthAmount)
end

function HealthComponent.Events.OnDamage:OnEventBegin(value)

	local time = TickRequestBus.Broadcast.GetTimeAtCurrentTick()
	if time:GetSeconds() > self.Component.NextDamageTime then
		
		self.Component.NextDamageTime = time:GetSeconds() + self.Component.Properties.DamageCooldown
		
		local oldHealthAmount = self.Component.HealthAmount
		
		self.Component.HealthAmount = Math.Max(0, oldHealthAmount - value)
		self.Component:Log("Damage " .. tostring(value) .. " health remaining " .. tostring(self.Component.HealthAmount))
		
		if oldHealthAmount ~= self.Component.HealthAmount then
			Events:Event(self.Component.entityId, Events.OnHealthChanged, self.Component.HealthAmount)
		end
		
		if oldHealthAmount > 0.0 and self.Component.HealthAmount < 0.1 then
			Events:Event(self.Component.entityId, Events.OnDestroyed, value)
			Events:GlobalEvent(Events.OnDestroyed, self.Component.entityId)
		end
	end
end

return HealthComponent