local Keyboard = {}
-- mappings can point to multiple keys or buttons, and key combinations
local default_keyboard_mappings = {
    quit = {
        -- all the common ways to quit the game
        keys = {
            -- Standard quit shortcuts
            {'lctrl', 'q'},
            {'rctrl', 'q'},
            {'lalt', 'f4'},
            {'ralt', 'f4'},
            {'lgui', 'q'},
            {'rgui', 'q'},
            {'escape'},
            -- Additional common quit shortcuts
            {'lctrl', 'lshift', 'q'},
            {'lctrl', 'rshift', 'q'},
            {'rctrl', 'lshift', 'q'},
            {'rctrl', 'rshift', 'q'},
            {'lalt', 'x'},
            {'ralt', 'x'},
        },
    }
}

local keyboard_mappings = default_keyboard_mappings

function Keyboard.getActionFromKeyboardPress(pressed_key, scancode, isrepeat)
    for action, mappings in pairs(keyboard_mappings) do
        for _, key_combination in ipairs(mappings.keys) do
            -- Check if this is a single key or a combination
            if #key_combination == 1 then
                -- Single key: check if it matches the pressed key
                if key_combination[1] == pressed_key then
                    print("Keyboard press: " .. pressed_key .. " mapped to action: " .. action)
                    return action
                end
            else
                -- Key combination: check if the pressed key is the last key in the combination
                -- and all previous keys are currently held down
                local last_key = key_combination[#key_combination]
                if last_key == pressed_key then
                    -- Check if all modifier keys are held down
                    local all_keys_down = true
                    for i = 1, #key_combination - 1 do
                        if not lovr.system.isKeyDown(key_combination[i]) then
                            all_keys_down = false
                            break
                        end
                    end
                    if all_keys_down then
                        print("Keyboard combination mapped to action: " .. action)
                        return action
                    end
                end
            end
        end
    end
    return nil
end

function Keyboard.handleGlobalActions(action)
    if action == "quit" then
        lovr.event.quit()
    end
    return false
end

return Keyboard