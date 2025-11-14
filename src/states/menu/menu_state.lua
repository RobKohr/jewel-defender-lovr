local MenuState = {}

function MenuState.init()
  -- Initialize menu state
end

function MenuState.update(dt)
  -- Update menu state
end

function MenuState.draw(pass)
   -- Get the current time for rotation
   local time = lovr.timer.getTime()
  
   -- Draw a spinning cube
   -- Parameters: x, y, z, size, rotation angle, rotation axis x, y, z
   pass:cube(0, 1.7, -1, .5, time, 1, 1, 0)
   
  -- Draw menu state
  pass:text("Networked Game", 0, 1.5, -1, .1)
  pass:text("Press ENTER to start", 0, 1.3, -1, .05)
end

function MenuState.cleanup()
  -- Cleanup menu state
end

function MenuState.onKeyPressed(key, scancode, isrepeat, action)
  -- handle the action
end



return MenuState

