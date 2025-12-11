-- Enum for Available Game Screens
local Screen = {}
local MenuScreen = require("src.screens.menu.menu_screen")
local GameScreen = require("src.screens.game.game_screen")

local screens_by_name = {
  MenuScreen = MenuScreen,
  GameScreen = GameScreen,
}


-- default game screen to MenuScreen
local currentScreen = MenuScreen -- screen is initialized in main.lua

function Screen.GetCurrentScreen()
  return currentScreen
end

function Screen.SetCurrentScreen(newScreenName)
  currentScreen = screens_by_name[newScreenName]
  currentScreen.init()
  return currentScreen
end

return Screen
