-- Enum for Available Game Screens
local State = {}
local MenuState = require("src.screens.menu.menu_state")
local GameState = require("src.screens.game.game_state")

local screens_by_name = {
  MenuState = MenuState,
  GameState = GameState,
}


-- default game screen to MenuState
local currentScreen = MenuState -- screen is initialized in main.lua

function State.GetCurrentState()
  return currentScreen
end

function State.SetCurrentState(newStateName)
  currentScreen = screens_by_name[newStateName]
  currentScreen.init()
  return currentScreen
end

return State
