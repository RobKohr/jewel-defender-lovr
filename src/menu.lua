local Menu = {}
local Utils = require("src.utils")
local Mouse = require("src.mouse")

-- Cache frequently used functions
local getNormalizedPosition = Mouse.getNormalizedPosition
local drawHUDText = Utils.drawHUDText
local debugMousePosition = Utils.debugMousePosition

-- HUD text sizing (normalized units)
local MENU_TEXT_SIZE = 0.136
local MENU_ITEM_SPACING = 0.15
local MENU_SHADOW_OFFSET = 0.0136

-- Default menu starting Y position (normalized units)
local DEFAULT_MENU_START_Y = -0.232

-- Factory function to create a new menu instance
function Menu.create()
  local menu = {
    menu_font = nil,
    menu_items = {},
    hovered_index = nil,
    menu_start_x = nil,
    menu_start_y = DEFAULT_MENU_START_Y,
    show_debug_pointer = false,
    show_debug_mouse_position = false,
  }
  
  -- Initialize font
  menu.menu_font = lovr.graphics.newFont('assets/fonts/Montserrat-ExtraBoldItalic.ttf', 80, 4)
  
  -- Set menu items
  function menu:setMenuItems(menu_start_x, items)
    self.menu_start_x = menu_start_x
    self.menu_items = {}
    
    for i, item in ipairs(items) do
      local y_pos = self.menu_start_y + (i - 1) * MENU_ITEM_SPACING
      table.insert(self.menu_items, {
        x = menu_start_x,
        y = y_pos,
        label = item.label,
        callback = item.callback,
      })
    end
  end
  
  -- Update hover state based on mouse position
  function menu:update()
    local mouse_x, mouse_y = getNormalizedPosition()
    if not mouse_x or not mouse_y then
      self.hovered_index = nil
      return
    end
    
    local x = mouse_x
    self.hovered_index = nil
    
    for i, position in ipairs(self.menu_items) do
      -- width is MENU_TEXT_SIZE * number of characters in the label
      local labelWidth = 0.45
      if mouse_y > position.y and mouse_y < position.y + MENU_TEXT_SIZE and 
         x > -0.86 and x < position.x + labelWidth then
        self.hovered_index = i
        break
      end
    end
    
    -- Handle mouse clicks
    if lovr.system.wasMousePressed(1) and self.hovered_index then
      local menu_item = self.menu_items[self.hovered_index]
      if menu_item and menu_item.callback then
        menu_item.callback()
      end
    end
  end
  
  -- Draw the menu
  function menu:draw(pass)
    for i, position in ipairs(self.menu_items) do
      local is_hovered = (self.hovered_index == i)
      local show_shadow = not is_hovered
      local shadow_offset = show_shadow and MENU_SHADOW_OFFSET or nil
      local y_pos = position.y
      drawHUDText(pass, position.label, position.x, y_pos, MENU_TEXT_SIZE, 'left', 'top', self.menu_font, shadow_offset)
    end
    
    if self.show_debug_mouse_position then
      debugMousePosition(pass, self.menu_font)
    end
    
    if self.show_debug_pointer then
      local mouse_x, mouse_y = getNormalizedPosition()
      if mouse_x and mouse_y then
        local viewport_width, viewport_height = pass:getDimensions()
        local aspect = viewport_width / viewport_height
        local circle_size = (25 / viewport_height) * 2
        
        Utils.setupHUD(pass)
        pass:setColor(1, 0, 0, 1)
        pass:circle(mouse_x * aspect, mouse_y, 0, circle_size, 0, 1, 0, 0, 'fill')
        pass:setColor(1, 1, 1, 1)
        pass:pop()
      end
    end
  end
  
  -- Set debug pointer visibility
  function menu:setShowDebugPointer(show)
    self.show_debug_pointer = show
  end
  
  -- Set debug mouse position visibility
  function menu:setShowDebugMousePosition(show)
    self.show_debug_mouse_position = show
  end
  
  return menu
end

return Menu

