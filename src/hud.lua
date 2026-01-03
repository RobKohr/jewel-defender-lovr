local HUD = {}

-- Set up HUD coordinate system (orthographic projection, returns aspect ratio)
function HUD.setupHUD(pass)
  pass:push()
  pass:origin()
  pass:setViewPose(1, mat4())
  
  local viewport_width, viewport_height = pass:getDimensions()
  local aspect = viewport_width / viewport_height
  pass:setProjection(1, lovr.math.mat4():orthographic(-aspect, aspect, -1, 1, -1, 1))
  pass:setDepthTest()
  
  return aspect
end

function HUD.drawHUDBackground(pass, texture)
  if not texture then return end
  
  HUD.setupHUD(pass)
  pass:fill(texture)
  pass:pop()
end

-- x, y: normalized coords (-1 to 1), shadow_offset: y offset or nil
function HUD.drawHUDText(pass, text, x, y, size, halign, valign, font, shadow_offset)
  halign = halign or 'left'
  valign = valign or 'top'
  
  local aspect = HUD.setupHUD(pass)
  local x_aspect = x * aspect
  
  if font then
    pass:setFont(font)
  end
  
  if shadow_offset then
    pass:setColor(0.5, 0.5, 0.5, 1.0)
    pass:text(text, x_aspect, y + shadow_offset, 0, size, 0, 1, 0, 0, 0, halign, valign)
    pass:setColor(1, 1, 1, 1)
  end
  
  pass:text(text, x_aspect, y, 0, size, 0, 1, 0, 0, 0, halign, valign)
  
  if font then
    pass:setFont(nil)
  end
  
  pass:pop()
end

function HUD.showFPS(pass)
  HUD.drawHUDText(pass, tostring(lovr.timer.getFPS()), -0.9, 0.9, 0.05, 'left', 'top')
end

-- Returns the mouse position in normalized coordinates (-1 to 1 range)
-- Normalized coordinates match the HUD coordinate system where:
--   x: -1 (left) to 1 (right), adjusted for aspect ratio
--   y: -1 (bottom) to 1 (top)
-- This allows mouse interaction to work consistently with HUD elements
-- regardless of window size or aspect ratio.
function HUD.getMouseNormalizedPosition()
  local viewport_width, viewport_height = lovr.system.getWindowDimensions()
  if not viewport_width then return nil, nil end
  
  local mouse_x, mouse_y = lovr.system.getMousePosition()
  if not mouse_x then return nil, nil end
  
  local norm_x = ((mouse_x / viewport_width) * 2 - 1)
  local norm_y = -(1 - (mouse_y / viewport_height) * 2)
  local aspect = viewport_width / viewport_height
  
  return norm_x, norm_y, aspect
end

local function drawDebugCircle(pass, x, y, viewport_height)
  local aspect = HUD.setupHUD(pass)
  local circle_size = (25 / viewport_height) * 2
  local mouse_x, mouse_y = HUD.getMouseNormalizedPosition()

  pass:setColor(1, 0, 0, 1)
  pass:circle(mouse_x*aspect, mouse_y, 0, circle_size, 0, 1, 0, 0, 'fill')
  pass:setColor(1, 1, 1, 1)
  
  pass:pop()
end

function HUD.debugMousePosition(pass, font)
  local MENU_TEXT_SIZE = 0.136
  local viewport_width, viewport_height = pass:getDimensions()
  local aspect = viewport_width / viewport_height
  local mouse_x, mouse_y, _ = HUD.getMouseNormalizedPosition()
  if mouse_x and mouse_y then
    drawDebugCircle(pass, mouse_x*aspect, mouse_y, viewport_height)  
    -- Display mouse coordinates at bottom of screen
    local coord_text = string.format("(%.2f, %.2f, %.2f)", mouse_x, mouse_y, aspect)
    HUD.drawHUDText(pass, coord_text, 0, 0, MENU_TEXT_SIZE, 'center', 'bottom', font, nil)
  end
end

return HUD
