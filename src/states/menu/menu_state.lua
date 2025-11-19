local MenuState = {}
local Utils = require("src.utils")
local Mouse = require("src.mouse")

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

-- Menu options
local menu_options = {
  "Start Game",
  "Options",
  "Extras",
  "Quit"
}

local menu_item_positions = {
  {x = MENU_START_X, y = MENU_START_Y},
  {x = MENU_START_X, y = MENU_START_Y + MENU_ITEM_SPACING},
  {x = MENU_START_X, y = MENU_START_Y + MENU_ITEM_SPACING * 2},
  {x = MENU_START_X, y = MENU_START_Y + MENU_ITEM_SPACING * 3},
}

function MenuState.init()
  background_image = lovr.data.newImage('assets/images/main_menu_background.jpg')
  background_texture = lovr.graphics.newTexture(background_image, {})
  menu_font = lovr.graphics.newFont('assets/fonts/Montserrat-ExtraBoldItalic.ttf', 80, 4)
end


function MenuState.updateHover(mouse_x, mouse_y, aspect)
  hovered_index = nil
  for i, position in ipairs(menu_item_positions) do
    if mouse_x > position.x and mouse_x < position.x + MENU_TEXT_SIZE and
       mouse_y > position.y and mouse_y < position.y + MENU_TEXT_SIZE then
      hovered_index = i
      break
    end
  end
end

function MenuState.update(dt)
  local mouse_x, mouse_y, aspect = Mouse.getNormalizedPosition()
  if mouse_x and mouse_y and aspect then
    MenuState.updateHover(mouse_x * aspect, mouse_y, aspect)
  end
end

local function drawDebugCircle(pass, x, y, viewport_height)
  local aspect = Utils.setupHUD(pass)
  local circle_size = (25 / viewport_height) * 2
  
  pass:setColor(1, 0, 0, 1)
  pass:circle(x * aspect, y, 0, circle_size, 0, 1, 0, 0, 'fill')
  pass:setColor(1, 1, 1, 1)
  
  pass:pop()
end

function MenuState.draw(pass)
  Utils.drawHUDBackground(pass, background_texture)
  
  local viewport_width, viewport_height = pass:getDimensions()
  local aspect = viewport_width / viewport_height
  
  for i, option in ipairs(menu_options) do
    local position = menu_item_positions[i]
    local is_hovered = (hovered_index == i)
    local show_shadow = not is_hovered
    local shadow_offset = show_shadow and MENU_SHADOW_OFFSET or nil
    local y_pos = position.y

    Utils.drawHUDText(pass, option, position.x, y_pos, MENU_TEXT_SIZE, 'left', 'top', menu_font, shadow_offset)
  end
  
  local mouse_x, mouse_y, _ = Mouse.getNormalizedPosition()
  if mouse_x and mouse_y then
    drawDebugCircle(pass, mouse_x, mouse_y, viewport_height)
  end
end

function MenuState.cleanup()
end

function MenuState.onKeyPressed(key, scancode, isrepeat, action)
end





return MenuState

