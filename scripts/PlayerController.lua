local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"
local StateMachine = require "scripts/ToolKit/statemachine"


local PlayerController = {
	Properties = {
		Debug = true,
		MoveSpeed = 1.0,
		SmoothFactor = 0.9,
		AttackRate = 0.1,
		MeleeBounds = EntityId(),
		Front = EntityId(),
		WeaponDamageAmount = 10.0,
		KnockBackAmount = 100.0,
		FireBallSpawner = EntityId(),
	},
	Events = {
		[Events.OnDestroyed] = {},
		[Events.OnReset] = {global=true},
		[Events.OnHealthChanged] = {},
		[Events.OnSetEnabled] = {},
		[Events.OnCollectItem] = {global=true},
		[Events.OnSetLevel] = {global=true},
	},
	InputEvents = {
		OnMoveUpDown = {},
		OnMoveLeftRight = {},
		OnAttack = {},
		OnSelectItem1 = {},
		OnSelectItem2 = {},
		OnSelectItem3 = {},
		OnSelectItem4 = {},
		OnSelectItem5 = {},
	}
}

function PlayerController:OnActivate()
	Utilities:InitLogging(self, "PlayerController")
	Utilities:BindEvents(self, self.Events)
	self.moveDirection = Vector2(0,0)
	self.items = {
		{name = "Sword", quantity = 1},
		{name = "MagicSword", quantity = 0},
		{name = "FireBall", quantity = 0},
		{name = "Storm", quantity = 0},
	}
	self.activeItem = self.items[1]
	self.activeAttack = self.OnAttackSword
	self.currentLevel = 0
	self.rotation = 0
	self.facing = Vector2(0,0)
	
	PhysicsComponentRequestBus.Event.DisablePhysics(self.entityId)
end

function PlayerController:Reset()
	self:Log("Reset")
	
	self.moveDirection = Vector2(0,0)
	self.attack = false
	self.nextAttackTime = 0
	self.activeAttack = self.OnAttackSword
	self.activeItem = self.items[1]
	
	TransformBus.Event.SetLocalRotation(self.entityId, Vector3(0,0,0))

	-- find player start
	local entities = ToolKitRequestBus.Broadcast.GetEntitiesWithTag(Crc32("PlayerStart"..tostring(self.currentLevel)))
	if entities ~= nil and #entities > 0 then		
		local startPosition = TransformBus.Event.GetWorldTranslation(entities[1])
		if startPosition ~= nil then
			self:Log("moving to PlayerStart ")
			TransformBus.Event.SetWorldTranslation(self.entityId, startPosition)
		end
	else
		self:Log("didn't find PlayerStart")
	end
	
	self.tickHandler = TickBus.Connect(self,0)
	
	PhysicsComponentRequestBus.Event.EnablePhysics(self.entityId)

	self:BindInputEvents(self.InputEvents)

	-- let everyone know what items we own
	for i,item in ipairs(self.items) do
		local args = vector_basic_string_char_char_traits_char()
		args:push_back(item.name)
		args:push_back(tostring(item.quantity))
		Events:GlobalEvent(Events.OnSetItemQuantity, args)
	end
	
	self.enabled = true
end

function PlayerController:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
	self:UnBindInputEvents(self.InputEvents)
	
	if self.tickHandler ~= nil then
		self.tickHandler:Disconnect()
		self.tickHandler =nil
	end
end

function PlayerController:OnTick(deltaTime, scriptTime)
	local moveSq = self.moveDirection:GetLengthSq()
	local move = Vector3(0,0,0)
	local attacking = false
	if self.enabled then
		if self.attack then
			attacking = self:OnAttack(scriptTime)
		end
		
		if moveSq > 0.001 then
			move = Vector3(self.moveDirection.x ,self.moveDirection.y ,0)
			move = move:GetNormalized() * self.Properties.MoveSpeed * deltaTime
			self.facing = move
			
			-- rotate to face move direction, annoying because can't attack while retreating
			local tm = TransformBus.Event.GetWorldTM(self.entityId)
			local angle = Math.ArcTan2(-self.moveDirection.x, self.moveDirection.y)
			self.rotation = angle
			local orientation = Quaternion.CreateFromAxisAngle(Vector3(0,0,1), angle)
			tm:SetRotationPartFromQuaternion(orientation)
			--TransformBus.Event.SetWorldTM(self.entityId, tm)
			TransformBus.Event.SetLocalRotation(self.Properties.Front, Vector3(0,0,self.rotation))
		end	
		-- framerate dependent smoothing (TODO make independent of fps)
		self.moveDirection.x = self.moveDirection.x * self.Properties.SmoothFactor
		self.moveDirection.y = self.moveDirection.y * self.Properties.SmoothFactor
	end
	
	if self.attack then
		if self.facing.x > 0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "AttackRightSword")
		elseif self.facing.x < -0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "AttackLeftSword")
		elseif self.facing.y > 0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "AttackUpSword")
		elseif self.facing.y < -0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "AttackDownSword")
		end	
	elseif moveSq > 0.001 then
		if move.x > 0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "WalkRight")
		elseif move.x < -0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "WalkLeft")
		elseif move.y > 0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "WalkUp")
		elseif move.y < -0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "WalkDown")
		end
	else
		if self.facing.x > 0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "Right")
		elseif self.facing.x < -0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "Left")
		elseif self.facing.y > 0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "Up")
		elseif self.facing.y < -0.1 then
			Events:GlobalEvent(Events.OnPlayAnimation, "Down")
		end	
	end
	
	local jumpMode = 0
	CryCharacterPhysicsRequestBus.Event.RequestVelocity(self.entityId, move, jumpMode)
