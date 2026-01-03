local AppSettings = require("app_settings")

function lovr.conf(t)
  -- Check for server mode via command-line argument
  -- arg[0] is the project path, arg[1] is the first argument
  local isServer = arg and arg[1] == "server"
  
  if isServer then
    -- Headless server mode: disable graphics and headset
    t.modules.graphics = false
    t.modules.headset = false
    t.window = nil
    -- Keep physics and other necessary modules
    t.modules.physics = true
    t.modules.system = true
    t.modules.timer = true
  else
    -- Client mode: normal configuration
    -- Set to nil to disable automatic opening - we'll open it manually in lovr.load to control fullscreen
    t.window = nil
    
    -- Graphics settings
    t.graphics.antialias = true  -- Enable antialiasing for better quality
    t.graphics.vsync = true  -- Enable vsync
    
    -- Headset settings (disabled for desktop mode)
    t.headset.connect = false
    t.headset.start = false
  end
end

