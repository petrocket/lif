local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local CanvasStateComponent = {
	Properties = {
		Debug = true,
		State = "",
		StartEnabled = false,
		ShowCursor = true,
	},
	Events = {
		[Events.OnStateChange] = {global=true}
	}
}

function CanvasStateComponent:OnActivate()
	Utilities:InitLogging(self, "CanvasStateComponent")
	Utilities:BindEvents(self, self.Events)
	
	self.canvasListener = UiCanvasAssetRefNotificationBus.Connect(self, self.entityId)
	self.canvasId = nil
	self.enabled = self.Properties.StartEnabled
	UiCanvasAssetRefBus.Event.LoadCanvas(self.entityId)
	
	if self.enabled and self.Properties.ShowCursor then
	  LyShineLua.ShowMouseCursor(true)
	end
end

function CanvasStateComponent:OnCanvasLoadedIntoEntity(entityId)
	self.canvasId = entityId
	if self.canvasId ~= nil then
		UiCanvasBus.Event.SetEnabled(self.canvasId, self.enabled)
		self.canvasListener:Disconnect()
		self.canvasListener = nil
	end
end

function CanvasStateComponent:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
	if self.canvasListener ~= nil then
		self.canvasListener:Disconnect()
		self.canvasListener = nil
	end
end

function CanvasStateComponent.Events.OnStateChange:OnEventBegin(newState)
	if self.Component.canvasId ~= nil then
		local wasEnabled = self.Component.enabled
		self.Component:Log("New state " .. tostring(newState) .. " looking for state " .. tostring(self.Component.Properties.State))
		
		self.Component.enabled = newState == self.Component.Properties.State
		
		if wasEnabled ~= self.Component.enabled then
			UiCanvasBus.Event.SetEnabled(self.Component.canvasId, self.Component.enabled)
			if self.Component.Properties.ShowCursor then
				if self.Component.enabled then
					self.Component:Log("Showing canvas for state " .. tostring(newState))
					UiCursorBus.Broadcast.IncrementVisibleCounter()
				else
					self.Component:Log("Hiding canvas for state " .. tostring(newState))
					if UiCursorBus.Broadcast.IsUiCursorVisible() then
						UiCursorBus.Broadcast.DecrementVisibleCounter()
					end
				end
			end
		end
	end
end


return CanvasStateComponent