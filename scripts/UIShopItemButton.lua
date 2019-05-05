local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local UIShopItemButton = {
	Properties = {
		Debug = true,
		Item = "",
		QuantityAvailable = 1,
		Text = EntityId(),
		Cost = 1,
	},
	Events = {
		[Events.OnSetItemQuantity] = {global=true}
	}
}

function UIShopItemButton:OnActivate()
	Utilities:InitLogging(self, "UIShopItemButton")
	Utilities:BindEvents(self, self.Events)
	self.owned = false
	self.buttonHandler = UiButtonNotificationBus.Connect(self, self.entityId)
end

function UIShopItemButton:OnButtonClick()
	self:Log("OnButtonClick")
	
	local args = vector_basic_string_char_char_traits_char()
	args:push_back(self.Properties.Item)
	args:push_back(tostring(1))
	args:push_back(tostring(self.Properties.Cost))
	Events:GlobalEvent(Events.OnBuyItem, args)
end

function UIShopItemButton:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
	self.buttonHandler:Disconnect()
end

function UIShopItemButton.Events.OnSetItemQuantity:OnEventBegin(args)
	local item = tostring(args[1])
	local amount = tonumber(args[2])
	if item == self.Component.Properties.Item then
		self.Component:Log("OnSetItemQuantity " .. tostring(item) .. " " .. tostring(amount))
		
		if amount > 0 then
			UiTextBus.Event.SetText(self.Component.Properties.Text, "ALREADY\nOWNED")
			UiInteractableBus.Event.SetIsHandlingEvents(self.Component.entityId, false)
		else
			UiTextBus.Event.SetText(self.Component.Properties.Text, "BUY")
			UiInteractableBus.Event.SetIsHandlingEvents(self.Component.entityId, true)
		end
	end
end

return UIShopItemButton