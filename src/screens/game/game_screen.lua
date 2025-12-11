local GameScreen = {}

-- localize functions and constants that are used in this file (don't add things that aren't used in this file)
-- localized functions
local rad = math.rad
local tan = math.tan
local atan = math.atan
local sin = math.sin
local cos = math.cos
local max = math.max
local newMat4 = lovr.math.newMat4
local newVec3 = lovr.math.newVec3
-- localized constants
local PI = math.pi


-- Grid configuration
local GRID_SIZE = 6  -- Each grid square is 6x6 units
local GRID_WIDTH = 24  -- 24 grid squares wide
local GRID_DEPTH = 12  -- 12 grid squares deep
local GRID_HEIGHT = 1  -- 1 grid square tall

-- Plate dimensions in world units
local PLATE_WIDTH = GRID_WIDTH * GRID_SIZE   -- 144 units
local PLATE_DEPTH = GRID_DEPTH * GRID_SIZE   -- 72 units
local PLATE_HEIGHT = GRID_HEIGHT * GRID_SIZE -- 6 units

-- Colors
local SKY_BLUE = {0.53, 0.81, 0.92}  -- Sky blue background
local GREEN = {0.2, 0.8, 0.2}        -- Green top
local BROWN = {0.4, 0.25, 0.15}      -- Brown sides/bottom

-- Grid lines toggle
local SHOW_GRID_LINES = true

-- Camera configuration
local CAMERA_ANGLE = rad(50)  -- 50 degrees in radians
local camera_distance = 0
local camera_position = {0, 0, 0}
local view_matrix = nil
local look_at = nil
local up = nil
local camera_pos = nil

-- Player tank
local player_tank_model = nil
local lighting_shader = nil


local blender_to_lovr_rotation = rad(-90) -- convert blender rotation to lovr rotation

function GameScreen.init()
  -- Set sky blue background
  lovr.graphics.setBackgroundColor(SKY_BLUE[1], SKY_BLUE[2], SKY_BLUE[3])
  
  -- Initialize view matrix (reused each frame for better performance)
  view_matrix = newMat4()
  
  -- Initialize permanent vectors (must use newVec3, not vec3, for module-level variables)
  look_at = newVec3(0, PLATE_HEIGHT, 0)
  up = newVec3(0, 1, 0)
  camera_pos = newVec3(0, 0, 0)
  
  -- Load lighting shader with rim lighting for tank edges
  lighting_shader = require('assets/shaders/tank_rim_lighting')
  
  -- Load player tank model
  player_tank_model = lovr.graphics.newModel('assets/objects/player_tank.glb')
end

function GameScreen.update(dt)
  -- Camera position will be calculated in draw() based on viewport
end

function GameScreen.draw(pass)
  -- Get viewport dimensions
  local width, height = pass:getDimensions()
  local aspect_ratio = width / height
  
  -- Calculate camera distance to show entire base plate
  -- We need to ensure both width and height of plate are visible
  local plate_half_width = PLATE_WIDTH / 2
  local plate_half_depth = PLATE_DEPTH / 2
  
  -- Calculate required distance based on FOV and plate dimensions
  -- Using a reasonable FOV (60 degrees) - this is the vertical FOV
  local fov = rad(60)
  local fov_half = fov / 2
  
  -- Calculate horizontal FOV based on aspect ratio
  -- horizontal_fov = 2 * atan(tan(vertical_fov/2) * aspect_ratio)
  local tan_fov_half = tan(fov_half)
  local horizontal_fov_half = atan(tan_fov_half * aspect_ratio)
  
  -- Distance needed to fit plate width (using horizontal FOV)
  local distance_for_width = plate_half_width / tan(horizontal_fov_half)
  -- Distance needed to fit plate depth (using vertical FOV)
  local distance_for_depth = plate_half_depth / tan_fov_half
  
  -- Use the larger distance to ensure entire plate is visible
  local base_distance = max(distance_for_width, distance_for_depth) * 1.1  -- 10% padding
  
  -- Calculate camera position at 50 degree angle
  -- Camera is positioned at an angle, looking down at the plate
  local camera_height = base_distance * sin(CAMERA_ANGLE)
  local camera_horizontal_distance = base_distance * cos(CAMERA_ANGLE)
  
  -- Position camera to look at center of plate's top surface
  camera_position[1] = 0
  camera_position[2] = camera_height + PLATE_HEIGHT
  camera_position[3] = camera_horizontal_distance
  
  -- Update camera position vector (use direct assignment if set method fails)
  if camera_pos then
    camera_pos.x = camera_position[1]
    camera_pos.y = camera_position[2]
    camera_pos.z = camera_position[3]
  else
    camera_pos = newVec3(camera_position[1], camera_position[2], camera_position[3])
  end
  -- Set up view matrix to look at center of plate's top surface
  if view_matrix == nil or look_at == nil or up == nil then
    error("Camera setup incomplete: view_matrix, look_at, or up is nil")
  end
  
  view_matrix:lookAt(camera_pos, look_at, up)
  
  -- Set camera view pose (lookAt creates a view matrix, so inverted = true)
  pass:setViewPose(1, view_matrix, true)

  -- Apply lighting shader to everything (ground, grid lines, and tank)
  pass:setShader(lighting_shader)

  -- Draw ground plate
  -- Main brown box (sides and bottom)
  pass:setColor(BROWN[1], BROWN[2], BROWN[3])
  pass:box(0, PLATE_HEIGHT / 2, 0, PLATE_WIDTH, PLATE_HEIGHT, PLATE_DEPTH)
  
  -- Green top face (slightly above box to avoid z-fighting)
  pass:setColor(GREEN[1], GREEN[2], GREEN[3])
  pass:plane(0, PLATE_HEIGHT + 0.001, 0, PLATE_WIDTH, PLATE_DEPTH, PI / 2, 1, 0, 0)
  
  -- Draw grid lines on top if enabled
  if SHOW_GRID_LINES then
    pass:setColor(0, 0, 0, 0.3)  -- Semi-transparent black
    
    -- Vertical lines (along X axis)
    for i = 0, GRID_WIDTH do
      local x = -PLATE_WIDTH / 2 + i * GRID_SIZE
      local z_start = -PLATE_DEPTH / 2
      local z_end = PLATE_DEPTH / 2
      pass:line(x, PLATE_HEIGHT + 0.01, z_start, x, PLATE_HEIGHT + 0.01, z_end)
    end
    
    -- Horizontal lines (along Z axis)
    for i = 0, GRID_DEPTH do
      local z = -PLATE_DEPTH / 2 + i * GRID_SIZE
      local x_start = -PLATE_WIDTH / 2
      local x_end = PLATE_WIDTH / 2
      pass:line(x_start, PLATE_HEIGHT + 0.01, z, x_end, PLATE_HEIGHT + 0.01, z)
    end
  end
  
  -- Draw player tank 1 meter above the ground
  pass:setColor(1, 1, 1)
  -- Rotate -90 degrees around Y axis (vertical)
  local tank_rotation = blender_to_lovr_rotation;
  pass:draw(player_tank_model, 0, PLATE_HEIGHT + 1, 0, 1, tank_rotation, 0, 1, 0)
  
  pass:setShader()  -- Reset to default shader for other draws
end

function GameScreen.cleanup()
  -- Nothing to cleanup
end

function GameScreen.onKeyPressed(key, scancode, isrepeat, action)
  -- TODO: Implement key press handling
end

return GameScreen