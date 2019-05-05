local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local UiShop = {
	Properties = {
		Debug = true,
		HealthText = EntityId(),
	},
	Events = {
		[Events.OnBuyItem] = {global=true},
		[Events.OnRefundAll] = {global=true},
		[Events.OnStateChange] = {global=true},
		[Events.OnSetHealthAmount] = {global=true},
	}
}

function UiShop:OnActivate()
	Utilities:InitLogging(self, "UiShop")
	Utilities:BindEvents(self, self.Events)
	
	self.itemsToBuy = {}
	self.totalCost = 0
	self.healthAmount = 0
end

function UiShop:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
end

function UiShop.Events.OnStateChange:OnEventBegin(newState)
	if newState == "Shop" then
		self.Component.itemsToBuy = {}
		self.totalCost = 0
	elseif newState == "InGame" then
		local total = 0
		
		-- give the player the stuff
		for i,item in ipairs(self.Component.itemsToBuy) do
			local args = vector_basic_string_char_char_traits_char()
			args:push_back(item.name)
			args:push_back(tostring(item.quantity))
			total = total + item.cost
			Events:GlobalEvent(Events.OnCollectItem, args)
		end
		
		-- deduct the health from the player
		local entities = ToolKitRequestBus.Broadcast.GetEntitiesWithTag(Crc32("Player"))
		if entities ~= nil then
			Events:Event(entities[1], Events.OnSetHealthAmount, self.Component.healthAmount)
		end
	end
end

function UiShop.Events.OnBuyItem:OnEventBegin(args)
	local name = tostring(args[1])
	local quantity = tonumber(args[2])
	local cost = tonumber(args[3])
	
	if self.Component.healthAmount - cost <= 0 then
		self.Component:Log("Cannot buy this - not enough health")
	else
		self.Component:Log("OnBuyItem " .. name)
		self.Component.healthAmount = self.Component.healthAmount - cost
		self.Component.totalCost = self.Component.totalCost + cost
		UiTextBus.Event.SetText(self.Component.Properties.HealthText, "x " .. tostring(self.Component.healthAmount))
		
		local item = vector_basic_string_char_char_traits_char()
		item:push_back(name)
		item:push_back(tostring(quantity))
		Events:GlobalEvent(Events.OnSetItemQuantity, item)
		
		table.insert(self.Component.itemsToBuy, { name=args[1], quantity = tonumber(args[2]), cost = tonumber(args[3]) } )	
	end
end

function UiShop.Events.OnRefundAll:OnEventBegin(value)
	
end

function UiShop.Events.OnSetHealthAmount:OnEventBegin(amount)
	self.Component.healthAmount = amount
end

return UiShop