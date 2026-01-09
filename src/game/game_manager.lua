-- Game Manager - Authoritative game logic and physics
-- This is the single source of truth for game state
-- Works the same whether running locally or networked

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

-- Clean up game state for a room
function GameManager.cleanupRoom(roomId)
  roomStates[roomId] = nil
  roomAccumulators[roomId] = nil
  print("GameManager: Cleaned up room " .. roomId)
end

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
    -- TODO: Run physics simulation for this room
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
  
  -- TODO: Validate and apply player input
  -- TODO: Update player state based on input
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

