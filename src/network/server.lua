-- Server - Coordinates game manager and transport layer
-- Works with both local and network transports

local Server = {}

local GameManager = require("src.game.game_manager")
local RoomManager = require("src.game.room_manager")
local Transport = nil  -- Will be set to local or network transport
local isLocal = true
local isRunning = false
local isInitialized = false

-- Initialize server with specified transport type
function Server.init(useLocalTransport)
  isLocal = useLocalTransport ~= false  -- Default to local
  
  if isLocal then
    Transport = require("src.network.transport_local")
    print("Server: Using local transport (direct function calls)")
  else
    -- TODO: Load network transport when implemented
    -- Transport = require("src.network.transport_network")
    print("Server: Network transport not yet implemented")
    return false
  end
  
  -- Initialize transport
  Transport.init()
  
  -- Set up receive callback
  Transport.setServerReceiveCallback(function(playerId, data)
    Server.handleClientMessage(playerId, data)
  end)
  
  -- Initialize managers
  RoomManager.init()
  GameManager.init()
  
  isRunning = true
  isInitialized = true
  Server.isInitialized = true  -- Expose for external checks
  print("Server: Initialized and running")
  return true
end

-- Handle incoming message from client
function Server.handleClientMessage(playerId, data)
  if not isRunning then
    return
  end
  
  local roomId = RoomManager.getPlayerRoom(playerId)
  
  -- TODO: Parse and validate message
  if data.type == "input" then
    if roomId then
      GameManager.applyInput(roomId, playerId, data.input)
    end
  elseif data.type == "create_room" then
    -- Create a new room
    local visibility = data.visibility or "public"
    local maxPlayers = data.maxPlayers or 4
    local room = RoomManager.createRoom(visibility, maxPlayers)
    if room then
      GameManager.initRoom(room.id)
      -- Auto-join creator to room
      RoomManager.addPlayerToRoom(room.id, playerId)
      -- Send confirmation
      if Transport and Transport.send then
        Transport.send(playerId, {
          type = "room_created",
          roomId = room.id,
          joinCode = room.joinCode
        })
      end
    end
  elseif data.type == "join_room" then
    -- Join a room by ID or join code
    local targetRoomId = data.roomId
    if data.joinCode then
      local room = RoomManager.getRoomByJoinCode(data.joinCode)
      if room then
        targetRoomId = room.id
      else
        -- Invalid join code
        if Transport and Transport.send then
          Transport.send(playerId, {
            type = "join_room_failed",
            reason = "Invalid join code"
          })
        end
        return
      end
    end
    
    if targetRoomId then
      local success, room = RoomManager.addPlayerToRoom(targetRoomId, playerId)
      if success then
        -- Initialize room if needed
        if not GameManager.getRoomState(targetRoomId) then
          GameManager.initRoom(targetRoomId)
        end
        -- Send confirmation
        if Transport and Transport.send then
          Transport.send(playerId, {
            type = "room_joined",
            roomId = room.id,
            state = GameManager.getRoomState(targetRoomId)
          })
        end
      else
        -- Failed to join
        if Transport and Transport.send then
          Transport.send(playerId, {
            type = "join_room_failed",
            reason = room or "Unknown error"
          })
        end
      end
    end
  elseif data.type == "leave_room" then
    if roomId then
      RoomManager.removePlayerFromRoom(roomId, playerId)
      if Transport and Transport.send then
        Transport.send(playerId, {
          type = "room_left",
          roomId = roomId
        })
      end
    end
  elseif data.type == "list_rooms" then
    -- Send list of public rooms
    local publicRooms = RoomManager.getPublicRooms()
    if Transport and Transport.send then
      Transport.send(playerId, {
        type = "room_list",
        rooms = publicRooms
      })
    end
  elseif data.type == "disconnect" then
    -- Handle client disconnect
    if roomId then
      RoomManager.removePlayerFromRoom(roomId, playerId)
    end
    if Transport and Transport.disconnect then
      Transport.disconnect(playerId)
    end
  end
end

-- Update server (called every frame)
function Server.update(dt)
  if not isRunning then
    return
  end
  
  -- Update room manager (cleanup empty rooms)
  RoomManager.update(dt)
  
  -- Step game simulation for all active rooms
  GameManager.step(dt)
  
  -- Send state updates to clients at configured rate (30-60 Hz)
  -- For now, we'll send every frame (will optimize later)
  if Transport and Transport.broadcast then
    -- Send room-scoped updates
    for roomId, room in pairs(RoomManager.getAllRooms()) do
      local state = GameManager.getRoomState(roomId)
      if state then
        -- Only send to players in this room
        for playerId, _ in pairs(room.players) do
          if Transport.send then
            Transport.send(playerId, {
              type = "state_update",
              roomId = roomId,
              state = state
            })
          end
        end
      end
    end
  end
end

-- Register a client (for local transport)
function Server.registerClient(playerId, receiveCallback)
  if Transport and Transport.onReceive then
    Transport.onReceive(playerId, receiveCallback)
    return true
  end
  return false
end

-- Send message to client (for local transport - client calls this)
function Server.sendToServer(playerId, data)
  if Transport and Transport.simulateReceive then
    Transport.simulateReceive(playerId, data)
    return true
  end
  return false
end

-- Create local room (for local games)
function Server.createLocalRoom()
  -- Delete existing local room if it exists
  local localRoom = RoomManager.getRoom("local")
  if localRoom then
    RoomManager.destroyRoom("local")
    GameManager.cleanupRoom("local")
  end
  
  -- Create fresh local room
  local room = RoomManager.createRoom("local", 4)
  if room then
    GameManager.initRoom(room.id)
    print("Server: Created local room")
    return room
  end
  return nil
end

-- Join local room (for local games)
function Server.joinLocalRoom(playerId)
  local success, room = RoomManager.addPlayerToRoom("local", playerId)
  if success then
    print("Server: Player " .. tostring(playerId) .. " joined local room")
    return room
  end
  return nil
end

-- Get current game state for a room (for clients to query)
function Server.getRoomState(roomId)
  return GameManager.getRoomState(roomId)
end

-- Cleanup
function Server.cleanup()
  if Transport and Transport.cleanup then
    Transport.cleanup()
  end
  isRunning = false
  isInitialized = false
  Server.isInitialized = false
  print("Server: Cleaned up")
end

return Server

