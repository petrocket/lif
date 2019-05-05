local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local CameraController = {
	Properties = {
		Debug = true,
		Player = EntityId(),
		Bounds = EntityId(),
		TerrainHeight = 32.0,
	}
}

function CameraController:OnActivate()
	Utilities:InitLogging(self, "CameraController")
	self.tickHandler = TickBus.Connect(self,0)
	--self.transformHandler = TransformNotificationBus.Connect(self, self.Properties.Player)
	self.playerPosition = TransformBus.Event.GetWorldTranslation(self.Properties.Player)
	self.position = TransformBus.Event.GetWorldTranslation(self.entityId)
	self.offset = Vector3(self.position.x - self.playerPosition.x, self.position.y - self.playerPosition.y, 0)
end

function CameraController:OnTick()
	local position = TransformBus.Event.GetWorldTranslation(self.entityId)
	local playerPosition = TransformBus.Event.GetWorldTranslation(self.Properties.Player)
	
	local destination = self:GetDestinationCameraPosition(position, playerPosition)
	if destination:GetDistanceSq(position) > 0.1 then
		local moveAmount = (destination - position) * 0.1
		TransformBus.Event.SetWorldTranslation(self.entityId, position + moveAmount)
	end
end

function CameraController:OnTransformChanged(localTM, worldTM)
	self.playerPosition = worldTM:GetTranslation()
	local newCameraPosition = self:GetDestinationCameraPosition(self.position, self.PlayerPosition)
	if newCameraPosition:GetDistanceSq(self.position) > 1.0 then
		self.destination = newCameraPosition
	end
end

function CameraController:GetDestinationCameraPosition(currentPosition, playerPosition)
	local inside = ShapeComponentRequestsBus.Event.IsPointInside(self.Properties.Bounds, playerPosition)
	if inside then
		return currentPosition
	else
		local distance =  ShapeComponentRequestsBus.Event.DistanceFromPoint(self.Properties.Bounds, playerPosition)
		local boundsCenter = TransformBus.Event.GetWorldTranslation(self.Properties.Bounds)
		local direction = playerPosition - boundsCenter
		direction.z = 0
		direction = direction:GetNormalized()
		--self:Log("Direction " .. tostring(direction))
		return currentPosition + (direction * distance)
	end
	return currentPosition
end

function CameraController:OnDeactivate()
	if self.tickHandler ~= nil then
		self.tickHandler:Disconnect()
		self.tickHandler = nil
	end
end

return CameraController