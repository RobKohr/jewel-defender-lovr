-- Game Manager - Authoritative game logic and physics
-- This is the single source of truth for game state
-- Works the same whether running locally or networked
local rad = math.rad

local GameManager = {}

-- Per-room game state
local roomStates = {}  -- roomId -> { tick, players, entities }

-- Fixed timestep for deterministic physics
local FIXED_DT = 1.0 / 60.0  -- 60 Hz physics
-- Accumulated time per room for fixed timestep simulation (preserves fractional time between frames)
local roomAccumulators = {}  -- roomId -> accumulator

-- Initialize the game manager
function GameManager.init()
  print("GameManager: Initialized")
  roomStates = {}
  roomAccumulators = {}
end

-- Initialize game state for a room
function GameManager.initRoom(roomId)
  roomStates[roomId] = {
    tick = 0,
    players = {},
    entities = {}
  }
  roomAccumulators[roomId] = 0.0
  print("GameManager: Initialized room " .. roomId)
end

-- Initialize a player in a room (called when player joins)
function GameManager.initPlayer(roomId, playerId)
  local state = roomStates[roomId]
  if not state then
    return false
  end
  
  -- Initialize player with default position and rotation
  state.players[playerId] = {
    id = playerId,
    x = 0.0,
    y = 0.0,  -- Will be set to PLATE_HEIGHT + 1 when rendering
    z = 0.0,
    rotation = rad(-90),  -- Rotation around Y axis in radians
    input = {
      moveForward = false,
      moveBackward = false,
      turnLeft = false,
      turnRight = false
    }
  }
  print("GameManager: Initialized player " .. tostring(playerId) .. " in room " .. roomId)
  return true
end

-- Clean up game state for a room
function GameManager.cleanupRoom(roomId)
  roomStates[roomId] = nil
  roomAccumulators[roomId] = nil
  print("GameManager: Cleaned up room " .. roomId)
end

-- Movement constants
local MOVE_SPEED = 5.0  -- units per second
local TURN_SPEED = 2.0  -- radians per second

-- Step the game simulation for a specific room with fixed timestep
function GameManager.stepRoom(roomId, dt)
  local state = roomStates[roomId]
  if not state then
    return
  end
  
  local accumulator = roomAccumulators[roomId] or 0.0
  accumulator = accumulator + dt
  
  -- Run physics in fixed timestep increments
  while accumulator >= FIXED_DT do
    state.tick = state.tick + 1
    
    -- Update player positions based on input
    for playerId, player in pairs(state.players) do
      local input = player.input
      
      -- Handle rotation
      -- Note: LOVR uses right-hand rule convention:
      --   Positive rotation = counter-clockwise (left turn) when viewed from above
      --   Negative rotation = clockwise (right turn) when viewed from above
      if input.turnLeft then
        player.rotation = player.rotation + TURN_SPEED * FIXED_DT
      end
      if input.turnRight then
        player.rotation = player.rotation - TURN_SPEED * FIXED_DT
      end
      
      -- Handle movement (forward/backward in direction of rotation)
      -- Note: Negate rotation to convert orientation angle to movement direction vector.
      -- The rotation value represents turn amount (positive = left, negative = right),
      -- but the standard sin/cos formula for forward direction needs the sign inverted.
      local moveX = 0.0
      local moveZ = 0.0
      local rot = -player.rotation  -- Negate rotation for movement calculation
      
      if input.moveForward then
        moveX = moveX + math.sin(rot) * MOVE_SPEED * FIXED_DT
        moveZ = moveZ - math.cos(rot) * MOVE_SPEED * FIXED_DT
      end
      if input.moveBackward then
        moveX = moveX - math.sin(rot) * MOVE_SPEED * FIXED_DT
        moveZ = moveZ + math.cos(rot) * MOVE_SPEED * FIXED_DT
      end
      
      player.x = player.x + moveX
      player.z = player.z + moveZ
    end
    
    -- TODO: Update game entities in this room
    -- TODO: Process game logic for this room
    accumulator = accumulator - FIXED_DT
  end
  
  roomAccumulators[roomId] = accumulator
end

-- Step all active rooms
function GameManager.step(dt)
  for roomId, _ in pairs(roomStates) do
    GameManager.stepRoom(roomId, dt)
  end
end

-- Apply player input to a specific room
-- @param roomId (string) The room ID to apply input to
-- @param playerId (number) The player ID applying the input
-- @param input (table) Input state table with boolean flags for actions (e.g., {moveForward=true, turnLeft=false, shoot=false})
function GameManager.applyInput(roomId, playerId, input)
  local state = roomStates[roomId]
  if not state then
    return false
  end
  
  -- Initialize player if they don't exist
  if not state.players[playerId] then
    GameManager.initPlayer(roomId, playerId)
  end
  
  local player = state.players[playerId]
  if not player then
    return false
  end
  
  -- Update player input state
  player.input.moveForward = input.moveForward or false
  player.input.moveBackward = input.moveBackward or false
  player.input.turnLeft = input.turnLeft or false
  player.input.turnRight = input.turnRight or false
  
  return true
end

-- Get game state for a specific room
function GameManager.getRoomState(roomId)
  local state = roomStates[roomId]
  if not state then
    return nil
  end
  
  return {
    tick = state.tick,
    players = state.players,
    entities = state.entities
  }
end

return GameManager

