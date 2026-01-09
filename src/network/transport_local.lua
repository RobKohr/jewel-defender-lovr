-- Local Transport - Direct function calls for local games
-- No network overhead, just direct function calls

local TransportLocal = {}

local receiveCallbacks = {}  -- playerId -> callback function
local connectedClients = {}  -- playerId -> client info

-- Initialize local transport
function TransportLocal.init()
  print("TransportLocal: Initialized (direct function calls)")
  receiveCallbacks = {}
  connectedClients = {}
end

-- Send data to a specific player (direct function call)
function TransportLocal.send(playerId, data)
  if receiveCallbacks[playerId] then
    -- Direct function call - no network overhead
    receiveCallbacks[playerId](data)
    return true
  end
  return false
end

-- Broadcast data to all connected clients
function TransportLocal.broadcast(data, excludePlayerId)
  excludePlayerId = excludePlayerId or -1
  local sent = 0
  for playerId, callback in pairs(receiveCallbacks) do
    if playerId ~= excludePlayerId then
      callback(data)
      sent = sent + 1
    end
  end
  return sent
end

-- Register a callback for receiving data from a player
function TransportLocal.onReceive(playerId, callback)
  receiveCallbacks[playerId] = callback
  connectedClients[playerId] = {
    id = playerId,
    connected = true
  }
end

-- Simulate a client sending data (called by client code)
function TransportLocal.simulateReceive(playerId, data)
  -- This is called by the client to simulate sending data
  -- In a real network transport, this would come from the network
  -- For local transport, we just call the server's receive handler directly
  if TransportLocal.serverReceiveCallback then
    TransportLocal.serverReceiveCallback(playerId, data)
  end
end

-- Set the server's receive callback (called by server)
function TransportLocal.setServerReceiveCallback(callback)
  TransportLocal.serverReceiveCallback = callback
end

-- Disconnect a player
function TransportLocal.disconnect(playerId)
  receiveCallbacks[playerId] = nil
  connectedClients[playerId] = nil
end

-- Get list of connected clients
function TransportLocal.getConnectedClients()
  local clients = {}
  for playerId, _ in pairs(connectedClients) do
    table.insert(clients, playerId)
  end
  return clients
end

-- Check if a player is connected
function TransportLocal.isConnected(playerId)
  return connectedClients[playerId] ~= nil
end

-- Cleanup
function TransportLocal.cleanup()
  receiveCallbacks = {}
  connectedClients = {}
  TransportLocal.serverReceiveCallback = nil
end

return TransportLocal

