# Network Plan - Jewel Defender LOVR

## Overview

This document outlines the networking architecture for implementing multiplayer functionality with an authoritative server model. The server will run in headless mode using LOVR's capabilities, handling physics and game state deterministically.

**Current Priority**: Local game functionality is the primary focus. Network gameplay (online multiplayer) is planned for Version 2.

**Key Design Principle**: The **Server module** (`src/network/server.lua`) is the unified interface for both local and networked games. Game screens (like `GameScreen`) interact directly with the Server module, which abstracts the transport layer (local or network). This ensures consistent behavior and easy transition between local and networked gameplay.

## Format Choice: MessagePack

### Why MessagePack?

MessagePack is a binary serialization format that provides an optimal balance between performance, size, and ease of use for game networking.

**Advantages:**
- **Compact**: ~30-50% smaller than JSON
- **Fast**: Binary encoding/decoding is significantly faster than text parsing
- **Type-preserving**: Maintains number types (int vs float) and data structures
- **Flexible**: Works seamlessly with nested Lua tables/arrays
- **Debuggable**: Can be converted to JSON for inspection when needed

### Size Comparison

For a typical game state update:

| Format | Size | Notes |
|--------|------|-------|
| **JSON** | ~120 bytes | Human-readable, verbose |
| **MessagePack** | ~70 bytes | Binary, compact (~40% smaller) |
| **Custom Binary** | ~40 bytes | Most efficient, but complex to implement |

### Usage Example

```lua
local cmsgpack = require 'cmsgpack'

-- Game state structure
local state = {
  tick = 123,
  players = {
    {id = 1, x = 10.5, y = 20.3, z = 5.0, health = 100},
    {id = 2, x = 15.2, y = 18.1, z = 5.0, health = 75}
  },
  entities = {
    {id = 10, type = "enemy", x = 20.0, y = 0, z = 30.0}
  }
}

-- Pack to binary string for network transmission
local packed = cmsgpack.pack(state)

-- Unpack on receiving end
local unpacked = cmsgpack.unpack(packed)
```

### MessagePack Format Details

MessagePack uses type tags in the first byte to indicate data types:
- `0x80-0x8F`: Small maps (up to 15 key-value pairs)
- `0x90-0x9F`: Small arrays (up to 15 items)
- `0xA0-0xBF`: Small strings (up to 31 bytes)
- `0xCB`: float64 (8 bytes)
- `0xCD`: uint16 (2 bytes)
- And more...

The format is binary and not human-readable, but provides efficient network transfer while maintaining the ability to debug by unpacking back to Lua tables.

## Update Rates

### Recommended Frequencies

For a defender-style game, we recommend **30-60 Hz** update rates:

- **30 Hz (33.33ms intervals)**: Good default
  - Balanced smoothness and efficiency
  - ~50-100 KB/s for 10 players
  - Suitable for most gameplay scenarios

- **60 Hz (16.67ms intervals)**: For high responsiveness
  - Smoother gameplay, lower latency
  - ~100-200 KB/s for 10 players
  - Best for fast-paced competitive play

### Fixed Timestep Architecture

The server will run with a **fixed timestep** to ensure determinism:

- **Physics tick rate**: 60 Hz (16.67ms per tick)
- **State update rate**: 30-60 Hz (configurable)
- **Time accumulator**: Accumulate variable `dt` and step in fixed increments

```lua
local FIXED_DT = 1.0 / 60.0  -- 60 Hz physics
local accumulator = 0.0

function update(dt)
  accumulator = accumulator + dt
  while accumulator >= FIXED_DT do
    Sim_StepFixed(world, FIXED_DT)  -- Deterministic physics step
    accumulator = accumulator - FIXED_DT
  end
end
```

### Bandwidth Considerations

- **30 Hz with 10 players**: ~50-100 KB/s
- **60 Hz with 10 players**: ~100-200 KB/s
- **Delta compression**: Can reduce bandwidth by 50-80% by only sending changes
- **Quantization**: Reduce precision (e.g., positions as int16) to save bandwidth

## Architecture

### Unified Authoritative Server Design

**Key Design Principle**: Local and networked games use the **same authoritative server code**. The only difference is the transport layer (direct function calls vs network).

This architecture provides:
- **Single source of truth**: Game logic lives in one place (`GameManager`)
- **Consistent behavior**: Local and networked games behave identically
- **Easier testing**: Test game logic without networking overhead
- **Flexible deployment**: Switch between local and networked without code changes

