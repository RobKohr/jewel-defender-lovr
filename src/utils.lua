local Utils = {}
local AppSettings = require("app_settings")

-- Cache frequently used values
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

return Utils