local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local UIHeartManagerComponent = {
	Properties = {
		Debug = true,
		HealthPerContainer = 100.0,
		TreasurePerContainer = 100.0
	},
	Events = {
		[Events.OnSetNumHeartContainers] = {global=true},
		[Events.OnSetHealthAmount] = {global=true},
		[Events.OnSetTreasureAmount] = {global=true},
	}
}

function UIHeartManagerComponent:OnActivate()
	Utilities:InitLogging(self, "UIHeartManagerComponent")
	Utilities:BindEvents(self, self.Events)
	
	self.healthAmount = 0
	self.treasureAmount = 0
	self.treasureContainer = nil
	self.containers = {}
	
	self.spawnListener = UiSpawnerNotificationBus.Connect(self, self.entityId)
	self.spawnedEntities = {}
end

function UIHeartManagerComponent:Reset()
	self.numContainers = 0
	self.healthAmount = 0
	self.treasureAmount = 0
	
	self:SetNumContainers(1)
end

function UIHeartManagerComponent:SetNumContainers(amount)
	self:Log("Setting num containers " ..tostring(amount))
	
	if self.numContainers == amount then
		return
	end
	
	self.numContainers = amount
	for i, entityId in ipairs(self.spawnedEntities) do
		if entityId ~= nil then
			UiElementBus.Event.DestroyElement(entityId)
		end
	end
	
	self.spawnedEntities = {}	
	self.containers = {}
	
	local offset = 0
	-- create one extra for the construction container
	for i=1,self.numContainers + 1 do
		local sliceTicket = UiSpawnerBus.Event.SpawnAbsolute(self.entityId, Vector2(offset, 0))
		table.insert(self.containers, { ticket = sliceTicket, entityId = nil })
		offset = offset + 32
		self.treasureContainer = self.containers[i]
	end
	
end

function UIHeartManagerComponent:FillContainers(amount)
	self:Log("FillContainers " .. tostring(amount))
	local healthRemaining = tonumber(amount)
	for i, container in ipairs(self.containers) do
		if container.entityId ~= nil then
			local health = healthRemaining % tonumber(self.Properties.HealthPerContainer)
			if healthRemaining >= self.Properties.HealthPerContainer then
				health = self.Properties.HealthPerContainer
			end
			-- send a value between 0..1
			Events:Event(container.entityId, Events.OnSetHealthAmount, health / self.Properties.HealthPerContainer)			
			healthRemaining = Math.Max(0, healthRemaining - self.Properties.HealthPerContainer)		
		end
	end

	self:FillTreasureContainer(self.treasureAmount)
end

function UIHeartManagerComponent:FillTreasureContainer(amount)
--	self:Log("FillTreasureContainer " .. tostring(amount))
	if self.treasureContainer ~= nil and self.treasureContainer.entityId ~= nil then
		self:Log("FillTreasureContainer " .. tostring(amount))
		Events:Event(self.treasureContainer.entityId, Events.OnSetTreasureAmount, amount / self.Properties.TreasurePerContainer)
	end
end

function UIHeartManagerComponent:OnEntitySpawned(sliceTicket, entityId)
	table.insert(self.spawnedEntities, entityId)
	
	-- save the top level entity id for each slice so we can send it messages
	local numSlicesSpawned = 0
	local foundNewSlice = false
	for i, container in ipairs(self.containers) do
		--self:Log("parent is " .. tostring(parent) .. " own id is " .. tostring(self.entityId))
		if container.ticket == sliceTicket then
			local parentId = UiElementBus.Event.GetParent(entityId)
			if container.entityId == nil and parentId == self.entityId then
				container.entityId = entityId
				foundNewSlice = true
			end
		end
		if container.entityId ~= nil then
			numSlicesSpawned = numSlicesSpawned + 1
		end
	end
	
	if foundNewSlice and numSlicesSpawned == (self.numContainers + 1) then
		self:Log("Hearts done spawning")
		self:FillContainers(self.healthAmount)
	end
end


function UIHeartManagerComponent.Events.OnSetNumHeartContainers:OnEventBegin(numContainers)
	self.Component:Log("OnSetNumHeartContainers " .. tostring(numContainers))
	self.Component:SetNumContainers(numContainers)
end

function UIHeartManagerComponent.Events.OnSetHealthAmount:OnEventBegin(amount)
	self.Component:Log("OnSetHealthAmount " .. tostring(amount))
	self.Component.healthAmount = amount
	self.Component:FillContainers(amount)
end

function UIHeartManagerComponent.Events.OnSetTreasureAmount:OnEventBegin(amount)
	self.Component:Log("OnSetTreasureAmount " .. tostring(amount))
	self.Component.treasureAmount = amount
	self.Component:FillTreasureContainer(amount)
end

function UIHeartManagerComponent:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
	
	for i, container in ipairs(self.containers) do
		if container.entityId ~= nil then
			self:Log("Destroying slice " .. tostring(container.entityId))
			GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(container.entityId)
		end
	end
	
	self.containers = {}	
end

return UIHeartManagerComponent