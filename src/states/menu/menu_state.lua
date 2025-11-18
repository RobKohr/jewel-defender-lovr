local MenuState = {}
local Utils = require("src.utils")

local background_texture = nil
local background_image = nil
local menu_font = nil

-- Original image coordinates (pixels)
local ORIGINAL_MENU_X = 205
local ORIGINAL_MENU_Y = 826
local ORIGINAL_FONT_SIZE = 80  -- 80 point font
local SHADOW_OFFSET_PX = 5  -- 5 pixel drop shadow

-- Menu options
local menu_options = {
  "New Game",
  "Options",
  "Extras",
  "Quit"
}

-- Scaling function: converts pixels to LÖVR coordinate units
local function scalePixel(value, scale_factor)
  return value * scale_factor
end

-- Get vertical scale factor based on viewport and image dimensions
local function getVerticalScale(viewport_height, image_height)
  -- LÖVR's default viewport spans approximately -1 to 1 in Y (2 units)
  -- We need to map image pixels to this coordinate system
  return 2.0 / image_height
end

-- Get horizontal scale factor
local function getHorizontalScale(viewport_width, viewport_height, image_width)
  -- LÖVR's default viewport spans approximately -aspect to aspect in X
  local aspect = viewport_width / viewport_height
  return (2.0 * aspect) / image_width
end

function MenuState.init()
  -- Load background image to get dimensions
  -- background_image = lovr.data.newImage('assets/images/main_menu_background.jpg')
  -- background_texture = lovr.graphics.newTexture(background_image, {})
  
  -- Use default font for testing (font loading commented out)
  -- menu_font = lovr.graphics.newFont('assets/fonts/Montserrat-ExtraBoldItalic.ttf', 80, 4)
  menu_font = nil  -- Use default font
end

function MenuState.update(dt)
end

function MenuState.draw(pass)
  -- Draw HUD text (fixed on screen)
  Utils.drawHUDText(pass, "Networked Game", -1, -1, 0.05, 'left', 'top')
  Utils.drawHUDText(pass, "Press ENTER to start", 0, 0.5, 0.05, 'center', 'top')
end

function MenuState.drawBackup(pass)
  -- Draw background
  pass:fill(background_texture)
  
  if not background_image then return end
  
  -- Get dimensions
  local viewport_width, viewport_height = pass:getDimensions()
  local image_width, image_height = background_image:getDimensions()
  
  -- Calculate scale factors
  local vertical_scale = getVerticalScale(viewport_height, image_height)
  local horizontal_scale = getHorizontalScale(viewport_width, viewport_height, image_width)
  
  -- Calculate scaled font size (80pt scaled to match vertical scale)
  local scaled_font_size = scalePixel(ORIGINAL_FONT_SIZE, vertical_scale)
  
  -- Calculate menu start position in LÖVR coordinates
  -- Convert from image coordinates (top-left origin) to LÖVR coordinates (center origin, Y up)
  -- Image: (0,0) is top-left, (width, height) is bottom-right
  -- LÖVR: center is (0, 0, -2), Y up, X right
  local menu_x_px = ORIGINAL_MENU_X - (image_width / 2)  -- Convert to center-relative
  local menu_y_px = (image_height / 2) - ORIGINAL_MENU_Y  -- Flip Y and convert to center-relative
  
  local menu_x = scalePixel(menu_x_px, horizontal_scale)
  local menu_y = scalePixel(menu_y_px, vertical_scale)
  local menu_z = -2  -- Same Z as working text
  
  -- Calculate shadow offset
  local shadow_offset_y = scalePixel(SHADOW_OFFSET_PX, vertical_scale)
  
  -- Set font (use default if menu_font is nil)
  if menu_font then
    pass:setFont(menu_font)
  end
  
  -- Draw menu options
  local line_height = scaled_font_size * 1.2  -- Spacing between lines
  for i, option in ipairs(menu_options) do
    local y_offset = (i - 1) * line_height
    local text_y = menu_y - y_offset
    
    -- Draw drop shadow (gray, offset down)
    pass:setColor(0.5, 0.5, 0.5)  -- Solid gray
    pass:text(option, menu_x, text_y - shadow_offset_y, menu_z, scaled_font_size, 0, 1, 0, 0, 0, 'left', 'top')
    
    -- Draw main text (white)
    pass:setColor(1, 1, 1)  -- White
    pass:text(option, menu_x, text_y, menu_z, scaled_font_size, 0, 1, 0, 0, 0, 'left', 'top')
  end
  
  -- Reset font to default
  pass:setFont(nil)
end

function MenuState.cleanup()
end

function MenuState.onKeyPressed(key, scancode, isrepeat, action)
end



return MenuState

