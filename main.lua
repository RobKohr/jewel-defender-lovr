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
-- Server is always available (for local games, it runs in the same process)
local Server = require("src.network.server")

function lovr.load(arg)
  if isServer then
    -- Server mode: initialize authoritative server (headless)
    print("Server mode: Initializing authoritative server...")
    if Server then
      -- Use local transport for now (will add network transport later)
      local useLocalTransport = true
      if not Server.init(useLocalTransport) then
        print("ERROR: Failed to initialize server")
      end
    else
      print("ERROR: Failed to load server module")
    end
    return
  end
  
  -- Client mode: initialize local server (for local games)
  print("Client mode: Initializing local server...")
  if Server then
    -- Use local transport for local games
    local useLocalTransport = true
    if not Server.init(useLocalTransport) then
      print("ERROR: Failed to initialize local server")
    end
  else
    print("ERROR: Failed to load server module")
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
    -- Server mode: update authoritative server only
    if Server then
      Server.update(dt)
    end
    return
  end
  
  -- Client mode: update both server (for local games) and client
  if Server and Server.isInitialized then
    Server.update(dt)
  end
  
  -- Update current screen
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
