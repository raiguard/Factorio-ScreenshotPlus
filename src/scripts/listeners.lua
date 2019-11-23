-- ----------------------------------------------------------------------------------------------------
-- EVENT LISTENERS
-- Entry point for the control scripting. Contains all non-gui event listeners.

local event = require('scripts/lib/event-handler')
local mod_gui = require('mod-gui')
local util = require('scripts/lib/util')

local editor_gui = require('scripts/gui/windows/editor')

-- --------------------------------------------------
-- LOCAL UTILITIES

local function setup_player(index)
    local data = {
        active_gifs = {},
        areas = {},
        default_settings = {
            filename = 'Debug',
            extension = 2,
            jpeg_quality = 100,
            zoom = 1,
            show_alt_info = true,
            antialias = 0,
            type = 'picture',
            gif_delay = 1,
            gif_length = 5
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

local extensions_by_index = {'.jpg', '.png', '.bmp'}
local function take_screenshot(player, settings, new_name, print)
    local area = settings.area
    local name = new_name or settings.filename
    game.take_screenshot{
        player = player,
        by_player = player,
        surface = player.surface,
        position = area.center,
        resolution = {x=area.width*settings.zoom*32, y=area.height*settings.zoom*32},
        zoom = settings.zoom,
        path = 'ScreenshotPlus/'..name..extensions_by_index[settings.extension],
        quality = settings.jpeg_quality,
        show_entity_info = settings.show_alt_info,
        anti_alias = settings.antialias,
        show_gui = false
    }
    if print then
        player.print('Screenshot saved to script-output/ScreenshotPlus/'..settings.filename..extensions_by_index[settings.extension])
    end
end

-- --------------------------------------------------
-- EVENT HANDLERS

-- handles GIF making: takes screenshots at the appropriate intervals
local function gif_on_tick(e)
    local tick = e.tick
    local active_players = global.conditional_event_registry.gif_on_tick.players
    for _,pi in pairs(active_players) do
        local player, player_table = util.get_player(pi)
        for i,t in pairs(player_table.active_gifs) do
            -- check if it needs a screenshot
            if tick % t.gif_delay == 0 then
                -- take a screenshot
                local new_name = string.format(t.filename, t.next_shot_index)
                take_screenshot(player, t, new_name, false)
                t.next_shot_index = t.next_shot_index + 1
                t.last_shot_tick = tick
            end
            -- check if this GIF should be retired
            if tick >= t.perish_tick then
                table.remove(player_table.active_gifs, i)
            end
        end
        -- check if the event should be deregistered for this player
        if table_size(player_table.active_gifs) == 0 then
            event.deregister(defines.events.on_tick, gif_on_tick, 'gif_on_tick', pi)
        end
    end
end

-- handler that is called when the player finishes editing a screenshot
local function on_editing_finished(e)
    local player, player_table = util.get_player(e)
    local settings = player_table.current.settings
    if settings.type == 'picture' then
        take_screenshot(player, settings, nil, true)
    else
        -- register on_tick event if needed
        if table_size(player_table.active_gifs) == 0 then
            event.register(defines.events.on_tick, gif_on_tick, 'gif_on_tick', player.index)
        end
        -- add to active GIFs table
        local data = table.deepcopy(settings)
        data.perish_tick = game.tick + (data.gif_length * 60)
        data.last_shot_tick = game.tick
        data.next_shot_index = 1
        data.filename = data.filename..'/'..data.filename..'-%03d'
        table.insert(player_table.active_gifs, data)
    end
end

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
    local elems, textfield_data = editor_gui.create(parent, gui_pinned, player.index, player_table.default_settings, on_editing_finished)
    player_table.gui.editor = elems
    for n,t in pairs(textfield_data) do
        player_table.gui.textfields[n] = t
    end
    local settings = table.deepcopy(player_table.default_settings)
    settings.area = area
    player_table.current = {
        rectangle = rectangle,
        settings = settings,
        initial_settings = table.deepcopy(settings)
    }
end)