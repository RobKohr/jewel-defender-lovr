# Network Plan - Jewel Defender LOVR

## Overview

This document outlines the networking architecture for implementing multiplayer functionality with an authoritative server model. The server will run in headless mode using LOVR's capabilities, handling physics and game state deterministically.

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

### Authoritative Server Design

The server is the single source of truth for all game state:

- **Server responsibilities**:
  - Run physics simulation deterministically
  - Process player inputs
  - Validate game state
  - Broadcast state updates to clients

- **Client responsibilities**:
  - Send input to server
  - Receive and apply state updates
  - Render game state (with client-side prediction/interpolation)
  - Handle local UI/effects

### ENet for UDP Networking

LOVR includes the `enet` plugin for UDP networking:

**Server Setup:**
```lua
local enet = require 'enet'

function lovr.load()
  local host = enet.host_create('0.0.0.0:6789')  -- Listen on port
  
  -- Service events in update loop
  local event = host:service(100)  -- 100ms timeout
  if event then
    if event.type == 'connect' then
      -- Handle new client
    elseif event.type == 'receive' then
      -- Handle incoming message
      local data = cmsgpack.unpack(event.data)
      processClientInput(data, event.peer)
    elseif event.type == 'disconnect' then
      -- Handle client disconnect
    end
  end
end
```

**Client Setup:**
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
  players = [...],      -- Player states
  entities = [...],      -- Entity states
  events = [...]        -- Game events (damage, spawns, etc.)
}
```

## Implementation Phases

### Phase 1: Basic Server/Client Setup

**Goals:**
- Set up headless server configuration
- Implement basic ENet server and client
- Establish connection between client and server
- Send/receive simple messages

**Tasks:**
- [ ] Create server configuration (disable graphics/headset)
- [ ] Implement basic ENet server in `src/network/server.lua`
- [ ] Implement basic ENet client in `src/network/client.lua`
- [ ] Add command-line flag to run in server mode
- [ ] Test basic connection and message passing

### Phase 2: State Serialization with MessagePack

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

### Phase 3: Delta Compression Optimization

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

