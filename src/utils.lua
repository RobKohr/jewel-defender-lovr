local Utils = {}
local AppSettings = require("app_settings")

-- Note: lovr.system.openWindow() does nothing if the window is already open.
-- LÖVR doesn't support closing the window programmatically, so fullscreen toggling
-- after the window is created is not possible without losing game state.
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

function Utils.showFPS(pass)
  local fps = lovr.timer.getFPS()
  -- Use HUD text for fixed on-screen FPS display
  Utils.drawHUDText(pass, tostring(fps), -0.9, 0.9, 0.05, 'left', 'top')
end

-- Draw HUD text that stays fixed on screen (doesn't move with camera)
-- x, y: position in normalized screen coordinates (-1 to 1, where 0,0 is center)
-- text: the text to display
-- size: font size
-- halign: 'left', 'center', or 'right'
-- valign: 'top', 'middle', or 'bottom'
function Utils.drawHUDText(pass, text, x, y, size, halign, valign)
  halign = halign or 'left'
  valign = valign or 'top'
  
  -- Save current state
  pass:push()
  
  -- Reset to origin and use orthographic projection for screen space
  pass:origin()
  pass:setViewPose(1, mat4())  -- Identity view (no camera movement)
  
  -- Create orthographic projection for screen space
  -- Convert normalized coordinates (-1 to 1) to aspect-ratio coordinates
  local viewport_width, viewport_height = pass:getDimensions()
  local aspect = viewport_width / viewport_height
  local ortho_matrix = lovr.math.mat4():orthographic(-aspect, aspect, -1, 1, -1, 1)
  pass:setProjection(1, ortho_matrix)
  
  -- Convert normalized x coordinate to aspect-ratio coordinate
  -- x = -1 maps to -aspect (left edge), x = 1 maps to aspect (right edge)
  local x_aspect = x * aspect
  
  -- Disable depth testing for HUD (always on top)
  pass:setDepthTest()  -- Disable depth test
  
  -- Draw text at fixed position (y stays the same, -1 to 1)
  pass:text(text, x_aspect, y, 0, size, 0, 1, 0, 0, 0, halign, valign)
  
  -- Restore state (depth test will be restored by pop())
  pass:pop()
end

return Utils