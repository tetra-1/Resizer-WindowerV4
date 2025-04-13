--[[
Copyright © 2025, Tetra
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Resizer nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Tetra BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]--

_addon.name = 'Resizer'
_addon.version = '1.0.0'
_addon.command = 'resizer'
_addon.author = 'Tetra'
_addon.link = "https://github.com/tetra-1/Resizer-WindowerV4"

local packets = require('packets')
local config = require('config')
local bit = require('bit')

-- Addon settings
local default_settings = {
    use_default_size = true,
    size = 'none',
    add_to_chat = false
}

local resizer = {
    character_load_pending = false,
    settings = {}
}

-- Table for converting user's shorthand input into regular, human readable values.
local size_aliases = {
    s = 'small',
    m = 'medium',
    l = 'large',
    [0] = 'small',
    [1] = 'medium',
    [2] = 'large'
}

-- TODO: check if there's some built in windower features for formatting and outputting to the chat/console, much like ashita's
--[[
* Prints a formatted message to the console or the game's chat window.
*
* @param {string} ... - Contents of the message to be output. Variable number of arguments allowed.
--]]
resizer.print = function(...)
    if ... == nil then
        return
    end

    local header = string.format("[%s]", _addon.name)

    if resizer.settings.add_to_chat then
        windower.add_to_chat(0, header .. ' ' .. ...)
    else
        print(header .. ' ' .. ...)
    end
end

--[[
* Sets the bit in the given position to 0 using bitwise magic, then returns the new integer.
*
* @param {integer} number - Integer to be modified.
* @param {integer} position - 0-based index of the bit to be flipped off.
*
* @return {integer} - The modified integer after the chosen bit has been flipped.
--]]
local function bitmask_off(number, position)
    --first we need the bit that's going to be cleared; we do this by bit shifting the number 1 to the left by the number of the bit's position
    local bitmask = bit.lshift(1, position)

    --next do a bitwise not on the bitmask
    bitmask = bit.bnot(bitmask)

    --finally do a bitwise and between the number and the bitmask
    return bit.band(number, bitmask)
end

--[[
* Sets the bit in the given position to 1 using bitwise magic, then returns the new integer.
*
* @param {integer} number - Integer to be modified.
* @param {integer} position - 0-based index of the bit to be turned on.
*
* @return {integer} - The modified integer after the chosen bit has been flipped.
--]]
local function bitmask_on(number, position)
    --first we need the bit that's going to be cleared; we do this by bit shifting the number 1 to the left by the number of the bit's position
    local bitmask = bit.lshift(1, position)

    --now we just do a bitwise inclusive or between the number and the bitmask
    return bit.bor(number, bitmask)
end

--[[
* Helper function for checking if a table contains the given value.
*
* @param {table} table - Table to be searched for the first instance of a given value.
* @param {any} value - Value to search for.
*
* @return {boolean} - True if the value was found within the table, false otherwise.
--]]
local function contains(table, value)
    for k, v in pairs(table) do
        if v == value then
            return true
        end
    end

    return false
end

--[[
* Prints the addon help information.
*
* @param {boolean} isError - Flag if this function was invoked due to an error.
--]]
local function print_help(isError)
    -- Print the help header..
    if (isError) then
        resizer.print('Invalid command syntax for command: resizer')
    else
        resizer.print('Available commands:')
    end

    local cmds = T{
        { 'resizer', 'Displays the current size setting.'},
        { 'resizer help', 'Displays the addons help information.' },
        { 'resizer (small | medium | large | s | m | l | 0 | 1 | 2)', "Sets the player's new size to the chosen value." },
        { 'resizer default', "Returns the player's size to the server default." },
        { 'resizer toggle_chat', "Toggles output to the game's chat window."},
        { 'resizer use_chat (on | off)', "Turns output to the game's chat window on or off."}
    }

    -- Print the command list..
    for key, value in pairs(cmds) do
        resizer.print(string.format("Usage: %s - %s", value[1], value[2]))
    end
end

--[[
* event: load
* desc : Event called when the addon has loaded.
--]]
windower.register_event('load', function()
    resizer.settings = config.load(default_settings)
    resizer.character_load_pending = true
end)

--[[
* event: login
* desc : Event called when the player has logged in.
--]]
windower.register_event('login', function()
    resizer.settings = config.load(default_settings)
end)

--event handler which is called when windower processes an incoming chunk, or packet
--[[
* event: incoming chunk
* desc : Event called when the addon is processing incoming packets.
--]]
windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    if blocked then
        return
    end

    --these packets all update the player's character model, specifically the size
    if id ~= 0x00A and id ~= 0x037 then
        return
    end

    --Windower's load event occurs before logging into your character. The login event occurs after.
    --In order to get the character specific settings on the first zone in, we need to do another config.load here.
    --Everything should work fine afterwards.
    if resizer.character_load_pending then
        resizer.settings = config.load(default_settings)
        resizer.character_load_pending = false
    end

    --only modify the packet if the player is using a different character size
    if resizer.settings.use_default_size then
        return
    end

    --get the player information, which will be useful for filtering incoming packets
    --is this necessary? eh, whatever
    local player = windower.ffxi.get_player()

    --parse the incoming packet (use the modified packet for greater compatibility with other addons)
    local packet = packets.parse('incoming', modified)

    --flag to check if we modified the packet and need to rebuild it
    local modified = false

    --the 0x00A packet is received on entering a zone, and contains information on the player's character model to be loaded (among other things)
    if id == 0x00A then
        --At the time of this writing the player's size is stored in a byte of flags at the 0x21 offset. In Windower this is currently covered by the field '_unknown1'.
        --the size of a character is stored in the 2nd and 3rd bits of the flags as the binary value of 0 (00), 1 (01), or 2 (10)
        --0 == small, 1 == medium, and 2 == large
        --The player's size value is also stored at 0xB6 (_unknown13 in Windower), directly represented as 0, 1, or 2. However changing it doesn't seem to do anything, so I don't know what it's used for.
        if packet['_unknown1'] then
            --retrieve the relevant flags from the _unknown1 field
            local flags = string.byte(packet['_unknown1'], 2)
            local new_flags

            --don't care what the size value was before, just overwrite it with the new one
            --Note: might as well change the size at 0xB6/_unknown13 just in case
            if resizer.settings.size == 'small' then
                --clear the 2nd bit and clear the 3rd bit
                new_flags = bitmask_off(flags, 1)
                new_flags = bitmask_off(new_flags, 2)

                packet['_unknown13'] = 0
            elseif resizer.settings.size == 'medium' then
                --set the 2nd bit to 1 and clear the 3rd bit
                new_flags = bitmask_on(flags, 1)
                new_flags = bitmask_off(new_flags, 2)

                packet['_unknown13'] = 1
            elseif resizer.settings.size == 'large' then
                --clear the 2nd bit and set the 3rd bit to 1
                new_flags = bitmask_off(flags, 1)
                new_flags = bitmask_on(new_flags, 2)

                packet['_unknown13'] = 2
            end

            --pack the new flags back into the _unknown1 field using the original data as a base
            --_unknown1 is a 16 byte block of flags and other data, so we need to repack all 16 bytes
            --(if there's a better way to do this, google won't tell it to me)
            local original_data = packet['_unknown1']
            packet['_unknown1'] = string.pack(
                'c16',
                string.byte(original_data, 1),
                new_flags,
                string.byte(original_data, 3),
                string.byte(original_data, 4),
                string.byte(original_data, 5),
                string.byte(original_data, 6),
                string.byte(original_data, 7),
                string.byte(original_data, 8),
                string.byte(original_data, 9),
                string.byte(original_data, 10),
                string.byte(original_data, 11),
                string.byte(original_data, 12),
                string.byte(original_data, 13),
                string.byte(original_data, 14),
                string.byte(original_data, 15),
                string.byte(original_data, 16)
            )

            modified = true
        else
            --If there's no _unknown1 field then the packets library must have changed, and this addon will need to be updated. Warn the user so they know what's happening and where to go.
            resizer.print(string.format("[WARNING] Packet fields are missing or renamed so size changes won't work properly. Resizer may need an update. (%s)", _addon.link))
        end
    end

    --the 0x037 packet is received when the player's character model appearance is to be updated (such as after equipping/unequipping gear)
    if id == 0x037 then
        --In Windower this packet's size flag is stored in the '_flags1' field.
        --The size of a character is stored in the 12th and 13th bits of the flags as the binary value of 0 (00), 1 (01), or 2 (10)
        --0 == small, 1 == medium, and 2 == large
        if packet['_flags1'] and packet['Player'] and packet['Player'] == player.id then
            local flags = packet['_flags1']
            local new_flags

            --don't care what the size value was before, just overwrite it with the new one
            if resizer.settings.size == 'small' then
                --clear the 12th bit and clear the 13th bit
                new_flags = bitmask_off(flags, 11)
                new_flags = bitmask_off(new_flags, 12)
            elseif resizer.settings.size == 'medium' then
                --set the 12th bit to 1 and clear the 13th bit
                new_flags = bitmask_on(flags, 11)
                new_flags = bitmask_off(new_flags, 12)
            elseif resizer.settings.size == 'large' then
                --clear the 12th bit and set the 13th bit to 1
                new_flags = bitmask_off(flags, 11)
                new_flags = bitmask_on(new_flags, 12)
            end
            
            packet['_flags1'] = new_flags
            modified = true
        end
    end

    --if the packet was successfully modified, build it and return the result; otherwise do nothing
    if modified then
        return packets.build(packet)
    end
end)

