local Utils = {}
local AppSettings = require("app_settings")

function Utils.turnOnFullscreen()
  if not lovr.system.isWindowOpen() then
    lovr.system.openWindow({
      width = 0,
      height = 0,
      fullscreen = true,
      resizable = true,
      title = AppSettings.window.title,
    })
  end
end

function Utils.turnOffFullscreen()
  if not lovr.system.isWindowOpen() then
    lovr.system.openWindow({
      width = 1280,
      height = 720,
      fullscreen = false,
      resizable = true,
      title = AppSettings.window.title,
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

return Utils