# jewel-defender-lovr

Copyright 2025 Robert Kohr 

## Project Overview

A defender-style game built with LOVR (Lua-based VR/game framework). Currently in early development with a functional menu system.

## Architecture & Structure

### State Management System
- State-based architecture (`src/state.lua`)
- Current states: `MenuState`, `GameState`
- States initialized via `State.SetCurrentState()`
- Each state implements: `init()`, `update(dt)`, `draw(pass)`, `cleanup()`, `onKeyPressed()`

### Key Modules
- **Utils** (`src/utils.lua`): HUD rendering, fullscreen management, debug tools
- **Mouse** (`src/mouse.lua`): Normalized mouse position calculations
- **Keyboard** (`src/keyboard.lua`): Keyboard input mapping and action handling

## Menu System

### Features
- 4 menu items: "Start Game", "Options", "Extras", "Quit"
- Hover detection with visual feedback (shadow removal on hover)
- Click handling: menu items have callback functions
- Debug display: mouse coordinates and hovered item label

### Configuration
- Font: Montserrat-ExtraBoldItalic.ttf (80pt, 4px padding)
- Text size: 0.136 normalized units
- Menu positioned at (-0.867, -0.232) with 0.15 spacing between items
- Background image: `assets/images/main_menu_background.jpg`

## Performance Optimizations

1. Removed redundant `menu_options` array (consolidated into `menu_items`)
2. Cached frequently used functions as local variables
3. Fixed font creation bug: font was being created every frame (major FPS issue)
4. Optimized imports: cached module functions for better performance

## Configuration

- **Window Settings**: Windowed mode, 800x600
- **Graphics**: Antialiasing disabled, VSync enabled
- **Headset**: Disabled (desktop mode)
- **Fullscreen**: Configurable via `_G.fullscreen` flag in `main.lua`

## Code Patterns & Best Practices

- Local variable caching for performance
- Modular design with clear separation of concerns
- Consistent naming conventions
- Error handling for nil checks
- Debug utilities for development

## Current Status

The menu system is functional with:
- ✅ Hover detection
- ✅ Click handling with callbacks
- ✅ Visual feedback
- ✅ Debug information display
- ✅ Performance optimizations in place
