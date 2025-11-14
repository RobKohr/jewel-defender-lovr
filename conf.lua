-- Load app settings module to access values
local AppSettings = require("app_settings")

function lovr.conf(t)
  -- Window configuration - set to nil to disable automatic opening
  -- We'll open it manually in lovr.load to control fullscreen
  t.window = nil
  
  -- Graphics settings
  t.graphics.antialias = true
  
  -- Headset settings (disabled for desktop mode)
  t.headset.connect = false
  t.headset.start = false
end

