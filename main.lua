_G = {
  fullscreen = false,
}

local State = require("src.state")
local Keyboard = require("src.keyboard")
local Utils = require("src.utils")

function lovr.load()
  if _G.fullscreen then
    Utils.turnOnFullscreen()
  else
    Utils.turnOffFullscreen()
  end
  State.SetCurrentState("MenuState")
end

function lovr.update(dt)
  State.GetCurrentState().update(dt)
end

function lovr.draw(pass)
  State.GetCurrentState().draw(pass)
  Utils.showFPS(pass)
  return false
end

function lovr.keypressed(key, scancode, isrepeat)
  local action = Keyboard.getActionFromKeyboardPress(key, scancode, isrepeat)
  if not Keyboard.handleGlobalActions(action) then
    State.GetCurrentState().onKeyPressed(key, scancode, isrepeat, action)
  end
end

function lovr.mousemoved(x, y, dx, dy)
  local currentState = State.GetCurrentState()
  if currentState.onMouseMoved then
    currentState.onMouseMoved(x, y)
  end
end
