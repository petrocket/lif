local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local CollectableComponent = {
	Properties = {
		Debug = true,
		RequiredTag = "Player", -- only give to entities with this tag
		Item = "", -- item to give
		Amount = 1, -- amount to give
		DestroyOnCollect = true,
	},
	Events = {
		--[Events.OnSetHealthAmount] = {}
	}
}

function CollectableComponent:OnActivate()
	Utilities:InitLogging(self, "CollectableComponent")
	Utilities:BindEvents(self, self.Events)
	
	self.listener = PhysicsComponentNotificationBus.Connect(self, self.entityId)
end

function CollectableComponent:OnCollision(collision)
	if collision.entity ~= nil and collision.entity:IsValid() then
		if self.Properties.RequiredTag ~= "" then	
			if not TagComponentRequestBus.Event.HasTag(collision.entity, Crc32(self.Properties.RequiredTag)) then
				return
			end
		end
		
		self:Log("Giving " .. tostring(self.Properties.Amount) .. " of " .. tostring(self.Properties.Item) .. " to entity")
		
		local args = vector_basic_string_char_char_traits_char()
		args:push_back(self.Properties.Item)
		args:push_back(tostring(self.Properties.Amount))
		Events:Event(collision.entity, Events.OnCollectItem, args)
		
		if self.Properties.DestroyOnCollect then
			GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entityId)
		end
	end
end

function CollectableComponent:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
end


return CollectableComponent