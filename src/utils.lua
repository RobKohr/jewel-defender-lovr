local Utils = {}
local AppSettings = require("app_settings")

function Utils.turnOnFullscreen()
  lovr.system.openWindow({
    width = 0,
    height = 0,
    fullscreen = true,
    resizable = true,
    title = AppSettings.window.title,
  })
end

function Utils.turnOffFullscreen()
  lovr.system.openWindow({
    width = 1280,
    height = 720,
    fullscreen = false,
    resizable = true,
    title = AppSettings.window.title,
  })
end

return Utils