--[[
* event: addon command
* desc : Event called when the addon is processing a command.
--]]
windower.register_event('addon command', function(...)
    local arg = {...}

    -- Handle: resizer - Gives basic info about the addon's current settings.
    if (#arg == 0) then
        if(resizer.settings.use_default_size) then
            resizer.print("Using the server default size.")
        else
            resizer.print(string.format("Player's size is currently set to '%s'.", resizer.settings.size))
        end

        return
    end

    -- Handle: resizer help - Shows the addon help.
    if (#arg == 1 and arg[1] == 'help') then
        print_help(false)
        return
    end

    -- Handle: resizer <size> - Changes the player's size to the chosen value.
    if (#arg == 1 and contains({'small', 'medium', 'large', 's', 'm', 'l', 0, 1, 2}, arg[1])) then
        if contains({'small', 'medium', 'large'}, arg[1]) then
            resizer.settings.size = arg[1]
        else
            --convert the user's shorthand input into something more readable
            resizer.settings.size = size_aliases[arg[1]]
        end

        resizer.settings.use_default_size = false

        resizer.print(string.format("Player size set to '%s'. Please change zones, equipment, or jobs to update your model.", resizer.settings.size))

        config.save(resizer.settings)
        return
    end

    -- Handle: resizer default - Reverts to the player's default size.
    if (#arg == 1 and arg[1] == 'default') then
        resizer.settings.use_default_size = true

        resizer.print("Using player's default size. Please change zones, equipment, or jobs to update your model.")

        config.save(resizer.settings)
        return
    end

    -- Handle: resizer toggle_chat - Toggles outputting to the game's chat window.
    if (#arg == 1 and arg[1] == 'toggle_chat') then
        resizer.settings.add_to_chat = not resizer.settings.add_to_chat

        if resizer.settings.add_to_chat then
            resizer.print("Outputting to chat window.")
        else
            resizer.print("Outputting to console.")
        end

        config.save(resizer.settings)
        return
    end
    
    -- Handle: resizer use_chat (on | off)
    if (#arg == 2 and arg[1] == 'use_chat' and ({'on', 'off'}):contains(arg[2])) then
        if arg[2] == 'on' then
            resizer.settings.add_to_chat = true
            resizer.print("Outputting to chat window.")
        else
            resizer.settings.add_to_chat = false
            resizer.print("Outputting to console.")
        end

        config.save(resizer.settings)
        return
    end

    -- Unhandled: Print help information.
    print_help(true)
end)