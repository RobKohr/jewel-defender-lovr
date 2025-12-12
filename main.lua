_G = {
  fullscreen = false,
}

local Screen = require("src.screen")
local Keyboard = require("src.keyboard")
local Utils = require("src.utils")
local HUD = require("src.hud")
local GameScreen = require("src.screens.game.game_screen")

function lovr.load()
  if _G.fullscreen then
    Utils.turnOnFullscreen()
  else
    Utils.turnOffFullscreen()
  end
  Screen.SetCurrentScreen("MenuScreen")
end

function lovr.update(dt)
  Screen.GetCurrentScreen().update(dt)
end

function lovr.draw(pass)
  Screen.GetCurrentScreen().draw(pass)
  HUD.showFPS(pass)
  return false
end

function lovr.keypressed(key, scancode, isrepeat)
  local currentScreen = Screen.GetCurrentScreen()
  
  -- Allow GameScreen to intercept escape key before global handler
  if key == "escape" and currentScreen == GameScreen then
    currentScreen.onKeyPressed(key, scancode, isrepeat, nil)
    return
  end
  
  local action = Keyboard.getActionFromKeyboardPress(key, scancode, isrepeat)
  if not Keyboard.handleGlobalActions(action) then
    currentScreen.onKeyPressed(key, scancode, isrepeat, action)
  end
end

function lovr.mousemoved(x, y, dx, dy)
  local currentScreen = Screen.GetCurrentScreen()
  if currentScreen.onMouseMoved then
    currentScreen.onMouseMoved(x, y)
  end
end
