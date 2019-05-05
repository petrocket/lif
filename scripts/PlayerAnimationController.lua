local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local PlayerAnimationController = {
	Properties = {
		Debug = true,
		Animations = {
			Right = EntityId(),
			Left = EntityId(),
			Up = EntityId(),
			Down = EntityId(),
			WalkDown = EntityId(),
			WalkUp = EntityId(),
			WalkRight = EntityId(),
			WalkLeft = EntityId(),
			AttackRightSword = EntityId(),
			AttackLeftSword = EntityId(),
			AttackUpSword = EntityId(),
			AttackDownSword = EntityId(),
		}
	},
	Events = {
		[Events.OnPlayAnimation] = {global=true}
	}
}

function PlayerAnimationController:OnActivate()
	Utilities:InitLogging(self, "PlayerAnimationController")
	Utilities:BindEvents(self, self.Events)
end

function PlayerAnimationController.Events.OnPlayAnimation:OnEventBegin(animation)
	for animName,entityId in pairs(self.Component.Properties.Animations) do
		if animName == animation then
			UiElementBus.Event.SetIsEnabled(entityId, true)
		else
			UiElementBus.Event.SetIsEnabled(entityId, false)
		end
	end	
end

function PlayerAnimationController:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
end

return PlayerAnimationController