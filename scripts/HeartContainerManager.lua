local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local HeartContainerManager = {
	Properties = {
		Debug = true,
		NumContainers = { default = 1.0, step = 1.0, min = 0.0, max = 100.0 },
		TreasurePerContainer = 10,
	},
	Events = {
		[Events.OnReset] = {global = true},
		[Events.OnCollectItem] = {},
		[Events.OnStateChange] = {global = true},
		[Events.OnRefillHealth] = {},
	}
}

function HeartContainerManager:OnActivate()
	Utilities:InitLogging(self, "HeartContainerManager")
	Utilities:BindEvents(self, self.Events)

	self.startingTreasure = 0
	self.startingContainers = self.Properties.NumContainers

	self:Reset()
end

function HeartContainerManager:Reset()
	self.treasureAmount = self.startingTreasure
	self.numContainers = self.startingContainers
	
	Events:GlobalEvent(Events.OnSetNumHeartContainers, self.numContainers)
	Events:GlobalEvent(Events.OnSetTreasureAmount, self.treasureAmount)
end

function HeartContainerManager:AddTreasure(amount)
	local prevNumContainers = self.numContainers
	self.treasureAmount = self.treasureAmount + amount
	
	while self.treasureAmount >= self.Properties.TreasurePerContainer do
		self.numContainers = self.numContainers + 1
		self.treasureAmount = self.treasureAmount - self.Properties.TreasurePerContainer
	end
	
	Events:GlobalEvent(Events.OnSetNumHeartContainers, self.numContainers)
	Events:GlobalEvent(Events.OnSetTreasureAmount, self.treasureAmount)
end

function HeartContainerManager:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
end

function HeartContainerManager.Events.OnRefillHealth:OnEventBegin(value)
	local newHealth = self.Component.numContainers * 100
	-- update the player health component
	Events:Event(self.Component.entityId, Events.OnSetHealthAmount, newHealth)
	
	-- update the HUD
	Events:GlobalEvent(Events.OnSetHealthAmount, newHealth)
end

function HeartContainerManager.Events.OnReset:OnEventBegin(value)
	self.Component:Reset()
end

function HeartContainerManager.Events.OnStateChange:OnEventBegin(newState)
	if newState == "InGame" or newState == "ExitLevel" then
		self.Component.startingTreasure = self.Component.treasureAmount
		self.Component.startingContainers = self.Component.numContainers
	end
end

function HeartContainerManager.Events.OnCollectItem:OnEventBegin(args)
	self.Component:Log("OnCollectItem " .. tostring(args) .. " num args " .. tostring(#args))
	if args ~= nil then
		
		local item = args[1]
		local amount = args[2]
		
		self.Component:Log("Received " .. tostring(amount) .. " of " .. tostring(item))
		if item == "Treasure" then
			self.Component:AddTreasure(tonumber(amount))
		end
	end
end

return HeartContainerManager