end

function PlayerController:OnAttackFireBall(scriptTime)
	if self.nextAttackTime < scriptTime:GetSeconds() then
		self.nextAttackTime = scriptTime:GetSeconds() + self.Properties.AttackRate * 3.0
		self:Log("Fireball")
		--local orientation = Quaternion.CreateFromAxisAngle(Vector3(0,0,1), self.rotation)
		--TransformBus.Event.SetLocalRotation(self.Properties.Front, Vector3(0,0,self.rotation))
		self.sliceTicket = SpawnerComponentRequestBus.Event.Spawn(self.Properties.FireBallSpawner)
		return true
	end
	return false
end

function PlayerController:OnAttackMagicSword(scriptTime)
	if self.nextAttackTime < scriptTime:GetSeconds() then
		-- slower attack, more damage
		self.nextAttackTime = scriptTime:GetSeconds() + self.Properties.AttackRate * 2.0
		
		--TransformBus.Event.SetLocalRotation(self.Properties.Front, Vector3(0,0,self.rotation))

		-- find any enemies in our shape and damage em
		local aabb = ShapeComponentRequestsBus.Event.GetEncompassingAabb(self.Properties.MeleeBounds)
		local entities = PhysicsSystemRequestBus.Broadcast.GatherPhysicalEntitiesInAABB(aabb, PhysicalEntityTypes.Living)
		
		for i=1,#entities do
			local entityId = entities[i]
			if TagComponentRequestBus.Event.HasTag(entityId, Crc32("Enemy")) then
				--self:Log("Hit self ")
			--else
				--self:Log("Hit " .. tostring(entityId))
				
				-- knock back a bit
				local position = TransformBus.Event.GetWorldTranslation(self.entityId)
				local enemyPosition = TransformBus.Event.GetWorldTranslation(entityId)
				local attackDirection = enemyPosition - position
				attackDirection.z = 0
				attackDirection = attackDirection:GetNormalized()
				attackDirection = attackDirection * self.Properties.KnockBackAmount
				attackDirection.z = 1.0
				PhysicsComponentRequestBus.Event.AddImpulse(entityId, attackDirection)
				
				Events:Event(entityId, Events.OnDamage, self.Properties.WeaponDamageAmount * 3.0)				
			end
		end	
		return true	
	end
	return false
end

function PlayerController:OnAttackStorm(scriptTime)
	if self.nextAttackTime < scriptTime:GetSeconds() then
		self.nextAttackTime = scriptTime:GetSeconds() + self.Properties.AttackRate
		self:Log("storm")
		return true
	end
	return false
end

function PlayerController:OnAttackSword(scriptTime)
	if self.nextAttackTime < scriptTime:GetSeconds() then
		self.nextAttackTime = scriptTime:GetSeconds() + self.Properties.AttackRate
		--TransformBus.Event.SetLocalRotation(self.Properties.Front, Vector3(0,0,self.rotation))
		-- find any enemies in our shape and damage em
		local aabb = ShapeComponentRequestsBus.Event.GetEncompassingAabb(self.Properties.MeleeBounds)
		local entities = PhysicsSystemRequestBus.Broadcast.GatherPhysicalEntitiesInAABB(aabb, PhysicalEntityTypes.Living)
		
		for i=1,#entities do
			local entityId = entities[i]
			if TagComponentRequestBus.Event.HasTag(entityId, Crc32("Enemy")) then
				--self:Log("Hit self ")
			--else
				--self:Log("Hit " .. tostring(entityId))
				
				-- knock back a bit
				local position = TransformBus.Event.GetWorldTranslation(self.entityId)
				local enemyPosition = TransformBus.Event.GetWorldTranslation(entityId)
				local attackDirection = enemyPosition - position
				attackDirection.z = 0
				attackDirection = attackDirection:GetNormalized()
				attackDirection = attackDirection * self.Properties.KnockBackAmount
				attackDirection.z = 1.0
				PhysicsComponentRequestBus.Event.AddImpulse(entityId, attackDirection)
				
				Events:Event(entityId, Events.OnDamage, self.Properties.WeaponDamageAmount)				
			end
		end
		return true
	end
	return false
end

