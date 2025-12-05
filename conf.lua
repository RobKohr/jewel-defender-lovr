local AppSettings = require("app_settings")

function lovr.conf(t)
  -- Set to nil to disable automatic opening - we'll open it manually in lovr.load to control fullscreen
  t.window = nil
  
  -- Graphics settings
  t.graphics.antialias = true  -- Enable antialiasing for better quality
  t.graphics.vsync = true  -- Enable vsync
  
  -- Headset settings (disabled for desktop mode)
  t.headset.connect = false
  t.headset.start = false
end

