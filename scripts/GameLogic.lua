local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"
local StateMachine = require "scripts/ToolKit/statemachine"

local GameLogic = {
	Properties = {
		Debug = true,
		InitialState = "MainMenu",
		DebugStateMachine = false,
		StartingLevel = 0,
		Player = EntityId(),
	},
	Events = {
		[Events.SetGameState] = {global=true},
		[Events.OnQuitGame] = {global=true},
	},
	States = {
		MainMenu =
        {
        	OnEnter = function(sm)
        		sm.UserData.currentLevel = 0
        		Events:GlobalEvent(Events.OnSetLevel, sm.UserData.currentLevel)
        		-- or continue?
        	end,
        	Transitions =
        	{
        		Shop =
        		{
        			Evaluate = function(sm)
        				return false
        			end
        		}
        	}          
        },       
        Shop =
        {
        	OnEnter = function(sm)
        		-- reset here
        		sm.UserData.PlayerDestroyed = false
        		Events:GlobalEvent(Events.OnReset,1)        	
        	end,
        	Transitions =
        	{
        	}        
        },         
        Reset =
        {
        	OnEnter = function(sm)
        		sm.UserData.PlayerDestroyed = false
        		Events:GlobalEvent(Events.OnReset,1)
        	end,
        	Transitions =
        	{
        		InGame =
        		{
        			Evaluate = function(sm)
        				return true
        			end
        		}
        	}        
        },
       
        InGame = 
        {
            OnEnter = function(sm)
            	sm.UserData.InLevel = true
                sm.UserData:Log("InGame ...")
            end,
            Transitions =
            {
                PlayerDied =
                {
                    Evaluate = function(sm)
                        return sm.UserData.PlayerDestroyed
                    end
                },
                ExitLevel =
                {
                    Evaluate = function(sm)
                        return sm.UserData.InLevel == false
                    end
                }
            }
        },
        PlayerDied =
        {
        	OnEnter = function(sm)
        	end,
        	Transitions =
        	{
        		
        	}
        },
        ExitLevel =
        {
        	OnEnter = function(sm)
        		Events:Event(sm.UserData.Properties.Player, Events.OnSetEnabled, false)
        		sm.UserData.currentLevel = sm.UserData.currentLevel + 1
        		
        		Events:GlobalEvent(Events.OnSetLevel, sm.UserData.currentLevel)
        	end,
        	Transitions =
        	{
        		
        	}
        },
	}
}

function GameLogic:OnActivate()
	Utilities:InitLogging(self, "GameLogic")
	Utilities:BindEvents(self, self.Events)
	self.Events.OnDestroyed = {
		Component = self,
		Listener = nil, 
		OnEventBegin = function(value)
			self:Log("Player destroyed")
			self.PlayerDestroyed = true
		end
	}
	self.Events.OnDestroyed.Listener = GameplayNotificationBus.Connect(self.Events.OnDestroyed, GameplayNotificationId(self.Properties.Player, Events.OnDestroyed, "float"))
	
	self.PlayerDestroyed = false
	self.InLevel = false
	self.currentLevel = self.Properties.StartingLevel
	
    self.StateMachine = {}
    setmetatable(self.StateMachine, StateMachine)
    
    -- execute on the next tick after every entity is activated for this level
    Utilities:ExecuteOnNextTick(self, function(self)
        local sendEventOnStateChange = true
        Events:GlobalEvent(Events.OnSetLevel, self.currentLevel)
        self.StateMachine:Start("Game Logic State Machine", self.entityId, self, self.States, sendEventOnStateChange, self.Properties.InitialState,  self.Properties.DebugStateMachine)    
    end)
end

function GameLogic.Events.SetGameState:OnEventBegin(value)
	self.Component.StateMachine:GotoState(value)
end

function GameLogic.Events.OnQuitGame:OnEventBegin(value)
	ToolKitRequestBus.Broadcast.ExecuteCommand("quit")
end
function GameLogic:OnDeactivate()
	Utilities:UnBindEvents(self.Events)
	self.StateMachine:Stop()
end


return GameLogic