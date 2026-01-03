_G = {
  fullscreen = false,
}

-- Check for server mode via command-line argument
local isServer = arg and arg[1] == "server"

local Screen = require("src.screen")
local Keyboard = require("src.keyboard")
local Utils = require("src.utils")
local HUD = require("src.hud")
local GameScreen = require("src.screens.game.game_screen")

function lovr.load(arg)
  if isServer then
    -- Server mode: skip UI initialization
    print("Server mode: Initializing network server...")
    -- TODO: Initialize server networking here
    return
  end
  
  -- Client mode: normal initialization
  if _G.fullscreen then
    Utils.turnOnFullscreen()
  else
    Utils.turnOffFullscreen()
  end
  Screen.SetCurrentScreen("MenuScreen")
end

function lovr.update(dt)
  if isServer then
    -- Server mode: update server logic
    -- TODO: Update server networking here
    return
  end
  
  -- Client mode: normal update
  Screen.GetCurrentScreen().update(dt)
end

function lovr.draw(pass)
  if isServer then
    -- Server mode: no rendering
    return false
  end
  
  -- Client mode: normal rendering
  Screen.GetCurrentScreen().draw(pass)
  HUD.showFPS(pass)
  return false
end

function lovr.keypressed(key, scancode, isrepeat)
  if isServer then
    -- Server mode: no input handling
    return
  end
  
  -- Client mode: normal input handling
  local currentScreen = Screen.GetCurrentScreen()
  
  local action = Keyboard.getActionFromKeyboardPress(key, scancode, isrepeat)
  if not Keyboard.handleGlobalActions(action) then
    currentScreen.onKeyPressed(key, scancode, isrepeat, action)
  end
end

function lovr.mousemoved(x, y, dx, dy)
  if isServer then
    -- Server mode: no input handling
    return
  end
  
  -- Client mode: normal input handling
  local currentScreen = Screen.GetCurrentScreen()
  if currentScreen.onMouseMoved then
    currentScreen.onMouseMoved(x, y)
  end
end
