local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"
local StateMachine = require "scripts/ToolKit/statemachine"

local EnemyController = {
	Properties = {
		Debug = true,
		FlashDuration = 2.0,
		FlashRate = 0.5,
		DamageAmount = 10.0,
		KnockBackAmount = 100.0,
		VisibilityCheckInterval = 2.0,
		VisibilityOffset = Vector3(0,0,0.7),
		VisibilityRange = 30.0,
		Awake = true,
		PathEpsilon = 0.1,
		Acceleration = 1.0,
		Speed = 10.0,
	},
	Events = {
		[Events.OnHealthChanged] = {},
		[Events.OnDestroyed] = {},
		[Events.OnWakeUp] = {},
	}
}

function EnemyController:OnActivate()
	Utilities:InitLogging(self, "EnemyController")
	Utilities:BindEvents(self, self.Events)
	
	self.tickHandler = nil
	self.player = EntityId() -- we'll get the player when we wake up
	self.collisionHandler = PhysicsComponentNotificationBus.Connect(self, self.entityId)
	self.nextVisibleCheckTime = 0
	
	self.navigationHandler = nil
	self.pathId = nil
	self.path = nil
	self.nextPathCheckTime = 0
	self.currentPoint = 1
	self.moveDirection = Vector3(0,0,0)
	self.velocity = Vector3(0,0,0)
	
	if self.Properties.Awake then
		Utilities:ExecuteOnNextTick(self, function(self)
			self:WakeUp()
		end)
	end
end

function EnemyController:OnCollision(collision)
	if collision.eventType == Collision.CollisionBegin then
		if TagComponentRequestBus.Event.HasTag(collision.entity, Crc32("Player")) then
			local position = TransformBus.Event.GetWorldTranslation(self.entityId)
			local playerPosition = TransformBus.Event.GetWorldTranslation(collision.entity)
			local attackDirection = playerPosition - position
			attackDirection.z = 0
			attackDirection = attackDirection:GetNormalized()
			attackDirection = attackDirection * self.Properties.KnockBackAmount
			attackDirection.z = 1.0
			PhysicsComponentRequestBus.Event.AddImpulse(collision.entity, attackDirection)
		
			Events:Event(collision.entity, Events.OnDamage, self.Properties.DamageAmount)
		end
	end
end

function EnemyController:OnTick(deltaTime, scriptTime)
	if self.nextVisibleCheckTime < scriptTime:GetSeconds() then
		self.playerPosition = TransformBus.Event.GetWorldTranslation(self.player)
		self.playerVisible = self:VisibilityCheck(self.playerPosition, self.Properties.VisibilityOffset)
		if self.playerVisible then
			self:Log("can see player")
			self:FindPathToEntity(self.player)
			self.nextVisibleCheckTime = scriptTime:GetSeconds() + 0.5
		else
			self:Log("can't see player")
			self.nextVisibleCheckTime = scriptTime:GetSeconds() + self.Properties.VisibilityCheckInterval + math.random()
			self.moveDirection = Vector3(0,0,0)
		end
	end
	
	if self.path ~= nil and #self.path > 0 then
		-- keep moving
		self.position = TransformBus.Event.GetWorldTranslation(self.entityId)
		if self.currentPoint > #self.path then
			self.moveDirection = Vector3(0,0,0)
		else
			self.moveDirection = self.path[self.currentPoint] - self.position
			self.moveDirection.z = 0
			if self.moveDirection:GetLengthSq() < self.Properties.PathEpsilon then
				if self.currentPoint <= #self.path then
					self.currentPoint = self.currentPoint + 1
				else
					--self:Log("Reached end of path")
					self.moveDirection.x = 0
					self.moveDirection.y = 0
				end
			end
		end
	end
	
	local jumpMode = 0
	if self.moveDirection:GetLengthSq() > 0.1 then
		CryCharacterPhysicsRequestBus.Event.RequestVelocity(self.entityId, self.moveDirection:GetNormalized() * self.Properties.Speed, jumpMode)
	else
		CryCharacterPhysicsRequestBus.Event.RequestVelocity(self.entityId, Vector3(0,0,0), jumpMode)
	end
end

function EnemyController:VisibilityCheck(playerPosition, offset)
	self.position = TransformBus.Event.GetWorldTranslation(self.entityId)
	
	local config = RayCastConfiguration()
	local direction = (playerPosition + offset) - (self.position + offset)
	config.direction = direction:GetNormalized()
	config.maxDistance = self.Properties.VisibilityRange
	config.origin = self.position + offset
	config.physicalEntityTypes = PhysicalEntityTypes.All
	config.maxHits = 5
	config.ignoreEntityIds = vector_EntityId()
	config.ignoreEntityIds:push_back(self.entityId)
	--config.physicalEntityTypes = TogglePhysicalEntityTypeMask(config.physicalEntityTypes, PhysicalEntityTypes.Terrain)
	
	local result = PhysicsSystemRequestBus.Broadcast.RayCast(config)
	if result ~= nil then
		for i=1,result:GetHitCount() do
			local hit = result:GetHit(i)
			if hit.entityId == self.player then
				-- can see player
				return true
			end
		end
	end
	
	return false
end

function EnemyController:WakeUp()
	if self.tickHandler == nil then
		self:Log("WakeUp")
		self.tickHandler = TickBus.Connect(self,0)
		local entities = ToolKitRequestBus.Broadcast.GetEntitiesWithTag(Crc32("Player"))
		if entities ~= nil then
			self.player = entities[1]
		end
	end
end

function EnemyController:FindPathToEntity(entity)
	if self.navigationHandler == nil then
		self.navigationHandler = ToolKitNotificationBus.Connect(self)
	end
	
	self.pathId = ToolKitRequestBus.Broadcast.FindPathToEntity(self.entityId, entity)
	self:Log("FindPathToEntity " .. tostring(self.pathId))	
end

function EnemyController:OnNavPathFound(navPathId, pathPoints)
	self:Log("OnNavPathFound " .. tostring(navPathId) .. " " .. tostring(self.pathId))
	-- don't check navpathid because it comes through as 0 (unsigned 32 problem?)
	--if navPathId == self.pathId then
		self:Log("Nav Path Found with " .. tostring(#pathPoints) .. " points")
		self.path = pathPoints
		self.currentPoint = 1
		
		self.navigationHandler:Disconnect()
		self.navigationHandler = nil
	--end
end

function EnemyController:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
	
	if self.collisionHandler ~= nil then
		self.collisionHandler:Disconnect()
		self.collisionHandler = nil
	end
	
	if self.tickHandler ~= nil then
		self.tickHandler:Disconnect()
		self.tickHandler = nil
	end
	
	if self.navigationHandler ~= nil then
		self.navigationHandler:Disconnect()
		self.navigationHandler = nil
	end	
end

function EnemyController.Events.OnHealthChanged:OnEventBegin(value)
	-- TODO stun
	--self.Component:Log(tostring(value))
end

function EnemyController.Events.OnWakeUp:OnEventBegin(value)
	self.Component:Log("WakeUp")
	self.Component:WakeUp()
end

function EnemyController.Events.OnDestroyed:OnEventBegin(value)
	self.Component:Log("Destroyed")
	GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.Component.entityId)
end

return EnemyController