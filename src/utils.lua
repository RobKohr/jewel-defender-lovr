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

-- Draw HUD background image that stays fixed on screen (doesn't move with camera)
-- texture: Texture object to draw as background
function Utils.drawHUDBackground(pass, texture)
  if not texture then return end
  
  -- Save current state
  pass:push()
  
  -- Reset to origin and use orthographic projection for screen space
  pass:origin()
  pass:setViewPose(1, mat4())  -- Identity view (no camera movement)
  
  -- Create orthographic projection for screen space
  local viewport_width, viewport_height = pass:getDimensions()
  local aspect = viewport_width / viewport_height
  local ortho_matrix = lovr.math.mat4():orthographic(-aspect, aspect, -1, 1, -1, 1)
  pass:setProjection(1, ortho_matrix)
  
  -- Disable depth testing for HUD (always on top)
  pass:setDepthTest()  -- Disable depth test
  
  -- Draw background texture filling the entire screen
  pass:fill(texture)
  
  -- Restore state
  pass:pop()
end

-- Draw HUD text that stays fixed on screen (doesn't move with camera)
-- x, y: position in normalized screen coordinates (-1 to 1, where 0,0 is center)
-- text: the text to display
-- size: font size
-- halign: 'left', 'center', or 'right'
-- valign: 'top', 'middle', or 'bottom'
-- font: optional Font object to use (nil for default font)
-- shadowed: optional boolean to enable text shadow (default false)
function Utils.drawHUDText(pass, text, x, y, size, halign, valign, font, shadowed)
  halign = halign or 'left'
  valign = valign or 'top'
  shadowed = shadowed or false
  
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
  
  -- Set font if provided
  if font then
    pass:setFont(font)
  end
  
  -- Disable depth testing for HUD (always on top)
  pass:setDepthTest()  -- Disable depth test
  
  -- Draw shadow if enabled (draw first, behind the text)
  if shadowed then
    local shadow_offset = size * 0.1  -- 10% of text height, moving down
    local shadow_y = y + shadow_offset
    pass:setColor(0.5, 0.5, 0.5, 1.0)  -- Solid gray
    pass:text(text, x_aspect, shadow_y, 0, size, 0, 1, 0, 0, 0, halign, valign)
    pass:setColor(1, 1, 1, 1)  -- Reset to white
  end
  
  -- Draw text at fixed position (y stays the same, -1 to 1)
  pass:text(text, x_aspect, y, 0, size, 0, 1, 0, 0, 0, halign, valign)
  
  -- Restore font to default
  if font then
    pass:setFont(nil)
  end
  
  -- Restore state (depth test will be restored by pop())
  pass:pop()
end

return Utils