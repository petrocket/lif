local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local UIItemIcon = {
	Properties = {
		Debug = true,
		Item = "",
		Cooldown = 0,
		StartActive = false,
		StartEnabled = false,
		ActiveBorder = EntityId(),
		Icon = EntityId(),
	},
	Events = {
		[Events.OnSetItemQuantity] = {global=true},
		[Events.OnSetItemActive] = {global=true},
	}
}

function UIItemIcon:OnActivate()
	Utilities:InitLogging(self, "UIItemIcon")
	Utilities:BindEvents(self, self.Events)
	self.active = self.Properties.StartActive
	self.enabled = self.Properties.StartEnabled
	UiElementBus.Event.SetIsEnabled(self.Properties.Icon, self.enabled)
end

function UIItemIcon:SetEnabled(enabled)
	self:Log("SetEnabled " .. tostring(self.Properties.Item) .. " " .. tostring(enabled))
	UiElementBus.Event.SetIsEnabled(self.Properties.Icon, enabled)
end

function UIItemIcon:SetActive(active)
	self:Log("SetActive " .. tostring(active))
	
	if active then
		UiImageBus.Event.SetAlpha(self.Properties.ActiveBorder, 1)
	else
		UiImageBus.Event.SetAlpha(self.Properties.ActiveBorder, 0)
	end
end

function UIItemIcon:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
end

function UIItemIcon.Events.OnSetItemQuantity:OnEventBegin(args)
	local item = tostring(args[1])
	local amount = tonumber(args[2])
	if item == self.Component.Properties.Item then
		self.Component:Log("OnSetItemQuantity " .. tostring(item) .. " " .. tostring(amount))
		self.Component:SetEnabled(amount > 0)
	end
end

function UIItemIcon.Events.OnSetItemActive:OnEventBegin(item)
	self.Component:SetActive(item == self.Component.Properties.Item)
end

return UIItemIcon