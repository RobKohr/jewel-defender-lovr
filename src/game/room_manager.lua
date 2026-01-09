-- Room Manager - Handles room creation, joining, listing, and cleanup
-- Supports local, public, and private rooms

local RoomManager = {}

local rooms = {}  -- roomId -> room data
local clientRooms = {}  -- playerId -> roomId (which room is each client in)

-- Constants
local LOCAL_ROOM_ID = "local"
local MAX_PLAYERS = 4
local PUBLIC_ROOM_TIMEOUT = 60.0  -- Seconds before destroying empty public room
local PRIVATE_ROOM_TIMEOUT = 5.0  -- Seconds before destroying empty private room

-- Generate a 6-digit join code for private rooms
local function generateJoinCode()
  local code = ""
  for i = 1, 6 do
    code = code .. tostring(math.random(0, 9))
  end
  return code
end

-- Generate a unique room ID
local function generateRoomId()
  -- Simple UUID-like generation (can be improved)
  local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
  local id = ""
  for i = 1, 8 do
    local rand = math.random(1, #chars)
    id = id .. string.sub(chars, rand, rand)
  end
  return "room_" .. id
end

-- Initialize room manager
function RoomManager.init()
  rooms = {}
  clientRooms = {}
  print("RoomManager: Initialized")
end

-- Create a new room
function RoomManager.createRoom(visibility, maxPlayers)
  visibility = visibility or "public"
  maxPlayers = maxPlayers or MAX_PLAYERS
  
  local roomId
  local joinCode = nil
  
  if visibility == "local" then
    roomId = LOCAL_ROOM_ID
  else
    roomId = generateRoomId()
    if visibility == "private" then
      joinCode = generateJoinCode()
    end
  end
  
  -- Delete existing room if it exists (for local room, this ensures fresh start)
  if rooms[roomId] then
    RoomManager.destroyRoom(roomId)
  end
  
  local room = {
    id = roomId,
    joinCode = joinCode,
    visibility = visibility,
    maxPlayers = maxPlayers,
    players = {},
    gameState = nil,  -- Will be initialized by GameManager
    createdAt = lovr.timer.getTime(),
    lastActivity = lovr.timer.getTime()
  }
  
  rooms[roomId] = room
  print("RoomManager: Created room " .. roomId .. " (visibility: " .. visibility .. ", joinCode: " .. (joinCode or "none") .. ")")
  
  return room
end

-- Get room by ID
function RoomManager.getRoom(roomId)
  return rooms[roomId]
end

-- Get room by join code
function RoomManager.getRoomByJoinCode(joinCode)
  for roomId, room in pairs(rooms) do
    if room.joinCode == joinCode then
      return room
    end
  end
  return nil
end

-- Get list of public rooms (for room browser)
function RoomManager.getPublicRooms()
  local publicRooms = {}
  for roomId, room in pairs(rooms) do
    if room.visibility == "public" and roomId ~= LOCAL_ROOM_ID then
      local playerCount = 0
      for _ in pairs(room.players) do
        playerCount = playerCount + 1
      end
      table.insert(publicRooms, {
        id = room.id,
        playerCount = playerCount,
        maxPlayers = room.maxPlayers,
        createdAt = room.createdAt
      })
    end
  end
  return publicRooms
end

-- Add player to a room
function RoomManager.addPlayerToRoom(roomId, playerId)
  local room = rooms[roomId]
  if not room then
    return false, "Room not found"
  end
  
  -- Check if room is full
  local playerCount = 0
  for _ in pairs(room.players) do
    playerCount = playerCount + 1
  end
  
  if playerCount >= room.maxPlayers then
    return false, "Room is full"
  end
  
  -- Remove player from previous room if any
  local previousRoomId = clientRooms[playerId]
  if previousRoomId and previousRoomId ~= roomId then
    RoomManager.removePlayerFromRoom(previousRoomId, playerId)
  end
  
  -- Add player to room
  room.players[playerId] = true
  clientRooms[playerId] = roomId
  room.lastActivity = lovr.timer.getTime()
  
  print("RoomManager: Player " .. tostring(playerId) .. " joined room " .. roomId)
  return true, room
end

-- Remove player from a room
function RoomManager.removePlayerFromRoom(roomId, playerId)
  local room = rooms[roomId]
  if not room then
    return false
  end
  
  room.players[playerId] = nil
  if clientRooms[playerId] == roomId then
    clientRooms[playerId] = nil
  end
  
  room.lastActivity = lovr.timer.getTime()
  
  print("RoomManager: Player " .. tostring(playerId) .. " left room " .. roomId)
  
  -- Check if room should be destroyed (empty and timeout expired)
  local playerCount = 0
  for _ in pairs(room.players) do
    playerCount = playerCount + 1
  end
  
  if playerCount == 0 then
    local timeout = room.visibility == "private" and PRIVATE_ROOM_TIMEOUT or PUBLIC_ROOM_TIMEOUT
    if room.id == LOCAL_ROOM_ID then
      -- Local room: destroy immediately when empty
      RoomManager.destroyRoom(roomId)
    elseif lovr.timer.getTime() - room.lastActivity > timeout then
      RoomManager.destroyRoom(roomId)
    end
  end
  
  return true
end

-- Get room ID for a player
function RoomManager.getPlayerRoom(playerId)
  return clientRooms[playerId]
end

-- Destroy a room
function RoomManager.destroyRoom(roomId)
  local room = rooms[roomId]
  if not room then
    return false
  end
  
  -- Remove all players from room
  for playerId, _ in pairs(room.players) do
    clientRooms[playerId] = nil
  end
  
  rooms[roomId] = nil
  print("RoomManager: Destroyed room " .. roomId)
  return true
end

-- Update room manager (cleanup empty rooms)
function RoomManager.update(dt)
  local currentTime = lovr.timer.getTime()
  
  for roomId, room in pairs(rooms) do
    -- Skip local room (handled separately)
    if roomId ~= LOCAL_ROOM_ID then
      local playerCount = 0
      for _ in pairs(room.players) do
        playerCount = playerCount + 1
      end
      
      -- Destroy empty rooms after timeout
      if playerCount == 0 then
        local timeout = room.visibility == "private" and PRIVATE_ROOM_TIMEOUT or PUBLIC_ROOM_TIMEOUT
        if currentTime - room.lastActivity > timeout then
          RoomManager.destroyRoom(roomId)
        end
      end
    end
  end
end

-- Get all rooms (for debugging)
function RoomManager.getAllRooms()
  return rooms
end

return RoomManager

