local Utils = {}
local AppSettings = require("app_settings")
local Mouse = require("src.mouse")

-- Cache frequently used functions and values
local getNormalizedPosition = Mouse.getNormalizedPosition
local windowTitle = AppSettings.window.title

function Utils.turnOnFullscreen()
  if not lovr.system.isWindowOpen() then
    lovr.system.openWindow({
      width = 0,
      height = 0,
      fullscreen = true,
      resizable = true,
      title = windowTitle,
    })
  end
end

function Utils.turnOffFullscreen()
  if not lovr.system.isWindowOpen() then
    lovr.system.openWindow({
      width = 1600,
      height = 1200,
      fullscreen = false,
      resizable = true,
      title = windowTitle,
    })
  end
end

-- Set up HUD coordinate system (orthographic projection, returns aspect ratio)
function Utils.setupHUD(pass)
  pass:push()
  pass:origin()
  pass:setViewPose(1, mat4())
  
  local viewport_width, viewport_height = pass:getDimensions()
  local aspect = viewport_width / viewport_height
  pass:setProjection(1, lovr.math.mat4():orthographic(-aspect, aspect, -1, 1, -1, 1))
  pass:setDepthTest()
  
  return aspect
end

function Utils.showFPS(pass)
  Utils.drawHUDText(pass, tostring(lovr.timer.getFPS()), -0.9, 0.9, 0.05, 'left', 'top')
end

function Utils.drawHUDBackground(pass, texture)
  if not texture then return end
  
  Utils.setupHUD(pass)
  pass:fill(texture)
  pass:pop()
end

-- x, y: normalized coords (-1 to 1), shadow_offset: y offset or nil
function Utils.drawHUDText(pass, text, x, y, size, halign, valign, font, shadow_offset)
  halign = halign or 'left'
  valign = valign or 'top'
  
  local aspect = Utils.setupHUD(pass)
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

local function drawDebugCircle(pass, x, y, viewport_height)
  local aspect = Utils.setupHUD(pass)
  local circle_size = (25 / viewport_height) * 2
  local mouse_x, mouse_y = getNormalizedPosition()

  pass:setColor(1, 0, 0, 1)
  pass:circle(mouse_x*aspect, mouse_y, 0, circle_size, 0, 1, 0, 0, 'fill')
  pass:setColor(1, 1, 1, 1)
  
  pass:pop()
end

function Utils.debugMousePosition(pass, font)
  local MENU_TEXT_SIZE = 0.136
  local viewport_width, viewport_height = pass:getDimensions()
  local aspect = viewport_width / viewport_height
  local mouse_x, mouse_y, _ = getNormalizedPosition()
  if mouse_x and mouse_y then
    drawDebugCircle(pass, mouse_x*aspect, mouse_y, viewport_height)  
    -- Display mouse coordinates at bottom of screen
    local coord_text = string.format("(%.2f, %.2f, %.2f)", mouse_x, mouse_y, aspect)
    Utils.drawHUDText(pass, coord_text, 0, 0, MENU_TEXT_SIZE, 'center', 'bottom', font, nil)
  end
end

return Utils