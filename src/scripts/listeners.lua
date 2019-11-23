-- ----------------------------------------------------------------------------------------------------
-- EVENT LISTENERS
-- Entry point for the control scripting. Contains all non-gui event listeners.

local event = require('scripts/lib/event-handler')
local mod_gui = require('mod-gui')
local util = require('scripts/lib/util')

local editor_gui = require('scripts/gui/windows/editor')

local function setup_player(index)
    local data = {
        areas = {},
        default_settings = {
            filename = 'Debug',
            extension = 2,
            jpeg_quality = 100,
            zoom = 1,
            show_alt_info = true,
            antialias = 0
        },
        gui = {
            textfields = {}
        }
    }
    global.players[index] = data
    -- create mod GUI button
    -- local button_flow = mod_gui.get_button_flow(util.get_player(index))
    -- if not button_flow.ssp_editor_button then
    --     local ssp_button = button_flow.add{type='sprite-button', name='ssp_editor_button', style=mod_gui.button_style, sprite='ssp-camera'}
    --     ssp_button.style.padding = 5
    -- end
end

-- event.gui.on_click('ssp_editor_button', function(e)
--     print(serpent.block(global.conditional_event_registry))
-- end)

event.on_init(function()
    global.players = {}
    for i,p in pairs(game.players) do
        setup_player(i)
    end
end)

-- when a player is created
event.register(defines.events.on_player_created, function(e)
    setup_player(e.player_index)
end)

-- when a player selects an area with a selection tool
event.register({defines.events.on_player_selected_area, defines.events.on_player_alt_selected_area}, function(e)
    if e.item ~= 'screenshotplus-selector' then return end
    local player, player_table = util.get_player(e)
    local gui_pinned = false
    local parent = gui_pinned and mod_gui.get_frame_flow(player) or player.gui.screen
    if parent.ssp_editor_window then
        player.print{'chat-message.finish-current-screenshot'}
        return
    end
    local area = util.setup_area(e.area)
    -- draw rectangle to show screenshot area
    local rectangle = rendering.draw_rectangle{
        color = {r=0, g=0.831, b=1},
        filled = false,
        left_top = area.left_top,
        right_bottom = area.right_bottom,
        surface = player.surface,
        players = {player}
    }
    local elems, textfield_data = editor_gui.create(parent, gui_pinned, player.index, player_table.default_settings)
    player_table.gui.editor = elems
    for n,t in pairs(textfield_data) do
        player_table.gui.textfields[n] = t
    end
    player_table.current = {
        area = area,
        rectangle = rectangle,
        settings = table.deepcopy(player_table.default_settings),
        initial_area = table.deepcopy(area),
        initial_settings = table.deepcopy(player_table.default_settings)
    }
end)