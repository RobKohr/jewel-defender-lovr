local PauseMenu = {}
local Menu = require("src.menu")
local Utils = require("src.utils")

-- Cache frequently used functions
local drawHUDBackground = Utils.drawHUDBackground

local menu = nil
PauseMenu.show = false

-- Menu starting position (normalized units)
local MENU_START_X = -0.867

local function returnToGame()
  PauseMenu.show = false
end

local function returnToMenu()
  local Screen = require("src.screen")
  PauseMenu.show = false
  Screen.SetCurrentScreen("MenuScreen")
end

local function quit()
  lovr.event.quit()
end

function PauseMenu.init()
  -- Create menu instance
  menu = Menu.create()
  menu:setMenuItems(MENU_START_X, {
    {label = "Return to Game", callback = returnToGame},
    {label = "Return to Menu", callback = returnToMenu},
    {label = "Quit", callback = quit},
  })
end

function PauseMenu.update()
  if PauseMenu.show and menu then
    menu:update()
  end
end

function PauseMenu.draw(pass)
  if PauseMenu.show and menu then
    -- Draw semi-transparent overlay
    Utils.setupHUD(pass)
    pass:setColor(0, 0, 0, 0.5)  -- Semi-transparent black overlay
    local viewport_width, viewport_height = pass:getDimensions()
    local aspect = viewport_width / viewport_height
    pass:plane(0, 0, 0, aspect * 2, 2, 0, 0, 1, 0, 'fill')
    pass:setColor(1, 1, 1, 1)
    pass:pop()
    
    -- Draw menu on top
    menu:draw(pass)
  end
end

function PauseMenu.onKeyPressed(key, scancode, isrepeat, action)
  if not PauseMenu.show then
    return
  end
  
  -- Handle escape to close pause menu
  if key == "escape" then
    PauseMenu.show = false
    return true  -- Consume the key event
  end
  
  return false
end

return PauseMenu

