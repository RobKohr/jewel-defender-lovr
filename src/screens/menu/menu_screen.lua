local MenuScreen = {}
local HUD = require("src.hud")
local Menu = require("src.menu")

-- Cache frequently used functions
local drawHUDBackground = HUD.drawHUDBackground

local background_texture = nil
local background_image = nil
local menu = nil

-- Menu starting position (normalized units)
local MENU_START_X = -0.867

local function startLocalGame()
  local Screen = require("src.screen")
  Screen.SetCurrentScreen("GameScreen")
end
local function options()
  print("Options")
end
local function extras()
  print("Extras")
end
local function quit()
  lovr.event.quit()
end

local function startOnlineGame()
  local Screen = require("src.screen")
  Screen.SetCurrentScreen("OnlineMenuScreen")
end

function MenuScreen.init()
  background_image = lovr.data.newImage('assets/images/main_menu_background.jpg')
  background_texture = lovr.graphics.newTexture(background_image, {})
  
  -- Create menu instance
  menu = Menu.create()
  menu:setMenuItems(MENU_START_X, {
    {label = "Play Online Game", callback = startOnlineGame},
    {label = "Start Local Game", callback = startLocalGame},
    {label = "Options", callback = options},
    {label = "Extras", callback = extras},
    {label = "Quit", callback = quit},
  })
  
  -- Enable debug mouse position
  menu:setShowDebugMousePosition(true)
end

function MenuScreen.update(dt)
  if menu then
    menu:update()
  end
end

function MenuScreen.draw(pass)
  drawHUDBackground(pass, background_texture)
  
  if menu then
    menu:draw(pass)
  end
end

function MenuScreen.cleanup()
  -- Nothing to cleanup
end

function MenuScreen.onKeyPressed(key, scancode, isrepeat, action)
  -- Handle escape to quit when on menu screen
  if key == "escape" then
    lovr.event.quit()
    return
  end
  
  if menu then
    menu:onKeyPressed(key, scancode, isrepeat, action)
  end
end

return MenuScreen

