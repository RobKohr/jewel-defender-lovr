local OnlineMenuScreen = {}
local HUD = require("src.hud")
local Menu = require("src.menu")

-- Cache frequently used functions
local drawHUDBackground = HUD.drawHUDBackground

local background_texture = nil
local background_image = nil
local menu = nil

-- Menu starting position (normalized units)
local MENU_START_X = -0.867

local function quickMatch()
  print("Quick Match")
  -- TODO: Implement quick match functionality
end

local function joinPrivateGame()
  print("Join Private Game")
  -- TODO: Implement join private game functionality
end

local function createPrivateGame()
  print("Create A Private Game")
  -- TODO: Implement create private game functionality
end

local function backToMainMenu()
  local Screen = require("src.screen")
  Screen.SetCurrentScreen("MenuScreen")
end

function OnlineMenuScreen.init()
  background_image = lovr.data.newImage('assets/images/main_menu_background.jpg')
  background_texture = lovr.graphics.newTexture(background_image, {})
  
  -- Create menu instance
  menu = Menu.create()
  menu:setMenuItems(MENU_START_X, {
    {label = "Quick Match", callback = quickMatch},
    {label = "Join Private Game", callback = joinPrivateGame},
    {label = "Create A Private Game", callback = createPrivateGame},
    {label = "Back to Main Menu", callback = backToMainMenu},
  })
  
  -- Enable debug mouse position
  menu:setShowDebugMousePosition(true)
end

function OnlineMenuScreen.update(dt)
  if menu then
    menu:update()
  end
end

function OnlineMenuScreen.draw(pass)
  drawHUDBackground(pass, background_texture)
  
  if menu then
    menu:draw(pass)
  end
end

function OnlineMenuScreen.cleanup()
  -- Nothing to cleanup
end

function OnlineMenuScreen.onKeyPressed(key, scancode, isrepeat, action)
  -- Handle escape to go back to main menu
  if key == "escape" then
    backToMainMenu()
    return
  end
  
  if menu then
    menu:onKeyPressed(key, scancode, isrepeat, action)
  end
end

return OnlineMenuScreen
