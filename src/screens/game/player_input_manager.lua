-- Player Input Manager - Handles input for multiple controllers
-- Controllers can be keyboard-based or gamepad-based, and join as the next available player

local PlayerInputManager = {}

-- Controller definitions
-- Each controller has a unique ID and key bindings
local CONTROLLERS = {
  {
    id = "keyboard_wasd",
    name = "WASD Keyboard",
    keys = {
      moveForward = "w",
      moveBackward = "s",
      turnLeft = "a",
      turnRight = "d"
    }
  },
  {
    id = "keyboard_arrows",
    name = "Arrow Keys Keyboard",
    keys = {
      moveForward = "up",
      moveBackward = "down",
      turnLeft = "left",
      turnRight = "right"
    }
  }
  -- Future: gamepad controllers can be added here
}

-- Track which controllers are active and which player they're assigned to
local controllerAssignments = {}  -- controllerId -> playerId
local playerToController = {}     -- playerId -> controllerId

-- Initialize the input manager
function PlayerInputManager.init()
  controllerAssignments = {}
  playerToController = {}
  print("PlayerInputManager: Initialized")
end

-- Check if a controller should join (pressed any of their keys)
-- Returns controllerId if they should join, nil otherwise
function PlayerInputManager.checkControllerJoin()
  for _, controller in ipairs(CONTROLLERS) do
    -- Skip if controller is already assigned
    if not controllerAssignments[controller.id] then
      -- Check if any of this controller's keys are pressed
      if lovr.system.isKeyDown(controller.keys.moveForward) or
         lovr.system.isKeyDown(controller.keys.moveBackward) or
         lovr.system.isKeyDown(controller.keys.turnLeft) or
         lovr.system.isKeyDown(controller.keys.turnRight) then
        return controller.id
      end
    end
  end
  
  return nil
end

-- Assign a controller to a player
-- @param controllerId (string) The controller ID
-- @param playerId (number) The player ID to assign to
function PlayerInputManager.assignController(controllerId, playerId)
  controllerAssignments[controllerId] = playerId
  playerToController[playerId] = controllerId
  print("PlayerInputManager: Assigned controller " .. controllerId .. " to player " .. tostring(playerId))
end

-- Get the controller assigned to a player
-- @param playerId (number) The player ID
-- @return (string|nil) The controller ID, or nil if not assigned
function PlayerInputManager.getControllerForPlayer(playerId)
  return playerToController[playerId]
end

-- Get input state for a specific player
-- @param playerId (number) The player ID
-- @return (table|nil) Input state table with boolean flags, or nil if no controller assigned
function PlayerInputManager.getPlayerInput(playerId)
  local controllerId = playerToController[playerId]
  if not controllerId then
    return nil
  end
  
  -- Find the controller
  local controller = nil
  for _, c in ipairs(CONTROLLERS) do
    if c.id == controllerId then
      controller = c
      break
    end
  end
  
  if not controller then
    return nil
  end
  
  -- Get input state from controller's keys
  return {
    moveForward = lovr.system.isKeyDown(controller.keys.moveForward),
    moveBackward = lovr.system.isKeyDown(controller.keys.moveBackward),
    turnLeft = lovr.system.isKeyDown(controller.keys.turnLeft),
    turnRight = lovr.system.isKeyDown(controller.keys.turnRight)
  }
end

-- Check if a player is active (has a controller assigned)
function PlayerInputManager.isPlayerActive(playerId)
  return playerToController[playerId] ~= nil
end

-- Get all active player IDs
function PlayerInputManager.getActivePlayers()
  local players = {}
  for playerId, _ in pairs(playerToController) do
    table.insert(players, playerId)
  end
  table.sort(players)  -- Return in order
  return players
end

-- Get the next available player ID (starting from 1)
-- @param maxPlayers (number) Maximum number of players (default 4)
-- @return (number|nil) Next available player ID, or nil if all slots full
function PlayerInputManager.getNextAvailablePlayerId(maxPlayers)
  maxPlayers = maxPlayers or 4
  for playerId = 1, maxPlayers do
    if not playerToController[playerId] then
      return playerId
    end
  end
  return nil  -- All slots full
end

-- Get controller info (for debugging/future use)
function PlayerInputManager.getControllerInfo(controllerId)
  for _, controller in ipairs(CONTROLLERS) do
    if controller.id == controllerId then
      return controller
    end
  end
  return nil
end

return PlayerInputManager
