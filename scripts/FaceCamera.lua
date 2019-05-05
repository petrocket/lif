local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local FaceCamera = {
	Properties = {
		Debug = true,
		Camera = EntityId(),
	},
}

function FaceCamera:OnActivate()
	Utilities:InitLogging(self, "FaceCamera")
	self.listener = TickBus.Connect(self,0)
	self.tm = TransformBus.Event.GetWorldTM(self.entityId)
	--self.orientation = Quaternion.CreateFromTransform(tm)
end

function FaceCamera:OnTick(deltaTime, scriptTime)
	
	--local cameraTM = TransformBus.Event.GetWorldTM(self.Properties.Camera)
	local position = TransformBus.Event.GetWorldTranslation(self.entityId)
	if self.tm ~= nil then
		--local facingTM = MathUtils.CreateLookAt(tm:GetPosition(), cameraTM:GetPosition(), AxisType.ZPositive)
		
		--local orientation = Quaternion.CreateFromTransform(facingTM)
		
		--local axis = Vector3(1,0,0)
		--local orientation = Quaternion.CreateFromAxisAngle(axis:GetNormalized(), 0)
		self.tm:SetPosition(position)
		--tm:SetRotationPartFromQuaternion(self.orientation)
		TransformBus.Event.SetWorldTM(self.entityId,self.tm)
	end
end

function FaceCamera:OnDeactivate()
	if self.listener ~= nil then
		self.listener:Disconnect()
		self.listener = nil
	end
end

return FaceCamera