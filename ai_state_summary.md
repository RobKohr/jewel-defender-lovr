# AI State Summary - Jewel Defender LOVR Project

## Project Overview
A defender-style game built with LOVR (Lua-based VR/game framework). The project uses a state-based architecture with MenuState and GameState.

## Key Technical Learnings

### 1. Z-Fighting Issue and Solution
**Problem**: Brown ground box was showing through green top plane, especially when resizing window.

**Root Cause**: The brown box's top face and green plane were at exactly the same depth (`PLATE_HEIGHT`), causing z-fighting.

**Solution**: Offset the green plane slightly above the box:
```lua
pass:plane(0, PLATE_HEIGHT + 0.001, 0, PLATE_WIDTH, PLATE_DEPTH, math.pi / 2, 1, 0, 0)
```

### 2. LOVR Mat4 lookAt Method
**Issue**: `view_matrix:lookAt()` was throwing "Undefined field `lookAt`" error.

**Root Cause**: The `lookAt` method expects `Vec3` objects, not individual numbers.

**Solution**: Convert camera position and look-at point to Vec3 objects:
```lua
local camera_pos = lovr.math.vec3(camera_position[1], camera_position[2], camera_position[3])
local look_at = lovr.math.newVec3(0, PLATE_HEIGHT, 0)
local up = lovr.math.newVec3(0, 1, 0)
view_matrix:lookAt(camera_pos, look_at, up)
```

**Performance Note**: Creating the matrix inline (`lovr.math.mat4():lookAt(...)`) helps with linter type inference, but reusing a permanent matrix (`lovr.math.newMat4()`) is better for performance when recalculating every frame.

### 3. Vec3 Component Assignment
**Issue**: `camera_pos:set()` method was failing.

**Solution**: Use direct component assignment instead:
```lua
camera_pos.x = camera_position[1]
camera_pos.y = camera_position[2]
camera_pos.z = camera_position[3]
```

**Important**: For module-level variables that persist across frames, use `lovr.math.newVec3()` (permanent vectors), not `lovr.math.vec3()` (temporary vectors that are only valid within a single frame).

### 4. Lighting System Implementation
**Problem**: Tank model appeared flat and featureless (just a red texture).

**Solution**: Created a custom lighting shader with:
- Ambient lighting (0.6, 0.6, 0.6) for base illumination
- Directional light from above and slightly to the side
- **Critical**: Must preserve base color/texture by multiplying lighting with base color, not replacing it

**Key Shader Code**:
```lua
vec4 baseColor = Color * getPixel(ColorTexture, UV);
vec3 lighting = ambient + getLighting(surface, lightDirection, lightColorAndBrightness, visibility);
vec3 finalColor = baseColor.rgb * lighting;
return vec4(finalColor, baseColor.a);
```

### 5. Coordinate System Differences: Blender vs LOVR

**Blender Coordinate System** (user's setup):
- **Y (green)**: Right (+)
- **X (red)**: Forward/Backward  
- **Z (blue)**: Up/Down

**LOVR/OpenGL Coordinate System**:
- **X**: Right (+)
- **Y**: Up (+)
- **Z**: Backward (+) / Forward (-) - **Negative Z is toward camera**

**Important**: When a model points along Blender's Y-axis (right), it maps to LOVR's +Z (backward/away from camera) at 0° rotation. To face the camera, rotate 180° around Y-axis.

### 6. Game State Implementation Details

**Ground Plate**:
- 1 meter thick (6 units) platform
- Brown sides/bottom, green top
- 144x72 units (24x12 grid squares, 6 units each)
- Grid lines drawn 0.01 units above surface

**Camera System**:
- Dynamic camera positioning based on viewport aspect ratio
- 50-degree angle looking down at plate
- Automatically adjusts distance to show entire plate
- Uses `pass:setViewPose(1, view_matrix, true)` with inverted view matrix

**Tank Rendering**:
- Positioned 1 meter above ground (`PLATE_HEIGHT + 1`)
- Uses custom lighting shader
- Currently rotated 0° (points away from camera - needs 180° to face camera)

## File Structure
- `src/states/game/game_state.lua` - Main game state with 3D scene
- `src/states/menu/menu_state.lua` - Menu system
- `assets/objects/player_tank.glb` - Tank model
- `.gitignore` - Includes `.DS_Store` to ignore macOS system files

## Current Status
- ✅ 3D game state fully implemented
- ✅ Camera system working
- ✅ Lighting system working
- ✅ Ground plate with grid rendering
- ⚠️ Tank orientation needs adjustment (180° rotation to face camera)
- ✅ Menu connects to game state

## Performance Optimizations Applied
- Reuse permanent matrices/vectors instead of creating temporary ones each frame
- Cache frequently used values
- Use permanent vectors (`newVec3`) for module-level variables

## Common Pitfalls to Avoid
1. Don't use temporary vectors (`vec3`) for module-level variables - they're only valid within a single frame
2. Always offset overlapping surfaces slightly to avoid z-fighting
3. When using custom shaders, preserve base color by multiplying lighting, not replacing it
4. Remember LOVR's Z-axis: negative Z is toward camera, positive Z is away
5. Linter warnings about `lookAt` and `set` methods are often false positives - the code works at runtime

