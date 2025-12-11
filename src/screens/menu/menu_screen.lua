local MenuScreen = {}
local Utils = require("src.utils")
local Mouse = require("src.mouse")

-- Cache frequently used functions
local getNormalizedPosition = Mouse.getNormalizedPosition
local drawHUDBackground = Utils.drawHUDBackground
local drawHUDText = Utils.drawHUDText
local debugMousePosition = Utils.debugMousePosition

local background_texture = nil
local background_image = nil
local menu_font = nil
local hovered_index = nil

-- HUD text sizing (normalized units)
local MENU_TEXT_SIZE = 0.136
local MENU_ITEM_SPACING = 0.15
local MENU_SHADOW_OFFSET = 0.0136

-- Menu starting position (normalized units)
local MENU_START_X = -0.867
local MENU_START_Y = -0.232


local function startGame()
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


-- Menu items
local menu_items = {
  {x = MENU_START_X, y = MENU_START_Y, label = "Start Game", callback = startGame },
  {x = MENU_START_X, y = MENU_START_Y + MENU_ITEM_SPACING, label = "Options", callback = options },
  {x = MENU_START_X, y = MENU_START_Y + MENU_ITEM_SPACING * 2, label = "Extras", callback = extras },
  {x = MENU_START_X, y = MENU_START_Y + MENU_ITEM_SPACING * 3, label = "Quit", callback = quit },
}

function MenuScreen.init()
  background_image = lovr.data.newImage('assets/images/main_menu_background.jpg')
  background_texture = lovr.graphics.newTexture(background_image, {})
  menu_font = lovr.graphics.newFont('assets/fonts/Montserrat-ExtraBoldItalic.ttf', 80, 4)
end


function MenuScreen.updateHover(mouse_x, mouse_y)
  local x = mouse_x
  hovered_index = nil
  for i, position in ipairs(menu_items) do
    -- width is MENU_TEXT_SIZE * number of characters in the label
    local labelWidth = 0.45;
    if mouse_y > position.y and mouse_y < position.y + MENU_TEXT_SIZE and x > -0.86 and x < position.x + labelWidth then
      hovered_index = i
      break
    end
  end
end

function MenuScreen.update(dt)
  local mouse_x, mouse_y = getNormalizedPosition()
  if mouse_x and mouse_y then
    MenuScreen.updateHover(mouse_x, mouse_y)
  end
  
  -- Handle mouse clicks
  if lovr.system.wasMousePressed(1) and hovered_index then
    local menu_item = menu_items[hovered_index]
    if menu_item and menu_item.callback then
      menu_item.callback()
    end
  end
end

function MenuScreen.draw(pass)
  drawHUDBackground(pass, background_texture)
  
  for i, position in ipairs(menu_items) do
    local is_hovered = (hovered_index == i)
    local show_shadow = not is_hovered
    local shadow_offset = show_shadow and MENU_SHADOW_OFFSET or nil
    local y_pos = position.y
    drawHUDText(pass, position.label, position.x, y_pos, MENU_TEXT_SIZE, 'left', 'top', menu_font, shadow_offset)
  end
  
  debugMousePosition(pass, menu_font)
end

function MenuScreen.cleanup()
  -- Nothing to cleanup
end

function MenuScreen.onKeyPressed(key, scancode, isrepeat, action)
  -- TODO: Implement key press handling
end

return MenuScreen

