local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local SpawnOnGameplayEvent = {
	Properties = {
		Debug = true,
		DestroyExisting = true,
		Event = "OnReset",
		EventTarget = EntityId(),
	},
}

function SpawnOnGameplayEvent:OnActivate()
	Utilities:InitLogging(self, "SpawnOnGameplayEvent")
	local targetEntityId = self.Properties.EventTarget
	if targetEntityId == nil or not targetEntityId:IsValid() then
		targetEntityId = EntityId(0)
	end
	self.listener = GameplayNotificationBus.Connect(self, GameplayNotificationId(targetEntityId, self.Properties.Event, "float"))
end

function SpawnOnGameplayEvent:OnDeactivate()
	if self.listener ~= nil then
		self.listener:Disconnect()
		self.listener = nil
	end
end

function SpawnOnGameplayEvent:OnEventBegin(newState)
	if self.Properties.DestroyExisting then
		self:Log("Destroying all spawned slices")
		SpawnerComponentRequestBus.Event.DestroyAllSpawnedSlices(self.entityId)
	else
		self:Log("Not destroying all spawned slices")
	end
	
	SpawnerComponentRequestBus.Event.Spawn(self.entityId)
end


return SpawnOnGameplayEvent