**Architecture Layers:**

```
┌─────────────────────────────────────┐
│     GameManager (Authoritative)     │
│  - Physics simulation (fixed timestep)│
│  - Game state management             │
│  - Input processing                  │
│  - Deterministic logic               │
└──────────────┬───────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌──────▼──────┐
│   Network   │  │   Local      │
│  Transport  │  │  Transport   │
│  (ENet)     │  │ (Direct Call)│
└─────────────┘  └──────────────┘
       │                │
       └───────┬────────┘
               │
       ┌───────▼────────┐
       │     Server      │
       │  (Coordinator)  │
       └─────────────────┘
```

**Component Responsibilities:**

- **GameManager** (`src/game/game_manager.lua`):
  - Single source of truth for all game state
  - Runs physics simulation with fixed timestep (60 Hz)
  - Processes player inputs deterministically
  - Provides `step(dt)`, `applyInput()`, `getState()` API
  - Transport-agnostic (doesn't know about network vs local)

- **Transport Layer** (Abstract interface):
  - **Local Transport** (`src/network/transport_local.lua`): Direct function calls, zero latency
  - **Network Transport** (`src/network/transport_network.lua`): ENet UDP networking (to be implemented)
  - Both implement: `send()`, `broadcast()`, `onReceive()`, `disconnect()`

- **Server** (`src/network/server.lua`):
  - **Unified interface** for both local and networked games
  - Coordinates GameManager and Transport
  - Handles client connections/disconnections
  - Routes messages between transport and game manager
  - Broadcasts state updates to clients
  - Works identically whether using local or network transport
  - Provides API: `registerClient()`, `sendToServer()`, `createLocalRoom()`, `joinLocalRoom()`, etc.

**Server responsibilities**:
  - Run physics simulation deterministically (via GameManager)
  - Process player inputs (via GameManager)
  - Validate game state
  - Broadcast state updates to clients (via Transport)

**Client responsibilities** (GameScreen and other screens):
  - Register as client with Server using `Server.registerClient(playerId, receiveCallback)`
  - Send input to server via `Server.sendToServer(playerId, {type="input", input={...}})`
  - Receive and apply state updates via registered callback
  - Render game state (with client-side prediction/interpolation)
  - Handle local UI/effects
  - **No separate Client module needed** - screens interact directly with Server

### Transport Layer Implementation

**Local Transport** (for single-player/local multiplayer):
- Direct function calls - zero network overhead
- Instant communication - no latency
- Used automatically when running in client mode
- Client and server run in same process

**Network Transport** (for online multiplayer - Version 2):
- Uses ENet for UDP networking
- LOVR includes the `enet` plugin for UDP networking
- Handles connection management, packet delivery, etc.
- **Note**: Network transport is planned for Version 2. Local transport is the current priority.

**Network Transport Implementation** (to be implemented in Version 2):
```lua
-- src/network/transport_network.lua
local enet = require 'enet'

local TransportNetwork = {}
local host = nil
local PORT = 6789

function TransportNetwork.init()
  host = enet.host_create('0.0.0.0:' .. PORT)
  -- ... setup ...
end

function TransportNetwork.update()
  local event = host:service(100)  -- 100ms timeout
  if event then
    if event.type == 'connect' then
      -- Handle new client
    elseif event.type == 'receive' then
      -- Handle incoming message
      local data = cmsgpack.unpack(event.data)
      -- Route to server handler
    elseif event.type == 'disconnect' then
      -- Handle client disconnect
    end
  end
end
```

**Client Network Setup** (to be implemented in Version 2):
```lua
local enet = require 'enet'

function lovr.load()
  local host = enet.host_create()
  local server = host:connect('server-ip:6789')
  
  -- Send input to server
  local input = {tick = currentTick, keys = {...}}
  server:send(cmsgpack.pack(input))
  
  -- Receive state updates
  local event = host:service(100)
  if event and event.type == 'receive' then
    local state = cmsgpack.unpack(event.data)
    applyGameState(state)
  end
end
```

### Multi-Room Architecture

The server supports multiple concurrent game rooms. Each room operates independently and can support 1-4 players.

**Room Structure:**
```lua
{
  id = "local" or "room_abc123" or UUID,  -- Unique identifier
  joinCode = nil or "123456",              -- 6-digit code for private rooms
  visibility = "public" or "private",      -- Room visibility
  maxPlayers = 4,                          -- Maximum players (1-4)
  players = {playerId1, playerId2, ...},   -- Current players (up to 4)
  gameState = {...},                       -- Room-specific game state
  createdAt = timestamp,                   -- Creation timestamp
  lastActivity = timestamp                 -- Last activity timestamp
}
```

**Room Types:**

1. **Local Room** (`id = "local"`):
   - Used for single-player and local multiplayer games
   - Created automatically when starting a local game
   - Never appears in public room list
   - No join code needed
   - Destroyed when game ends
   - Uses local transport (direct function calls)

2. **Public Rooms**:
   - Visible in public room list
   - Anyone can join (up to maxPlayers)
   - No join code required
   - Destroyed when empty for 60 seconds

3. **Private Rooms**:
   - Not visible in public room list
   - Require 6-digit join code to join
   - Destroyed when empty immediately (or after short delay)

**Room Management:**
- Each room has a unique room ID
- Rooms maintain their own game state and player list
- Players can join/leave rooms dynamically
- Rooms can be created/destroyed as needed
- Room manager handles creation, listing, joining, and cleanup

**Room-Scoped Updates:**
- **State updates are only sent to clients within the same room**
- When a room's game manager produces a state update, it is only broadcast to clients who are members of that room
- Clients in different rooms do not receive each other's updates
- This ensures efficient bandwidth usage and proper game isolation

**Example Room Update Flow:**
```lua
-- Server: Room processes game step
local room = rooms[roomId]
local stateUpdate = GameManager.getRoomState(roomId)

-- Only send to clients in THIS room
for playerId, _ in pairs(room.players) do
  transport:send(playerId, cmsgpack.pack(stateUpdate))
end
```

**Room Join/Leave:**
- When a client joins a room, they start receiving that room's updates
- When a client leaves a room, they stop receiving updates from that room
- Clients can only be in one room at a time

**Local Game Initialization:**
- When user clicks "Start Local Game" from menu:
  1. Delete existing local room data if it exists
  2. Create a fresh "local" room via `Server.createLocalRoom()`
  3. Join player 1 to room via `Server.joinLocalRoom(1)`
  4. Switch to GameScreen
  5. GameScreen registers as client via `Server.registerClient(1, receiveCallback)`
  6. Each local player connects as a separate simulated connection (matching networked game architecture)
  7. GameScreen sends input and receives state updates through Server's unified API

### Headless Server Mode

LOVR supports running in headless mode:

**Configuration (`conf.lua`):**
```lua
function lovr.conf(t)
  -- Disable graphics for headless server
  t.modules.graphics = false
  t.modules.headset = false
  t.window = nil  -- No window needed
  
  -- Keep physics and other necessary modules
  t.modules.physics = true
  t.modules.system = true
  t.modules.timer = true
end
```

**Benefits:**
- Lower resource usage (no rendering overhead)
- Can run on servers without GPU
- Faster physics simulation (no frame rate limits)
- Deterministic execution

## State Transfer Strategy

### Delta Compression

Instead of sending full state every update, only send changes:

**Full State (every N ticks):**
```lua
{
  tick = 123,
  players = [...],  -- All player data
  entities = [...], -- All entity data
}
```

**Delta Update (most ticks):**
```lua
{
  tick = 123,
  baselineTick = 120,  -- Reference tick
  changes = {
    players = {
      {id = 1, x = 10.5, y = 20.3}  -- Only changed fields
    },
    entities = {
      {id = 10, health = 50}  -- Only changed fields
    }
  }
}
```

### Quantization

Reduce precision to save bandwidth:

- **Positions**: Convert float32 to int16 (0.01 unit precision)
  - `x = 10.5` → `x = 1050` (divide by 0.01 on client)
- **Rotations**: Use quaternion with reduced precision or Euler angles
- **Health**: Use uint8 (0-255) instead of float

**Example:**
```lua
-- Server: Quantize before sending
local quantized = {
  x = math.floor(position.x * 100),  -- 0.01 precision
  y = math.floor(position.y * 100),
  z = math.floor(position.z * 100),
  health = math.floor(health)  -- Integer health
}

-- Client: Dequantize after receiving
local position = {
  x = quantized.x / 100,
  y = quantized.y / 100,
  z = quantized.z / 100
}
```

### Message Structure

**Client → Server (Input):**
```lua
{
  tick = 123,           -- Client's current tick
  input = {
    moveForward = true,
    moveBackward = false,
    turnLeft = false,
    turnRight = true,
    shoot = false
  }
}
```

**Server → Client (State Update):**
```lua
{
  tick = 123,           -- Server tick
  baselineTick = 120,   -- For delta compression (nil if full state)
  players = [...],      -- Player states (only players in this room)
  entities = [...],      -- Entity states (only entities in this room)
  events = [...]        -- Game events (damage, spawns, etc.)
}
```

**Important:** State updates are **room-scoped** - they only contain data for the room the client is in, and are only sent to clients who are members of that room.

## Implementation Phases

### Phase 1: Local Game Client Connection (Current Priority)

**Goals:**
- Implement client connection system for local games
- Each local player connects as a separate simulated connection through Server
- GameScreen sends input and receives state updates via Server's unified API
- Establish foundation for future network transport

**Tasks:**
- [x] Create server configuration (disable graphics/headset)
- [x] Create `src/game/game_manager.lua` - authoritative game logic
- [x] Create `src/network/transport_local.lua` - local transport (direct calls)
- [x] Create `src/network/server.lua` - server coordinator
- [x] Add command-line flag to run in server mode
- [ ] Implement client connection in GameScreen (register client, receive callback)
- [ ] Implement input sending in GameScreen (send input messages to server)
- [ ] Implement state update handling in GameScreen (receive and store game state)
- [ ] Add cleanup/disconnect logic in GameScreen
- [ ] Test local client-server communication flow

### Phase 2: Network Gameplay (Version 2 - Future)

**Goals:**
- Implement network transport for online multiplayer
- Add ENet UDP networking support
- Implement network client connection
- Test networked gameplay

**Tasks:**
- [ ] Implement basic ENet network transport in `src/network/transport_network.lua`
- [ ] Test network transport (connection and message passing)
- [ ] Verify GameScreen works with network transport (no code changes needed - Server abstracts transport)

### Phase 3: State Serialization with MessagePack (Version 2 - Future)

**Goals:**
- Integrate MessagePack for state serialization
- Define game state structure
- Implement state packing/unpacking
- Send state updates at configured rate

**Tasks:**
- [ ] Install/configure MessagePack plugin (lua-cmsgpack)
- [ ] Define game state schema
- [ ] Implement state serialization functions
- [ ] Implement state deserialization functions
- [ ] Add state update loop to server (30-60 Hz)
- [ ] Add state application to client
- [ ] Test state synchronization

### Phase 4: Delta Compression Optimization (Version 2 - Future)

**Goals:**
- Implement delta compression
- Add quantization for positions/rotations
- Optimize bandwidth usage
- Add client-side prediction/interpolation

**Tasks:**
- [ ] Implement baseline tick system
- [ ] Add delta calculation (compare current vs baseline)
- [ ] Implement quantization for positions
- [ ] Add client-side state interpolation
- [ ] Implement client-side prediction
- [ ] Optimize message sizes
- [ ] Performance testing and tuning

## MessagePack Plugin Setup

MessagePack requires the `lua-cmsgpack` plugin. To use it:

1. **Install as LOVR plugin**: Place in `plugins/` directory
2. **Require in code**: `local cmsgpack = require 'cmsgpack'`
3. **Pack data**: `local packed = cmsgpack.pack(data)`
4. **Unpack data**: `local data = cmsgpack.unpack(packed)`

## Best Practices

1. **Fixed Timestep**: Always use fixed timestep for server physics
2. **Determinism**: Ensure all game logic is deterministic (seeded RNG, no platform-specific math)
3. **Input Buffering**: Buffer client inputs and apply them at correct server ticks
4. **State Validation**: Server should validate all client inputs
5. **Interpolation**: Clients should interpolate between state updates for smooth rendering
6. **Prediction**: Clients can predict their own actions for immediate feedback
7. **Bandwidth Monitoring**: Track bandwidth usage and adjust update rates as needed

## References

- [LOVR ENet Documentation](https://lovr.org/docs/enet)
- [lua-enet Documentation](http://leafo.net/lua-enet/)
- [MessagePack Specification](https://github.com/msgpack/msgpack/blob/master/spec.md)
- [lua-cmsgpack](https://github.com/antirez/lua-cmsgpack)

