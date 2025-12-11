_G = {
  fullscreen = false,
}

local Screen = require("src.screen")
local Keyboard = require("src.keyboard")
local Utils = require("src.utils")

function lovr.load()
  if _G.fullscreen then
    Utils.turnOnFullscreen()
  else
    Utils.turnOffFullscreen()
  end
  Screen.SetCurrentScreen("GameScreen")
end

function lovr.update(dt)
  Screen.GetCurrentScreen().update(dt)
end

function lovr.draw(pass)
  Screen.GetCurrentScreen().draw(pass)
  Utils.showFPS(pass)
  return false
end

function lovr.keypressed(key, scancode, isrepeat)
  local action = Keyboard.getActionFromKeyboardPress(key, scancode, isrepeat)
  if not Keyboard.handleGlobalActions(action) then
    Screen.GetCurrentScreen().onKeyPressed(key, scancode, isrepeat, action)
  end
end

function lovr.mousemoved(x, y, dx, dy)
  local currentScreen = Screen.GetCurrentScreen()
  if currentScreen.onMouseMoved then
    currentScreen.onMouseMoved(x, y)
  end
end