function PlayerController:OnAttack(scriptTime)
	local attacking = self:activeAttack(scriptTime)
	return attacking
end

function PlayerController:SelectItem(itemNumber)
	-- hack for now only 4 items
	if itemNumber > 4 then
		self:Log("Not selecting item " .. tostring(itemNumber))
		return
	end
	
	if itemNumber > 0 and itemNumber <= #self.items then
		local item = self.items[itemNumber]
		if item.quantity > 0 then
			self:Log("Switching to item " .. tostring(item.name))
			self.activeItem = item
			self.activeAttack = self["OnAttack" .. tostring(item.name)]
			Events:GlobalEvent(Events.OnSetItemActive, item.name)
		else
			self:Log("Cannot switch to item " .. tostring(item.name))
		end
	end
end

function PlayerController.Events.OnCollectItem:OnEventBegin(args)
	
	local foundItem = false
	for i,item in ipairs(self.Component.items) do
		if item.name == tostring(args[1]) then
			foundItem = true
			item.quantity = tonumber(args[2])
			self.Component:Log("OnCollectItem found existing item " .. tostring(args[1]) .. " " .. tostring(args[2]))
			Events:GlobalEvent(Events.OnSetItemQuantity, args)
			return
		end
	end
	
	if not foundItem then
		table.insert(self.Component.items, {name=args[1], quantity=tonumber(args[2])})
		self.Component:Log("OnCollectItem adding new item " .. tostring(args[1]) .. " " .. tostring(args[2]))
		Events:GlobalEvent(Events.OnSetItemQuantity, args)
	end
end

function PlayerController.Events.OnReset:OnEventBegin(value)
	self.Component:Reset()
end

function PlayerController.Events.OnSetLevel:OnEventBegin(value)
	self.Component.currentLevel = value
end

function PlayerController.Events.OnSetEnabled:OnEventBegin(value)
	self.Component.enabled = value
	self.Component.moveDirection = Vector2(0,0)
end

function PlayerController.Events.OnHealthChanged:OnEventBegin(amount)
	-- broadcast the value so the HUD can pick it up
	self.Component:Log("Sending OnSetHealthAmount globally")
	Events:GlobalEvent(Events.OnSetHealthAmount,amount)
end

function PlayerController.Events.OnDestroyed:OnEventBegin(value)
	self.Component.enabled = false
	self.Component:Log("Player died")
	if self.Component.tickHandler ~= nil then
		self.Component.tickHandler:Disconnect()
	end

	local jumpMode = 0
	CryCharacterPhysicsRequestBus.Event.RequestVelocity(self.Component.entityId, Vector3(0,0,0), jumpMode)
	PhysicsComponentRequestBus.Event.DisablePhysics(self.Component.entityId)
	
	local deathTM = Transform.CreateIdentity()
	deathTM = deathTM.CreateRotationX(Math.DegToRad(90.0))
	local position = TransformBus.Event.GetWorldTranslation(self.Component.entityId)
	deathTM:SetTranslation(position + Vector3(0,0,16.0))
	--TransformBus.Event.SetWorldTM(self.Component.entityId, deathTM) -- this causes huge jitter somehow
	TransformBus.Event.SetLocalRotation(self.Component.entityId, Vector3(0, Math.DegToRad(90),0))
	
	self.Component:UnBindInputEvents(self.Component.InputEvents)
	--TransformBus.Event.MoveEntity(self.Component.entityId, Vector3(0,0,16.0))
end

-- input events
function PlayerController:BindInputEvents(events)
	for event, handler in pairs(events) do
		handler.Component = self
		handler.Listener = InputEventNotificationBus.Connect(handler, InputEventNotificationId(event))
	end
end

function PlayerController:UnBindInputEvents(events)
	for event, handler in pairs(events) do
		if handler.Listener ~= nil then
			handler.Listener:Disconnect()
			handler.Listener = nil
		end
	end
end

function PlayerController.InputEvents.OnMoveUpDown:OnHeld(value)
	self.Component.moveDirection.y = value
end

function PlayerController.InputEvents.OnMoveLeftRight:OnHeld(value)
	self.Component.moveDirection.x = value
end

function PlayerController.InputEvents.OnAttack:OnHeld(value)
	self.Component.attack = true
end

function PlayerController.InputEvents.OnAttack:OnReleased(value)
	self.Component.attack = false
end

function PlayerController.InputEvents.OnSelectItem1:OnPressed(value)
	self.Component:SelectItem(1)
end
function PlayerController.InputEvents.OnSelectItem2:OnPressed(value)
	self.Component:SelectItem(2)
end
function PlayerController.InputEvents.OnSelectItem3:OnPressed(value)
	self.Component:SelectItem(3)
end
function PlayerController.InputEvents.OnSelectItem4:OnPressed(value)
	self.Component:SelectItem(4)
end
function PlayerController.InputEvents.OnSelectItem5:OnPressed(value)
	self.Component:SelectItem(5)
end

return PlayerController