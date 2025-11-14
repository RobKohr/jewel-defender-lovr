-- Enum for Available Game States
local State = {}
local MenuState = require("src.states.menu.menu_state")
local GameState = require("src.states.game.game_state")

local states_by_name = {
  MenuState = MenuState,
  GameState = GameState,
}


-- default game state to MenuState
local currentState = MenuState

-- Function to get the current game state
function State.GetCurrentState()
  return currentState
end

-- Function to set the current game state
function State.SetCurrentState(newStateName)
  currentState = states_by_name[newStateName]
  currentState.init()
  return currentState
end

return State
