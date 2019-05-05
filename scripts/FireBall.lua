local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local FireBall = {
	Properties = {
		Debug = true,
		Speed = 10,
		Damage = 100.0,
		KnockBack = 100.0,
		Range = 30.0,
		TimeOut = 10.0,
	},
}

function FireBall:OnActivate()
	Utilities:InitLogging(self, "FireBall")	
	self.tickListener = TickBus.Connect(self,0)
	local tm = TransformBus.Event.GetWorldTM(self.entityId)
	self.forward = tm.basisY:GetNormalized()
	PhysicsComponentRequestBus.Event.SetVelocity(self.entityId, self.forward * self.Properties.Speed)
	self:Log(tostring(self.forward * self.Properties.Speed))
	self.startPosition = tm:GetTranslation()
	self.rangeSq = self.Properties.Range * self.Properties.Range
	
	self.collisionListener = PhysicsComponentNotificationBus.Connect(self, self.entityId)
end

function FireBall:OnTick(deltaTime, scriptTime)
	--local tm = TransformBus.Event.GetWorldTM(self.entityId)
	--self.forward = tm.basisY:GetNormalized()
	--PhysicsComponentRequestBus.Event.SetVelocity(self.entityId, self.forward * self.Properties.Speed)
	
	local position = TransformBus.Event.GetWorldTranslation(self.entityId)
	if position:GetDistanceSq(self.startPosition) > self.rangeSq then
		GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entityId)
	end
end

function FireBall:OnCollision(collision)
	if collision ~= nil then
		if collision.entity ~= nil and collision.entity:IsValid() then
			if TagComponentRequestBus.Event.HasTag(collision.entity, Crc32("Enemy")) then
				Events:Event(collision.entity, Events.OnDamage, self.Properties.Damage)
				
				local position = TransformBus.Event.GetWorldTranslation(self.entityId)
				local enemyPosition = TransformBus.Event.GetWorldTranslation(collision.entity)
				if enemyPosition ~= nil then
					local attackDirection = enemyPosition - position
					attackDirection.z = 0
					attackDirection = attackDirection:GetNormalized()
					attackDirection = attackDirection * self.Properties.KnockBack
					attackDirection.z = 1.0
					PhysicsComponentRequestBus.Event.AddImpulse(collision.entity, attackDirection)
				end
				
				GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entityId)
			elseif TagComponentRequestBus.Event.HasTag(collision.entity, Crc32("Player")) then
				-- do nothing
			else
				GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entityId)
			end
		else
			GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entityId)
		-- bounce?
			--PhysicsComponentRequestBus.Event.SetVelocity(self.entityId, -collision.normal * self.Properties.Speed)
		end
	else
		GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entityId)
	end
	
end

function FireBall:OnDeactivate()
	if self.tickListener ~= nil then
		self.tickListener:Disconnect()
		self.tickListener = nil
	end
	
	if self.collisionListener then
		self.collisionListener:Disconnect()
		self.collisionListener = nil
	end
end

return FireBall