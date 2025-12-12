local Mouse = {}

-- Returns the mouse position in normalized coordinates (-1 to 1 range)
-- Normalized coordinates match the HUD coordinate system where:
--   x: -1 (left) to 1 (right), adjusted for aspect ratio
--   y: -1 (bottom) to 1 (top)
-- This allows mouse interaction to work consistently with HUD elements
-- regardless of window size or aspect ratio.
function Mouse.getMouseNormalizedPosition()
  local viewport_width, viewport_height = lovr.system.getWindowDimensions()
  if not viewport_width then return nil, nil end
  
  local mouse_x, mouse_y = lovr.system.getMousePosition()
  if not mouse_x then return nil, nil end
  
  local norm_x = ((mouse_x / viewport_width) * 2 - 1)
  local norm_y = -(1 - (mouse_y / viewport_height) * 2)
  local aspect = viewport_width / viewport_height
  
  return norm_x, norm_y, aspect
end

return Mouse

