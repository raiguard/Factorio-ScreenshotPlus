-- ----------------------------------------------------------------------------------------------------
-- EDITOR GUI
-- Comes up when a player selects an area for screenshotting. Lets one edit the area and screenshot settings.

local event = require('scripts/lib/event-handler')
local titlebar = require('scripts/gui/gui-elems/titlebar')
local mod_gui = require('mod-gui')
local util = require('scripts/lib/util')

local confirm_button_handler
local editor_gui = {}

-- --------------------------------------------------
-- LOCAL UTILITIES

local function create_adjustment_buttons(parent, name, direction, opp)
    local flow_direction = (direction=='east' or direction=='west') and 'vertical' or 'horizontal'
    local flow = parent.add{type='flow', name='ssp_editor_pos_'..name..'_'..direction..'_flow', direction=flow_direction}
    if flow_direction == 'vertical' then
        flow.style.vertical_spacing = 0
    else
        flow.style.horizontal_spacing = 0
    end
    local button_out = flow.add{type='sprite-button', name='ssp_editor_pos_'..name..'_'..direction..'_out_button', style='close_button_light',
                                sprite='ssp-move-'..direction..'-white', hovered_sprite='ssp-move-'..direction, clicked_sprite='ssp-move-'..direction}
    local button_in
    if opp then
        local visual_direction = util.oppositedirection_string[direction]
        button_in = flow.add{type='sprite-button', name='ssp_editor_pos_'..name..'_'..direction..'_in_button', style='close_button_light',
                             sprite='ssp-move-'..visual_direction..'-white', hovered_sprite='ssp-move-'..visual_direction,
                             clicked_sprite='ssp-move-'..visual_direction}
    end
    return button_out, button_in
end
local function create_adjustment_pad(parent, name, sprite, opp)
    local buttons = {}
    local flow = parent.add{type='flow', name='ssp_editor_pos_'..name..'_flow', direction='vertical'}
    flow.style.horizontal_align = 'center'
    flow.style.horizontally_stretchable = true
    flow.add{type='label', name='ssp_editor_pos_'..name..'_label', caption={'gui-screenshot-editor.movement-pad-'..name..'-label'}}
    local elem_table = flow.add{type='table', name='ssp_editor_pos_'..name..'_table', style='ssp_adjustment_pad_table', column_count=3}
    elem_table.add{type='empty-widget', name='ssp_editor_pos_'..name..'_1'}
    buttons[1], buttons[2] = create_adjustment_buttons(elem_table, name, 'north', opp)
    elem_table.add{type='empty-widget', name='ssp_editor_pos_'..name..'_3'}
    buttons[3], buttons[4] = create_adjustment_buttons(elem_table, name, 'west', opp)
    local button = elem_table.add{type='sprite-button', name='ssp_editor_pos_'..name..'_edit_button', style='tool_button', sprite=sprite,
                             tooltip={'gui-screenshot-editor.movement-pad-'..name..'-button-tooltip'}}
    if not opp then button.style.margin = 2 end
    -- button.enabled = false
    buttons[5], buttons[6] = create_adjustment_buttons(elem_table, name, 'east', opp)
    elem_table.add{type='empty-widget', name='ssp_editor_pos_'..name..'_7'}
    buttons[7], buttons[8] = create_adjustment_buttons(elem_table, name, 'south', opp)
    return {adjustment=buttons, center={button}}
end
local function create_setting_flow(parent, name, tooltip)
    local flow = parent.add{type='flow', name='ssp_editor_settings_'..name..'_flow', direction='horizontal'}
    flow.style.vertical_align = 'center'
    flow.add{type='label', name='ssp_editor_settings_'..name..'_label',
             caption={'', {'gui-screenshot-editor.setting-'..name..'-label'}, tooltip and ' [img=info]' or ''},
             tooltip=tooltip and {'gui-screenshot-editor.setting-'..name..'-tooltip'} or nil}
    flow.add{type='empty-widget', name='ssp_editor_settings_'..name..'_filler', style='invisible_horizontal_filler'}
    return flow
end

local direction_to_delta = {north={x=0,y=-1}, east={x=1,y=0}, south={x=0,y=1}, west={x=-1,y=0}}
local direction_to_corner = {north='left_top', east='right_bottom', south='right_bottom', west='left_top'}
local type_to_switch_state = {picture='left', gif='right'}
local switch_state_to_type = {left='picture', right='gif'}

-- --------------------------------------------------
-- EVENT HANDLERS
-- All handlers are registered conditionally, and deregistered when the GUI is destroyed

local function reset_button_clicked(e)
    local player, player_table = util.get_player(e)
    player_table.current.settings = table.deepcopy(player_table.current.initial_settings)
    player_table.current.settings.area = table.deepcopy(player_table.current.initial_settings.area)
    editor_gui.update(player.index)
end

local function area_adjustment_pad_adjustment_button_clicked(e)
    local player, player_table = util.get_player(e)
    local area = player_table.current.settings.area
    local rectangle = player_table.current.rectangle
    -- get delta  from element name
    local direction = string.match(e.element.name, 'ssp_editor_pos_area_(.*)_out_button')
    local delta = direction_to_delta[direction]
    -- apply delta to area
    area.left_top = util.add_positions(area.left_top, delta)
    area.right_bottom = util.add_positions(area.right_bottom, delta)
    area = util.setup_area(area)
    rendering.set_left_top(rectangle, area.left_top)
    rendering.set_right_bottom(rectangle, area.right_bottom)
    editor_gui.update_reset_button(e)
end

local function edge_adjustment_pad_adjustment_button_clicked(e)
    local player, player_table = util.get_player(e)
    local area = player_table.current.settings.area
    local rectangle = player_table.current.rectangle
    -- get delta and corner to change from element name
    local direction, type = string.match(e.element.name, 'ssp_editor_pos_edge_(.*)_(.*)_button')
    local corner = direction_to_corner[direction]
    if type == 'in' then
        direction = util.oppositedirection_string[direction]
    end
    local delta = direction_to_delta[direction]
    -- apply delta to area
    area[corner] = util.add_positions(area[corner], delta)
    area = util.setup_area(area)
    rendering.set_left_top(rectangle, area.left_top)
    rendering.set_right_bottom(rectangle, area.right_bottom)
    editor_gui.update_reset_button(e)
end

local function area_adjustment_pad_center_button_clicked(e)
    util.debug_print(e)
end

local function edge_adjustment_pad_center_button_clicked(e)
    util.debug_print(e)
end

local function type_switch_state_changed(e)
    local player, player_table = util.get_player(e)
    local switch_state = e.element.switch_state
    local elems = player_table.gui.editor
    player_table.current.settings.type = switch_state_to_type[switch_state]
    if switch_state == 'left' then
        elems.gif_delay_textfield.enabled = false
        elems.gif_length_textfield.enabled = false
    else
        elems.gif_delay_textfield.enabled = true
        elems.gif_length_textfield.enabled = true
    end
    editor_gui.update_reset_button(e)
end

local function gif_delay_textfield_text_changed(e)
    util.textfield.clamp_number_input(e)
end

local function gif_delay_textfield_confirmed(e)
    local player, player_table = util.get_player(e)
    util.textfield.set_last_valid_value(e.element, player_table)
    player_table.current.settings.gif_delay = tonumber(e.element.text)
    editor_gui.update_reset_button(e)
end

local function gif_length_textfield_text_changed(e)
    util.textfield.clamp_number_input(e)
end

local function gif_length_textfield_confirmed(e)
    local player, player_table = util.get_player(e)
    util.textfield.set_last_valid_value(e.element, player_table)
    player_table.current.settings.gif_length = tonumber(e.element.text)
    editor_gui.update_reset_button(e)
end

local function name_textfield_text_changed(e)
    util.textfield.clamp_number_input(e)
end

local function name_textfield_confirmed(e)
    local player, player_table = util.get_player(e)
    util.textfield.set_last_valid_value(e.element, player_table)
    player_table.current.settings.filename = e.element.text
    editor_gui.update_reset_button(e)
end

local function extension_dropdown_selection_changed(e)
    local player, player_table = util.get_player(e)
    local selected_index = e.element.selected_index
    player_table.current.settings.extension = selected_index
    if selected_index == 1 then
        player_table.gui.editor.quality_textfield.enabled = true
    else
        player_table.gui.editor.quality_textfield.enabled = false
    end
    editor_gui.update_reset_button(e)
end

local function quality_textfield_text_changed(e)
    util.textfield.clamp_number_input(e)
end

local function quality_textfield_confirmed(e)
    local player, player_table = util.get_player(e)
    util.textfield.set_last_valid_value(e.element, player_table)
    player_table.current.settings.quality = tonumber(e.element.text)
    editor_gui.update_reset_button(e)
end

local function zoom_textfield_text_changed(e)
    util.textfield.clamp_number_input(e)
end

local function zoom_textfield_confirmed(e)
    local player, player_table = util.get_player(e)
    util.textfield.set_last_valid_value(e.element, player_table)
    player_table.current.settings.zoom = tonumber(e.element.text)
    editor_gui.update_reset_button(e)
end

local function alt_info_checkbox_state_changed(e)
    local player, player_table = util.get_player(e)
    player_table.current.settings.alt_info = e.element.checked_state
    editor_gui.update_reset_button(e)
end

local function antialias_checkbox_state_changed(e)
    local player, player_table = util.get_player(e)
    player_table.current.settings.antialias = e.element.checked_state
    editor_gui.update_reset_button(e)
end

local function preview_button_click(e)
    util.debug_print(e)
end

local function back_button_clicked(e)
    local player, player_table = util.get_player(e)
    rendering.destroy(player_table.current.rectangle)
    player_table.current = nil
    editor_gui.destroy(player_table.gui.editor.window, player.index)
end

local function confirm_button_clicked(e)
    local player, player_table = util.get_player(e)
    rendering.destroy(player_table.current.rectangle)
    editor_gui.destroy(player_table.gui.editor.window, player.index)
    confirm_button_handler(e)
    player_table.current = nil
end

local handlers = {
    editor_reset_button_clicked = reset_button_clicked,
    area_adjustment_pad_adjustment_button_clicked = area_adjustment_pad_adjustment_button_clicked,
    edge_adjustment_pad_adjustment_button_clicked = edge_adjustment_pad_adjustment_button_clicked,
    area_adjustment_pad_center_button_clicked = area_adjustment_pad_center_button_clicked,
    edge_adjustment_pad_center_button_clicked = edge_adjustment_pad_center_button_clicked,
    editor_type_switch_state_changed = type_switch_state_changed,
    editor_gif_delay_textfield_text_changed = gif_delay_textfield_text_changed,
    editor_gif_delay_textfield_confirmed = gif_delay_textfield_confirmed,
    editor_gif_length_textfield_text_changed = gif_length_textfield_text_changed,
    editor_gif_length_textfield_confirmed = gif_length_textfield_confirmed,
    editor_name_textfield_text_changed = name_textfield_text_changed,
    editor_name_textfield_confirmed = name_textfield_confirmed,
    editor_extension_dropdown_selection_changed = extension_dropdown_selection_changed,
    editor_quality_textfield_text_changed = quality_textfield_text_changed,
    editor_quality_textfield_confirmed = quality_textfield_confirmed,
    editor_zoom_textfield_text_changed = zoom_textfield_text_changed,
    editor_zoom_textfield_confirmed = zoom_textfield_confirmed,
    editor_alt_info_checkbox_state_changed = alt_info_checkbox_state_changed,
    editor_antialias_checkbox_state_changed = antialias_checkbox_state_changed,
    editor_preview_button_clicked = preview_button_clicked,
    editor_back_button_clicked = back_button_clicked,
    editor_confirm_button_clicked = confirm_button_clicked
}

-- pass handlers to event handler in case they need to be re-registered
event.on_load(function()
    event.load_conditional_events(handlers)
end)

-- --------------------------------------------------
-- LIBRARY

-- create the GUI and register conditional handlers
function editor_gui.create(parent, gui_pinned, player_index, default_settings, confirm_handler)
    local window = parent.add{type='frame', name='ssp_editor_window', style=gui_pinned and mod_gui.frame_style or 'dialog_frame', direction='vertical'}
    local titlebar = titlebar.create(window, 'ssp_editor_titlebar', {label={'gui-screenshot-editor.titlebar-label-caption'}, draggable= not gui_pinned})
    local content_frame = window.add{type='frame', name='ssp_editor_content_frame', style='window_content_frame_packed', direction='vertical'}
    content_frame.style.horizontally_stretchable = true    
    local toolbar = content_frame.add{type='frame', name='ssp_editor_toolbar', style='subheader_frame'}
    toolbar.style.horizontally_stretchable = true
    toolbar.add{type='empty-widget', name='ssp_editor_toolbar_filler', style='invisible_horizontal_filler'}
    -- toolbar.add{type='textfield', name='ssp_editor_toolbar_textfield'}
    local reset_button = toolbar.add{type='sprite-button', name='ssp_editor_toolbar_button', style='red_icon_button', sprite='utility/reset',
                                     tooltip={'gui.reset'}}
    reset_button.enabled = false
    event.gui.on_click({element={reset_button}}, reset_button_clicked, 'editor_reset_button_clicked', player_index)
    -- positioning
    local pos_frame = content_frame.add{type='frame', name='ssp_editor_pos_frame', style='ssp_bordered_frame', direction='vertical'}
    pos_frame.add{type='label', name='ssp_editor_pos_label', style='caption_label', caption={'gui-screenshot-editor.section-positioning-label'}}
    local pad_flow = pos_frame.add{type='flow', name='ssp_editor_pos_pad_flow', direction='horizontal'}
    local area_adjustment_pad = create_adjustment_pad(pad_flow, 'area', 'ssp-square', false)
    event.gui.on_click({element=area_adjustment_pad.adjustment}, area_adjustment_pad_adjustment_button_clicked, 'area_adjustment_pad_adjustment_button_clicked',
                       player_index)
    event.gui.on_click({element=area_adjustment_pad.center}, area_adjustment_pad_center_button_clicked, 'area_adjustment_pad_center_button_clicked',
                       player_index)
    local edge_adjustment_pad = create_adjustment_pad(pad_flow, 'edge', 'ssp-square-sides', true)
    event.gui.on_click({element=edge_adjustment_pad.adjustment}, edge_adjustment_pad_adjustment_button_clicked, 'edge_adjustment_pad_adjustment_button_clicked',
                       player_index)
    event.gui.on_click({element=edge_adjustment_pad.center}, edge_adjustment_pad_center_button_clicked, 'edge_adjustment_pad_center_button_clicked',
                       player_index)
    -- settings
    local settings_frame = content_frame.add{type='frame', name='ssp_editor_settings_frame', style='ssp_bordered_frame', direction='vertical'}
    settings_frame.style.top_margin = -2
    settings_frame.add{type='label', name='ssp_editor_settings_label', style='caption_label', caption={'gui-screenshot-editor.section-settings-label'}}
    local type_flow = create_setting_flow(settings_frame, 'type', false)
    local type_switch = type_flow.add{type='switch', name='ssp_editor_settings_type_switch', switch_state=type_to_switch_state[default_settings.type],
                                      left_label_caption={'gui-screenshot-editor.setting-type-picture-label'},
                                      right_label_caption={'', {'gui-screenshot-editor.setting-type-gif-label'}, ' [img=info]'},
                                      right_label_tooltip={'gui-screenshot-editor.setting-type-gif-tooltip'}}
    event.gui.on_switch_state_changed({element={type_switch}}, type_switch_state_changed, 'editor_type_switch_state_changed', player_index)
    local gif_delay_flow = create_setting_flow(settings_frame, 'gif-delay', true)
    local gif_delay_textfield = gif_delay_flow.add{type='textfield', name='ssp_editor_settings_gif_delay_textfield',
                                                           text=default_settings.gif_delay, lose_focus_on_confirm=true, clear_and_focus_on_right_click=true,
                                                           numeric=true, allow_decimal=false}
    gif_delay_textfield.style.width = 50
    gif_delay_textfield.style.horizontal_align = 'center'
    event.gui.on_text_changed({element={gif_delay_textfield}}, gif_delay_textfield_text_changed, 'editor_gif_delay_textfield_text_changed',
                              player_index)
    event.gui.on_confirmed({element={gif_delay_textfield}}, gif_delay_textfield_confirmed, 'editor_gif_delay_textfield_confirmed', player_index)
    local gif_length_flow = create_setting_flow(settings_frame, 'gif-length', false)
    local gif_length_textfield = gif_length_flow.add{type='textfield', name='ssp_editor_settings_gif_length_textfield', text=default_settings.gif_length,
                                                            lose_focus_on_confirm=true, clear_and_focus_on_right_click=true, numeric=true, allow_decimal=false}
    gif_length_textfield.style.width = 50
    gif_length_textfield.style.horizontal_align = 'center'
    event.gui.on_text_changed({element={gif_length_textfield}}, gif_length_textfield_text_changed, 'editor_gif_length_textfield_text_changed', player_index)
    event.gui.on_confirmed({element={gif_length_textfield}}, gif_length_textfield_confirmed, 'editor_gif_length_textfield_confirmed', player_index)
    local filename_flow = create_setting_flow(settings_frame, 'filename', false)
    local filename_textfield = filename_flow.add{type='textfield', name='ssp_editor_settings_filename_textfield', lose_focus_on_confirm=true,
                                                 clear_and_focus_on_right_click=true, text=default_settings.filename}
    filename_textfield.style.width = 160
    event.gui.on_text_changed({element={filename_textfield}}, name_textfield_text_changed, 'editor_name_textfield_text_changed', player_index)
    event.gui.on_confirmed({element={filename_textfield}}, name_textfield_confirmed, 'editor_name_textfield_confirmed', player_index)
    local extension_flow = create_setting_flow(settings_frame, 'extension', true)
    local extension_dropdown = extension_flow.add{type='drop-down', name='ssp_editor_settings_extension_dropdown', items={'.jpg', '.png', '.bmp'},
                                                  selected_index=default_settings.extension}
    extension_dropdown.style.width = 70
    event.gui.on_selection_state_changed({element={extension_dropdown}}, extension_dropdown_selection_changed, 'editor_extension_dropdown_selection_changed',
                                         player_index)
    local quality_flow = create_setting_flow(settings_frame, 'quality', true)
    local quality_textfield = quality_flow.add{type='textfield', name='ssp_editor_settings_quality_textfield', text=default_settings.jpeg_quality,
                                               lose_focus_on_confirm=true, clear_and_focus_on_right_click=true, numeric=true, allow_decimal=false}
    quality_textfield.style.width = 50
    quality_textfield.style.horizontal_align = 'center'
    if default_settings.extension ~= 1 then quality_textfield.enabled = false end
    event.gui.on_text_changed({element={quality_textfield}}, quality_textfield_text_changed, 'editor_quality_textfield_text_changed', player_index)
    event.gui.on_confirmed({element={quality_textfield}}, quality_textfield_confirmed, 'editor_quality_textfield_confirmed', player_index)
    local zoom_flow = create_setting_flow(settings_frame, 'zoom', true)
    local zoom_textfield = zoom_flow.add{type='textfield', name='ssp_editor_settings_zoom_textfield', text=default_settings.zoom,
                                         lose_focus_on_confirm=true, clear_and_focus_on_right_click=true, numeric=true, allow_decimal=true}
    zoom_textfield.style.width = 50
    zoom_textfield.style.horizontal_align = 'center'
    event.gui.on_text_changed({element={zoom_textfield}}, zoom_textfield_text_changed, 'editor_zoom_textfield_text_changed', player_index)
    event.gui.on_confirmed({element={zoom_textfield}}, zoom_textfield_confirmed, 'editor_zoom_textfield_confirmed', player_index)
    local checkboxes_flow = settings_frame.add{type='flow', name='ssp_editor_settings_checkboxes_flow', direction='horizontal'}
    local alt_info_checkbox = checkboxes_flow.add{type='checkbox', name='ssp_editor_settings_alt_info_checkbox',
                                                  caption={'gui-screenshot-editor.setting-alt-info-label'}, state=default_settings.show_alt_info}
    event.gui.on_checked_state_changed({element={alt_info_checkbox}}, alt_info_checkbox_state_changed, 'editor_alt_info_checkbox_state_changed', player_index)
    checkboxes_flow.add{type='empty-widget', name='ssp_editor_settings_checkboxes_filler', style='invisible_horizontal_filler'}
    local antialias_checkbox = checkboxes_flow.add{type='checkbox', name='ssp_editor_settings_antialias_checkbox',
                                                   caption={'', {'gui-screenshot-editor.setting-antialias-label'}, ' [img=info]'},
                                                   tooltip={'gui-screenshot-editor.setting-antialias-tooltip'}, state=default_settings.antialias}
    event.gui.on_checked_state_changed({element={antialias_checkbox}}, antialias_checkbox_state_changed, 'editor_antialias_checkbox_state_changed',
                                       player_index)
    -- preview button
    local preview_button = content_frame.add{type='button', name='ssp_editor_preview_button', caption='[img=utility/warning] Open preview'}
    preview_button.style.margin = 6
    preview_button.style.top_margin = 0
    preview_button.style.horizontally_stretchable = true
    event.gui.on_click({element={preview_button}}, preview_button_click, 'editor_preview_button_click', player_index)
    -- dialog buttons
    local dialog_buttons_flow = window.add{type='flow', name='ssp_editor_dialog_buttons_flow', style='dialog_buttons_horizontal_flow', direction='horizontal'}
    local back_button = dialog_buttons_flow.add{type='button', name='ssp_editor_dialog_discard_button', style='back_button', caption={'gui.cancel'}}
    event.gui.on_click({element={back_button}}, back_button_clicked, 'editor_back_button_clicked', player_index)
    local filler = dialog_buttons_flow.add{type='empty-widget', name='ssp_editor_dialog_filler', style='draggable_space'}
    filler.style.horizontally_stretchable = true
    if gui_pinned then dialog_buttons_flow.style.bottom_margin = 2
    else filler.style.vertically_stretchable = true end
    local confirm_button = dialog_buttons_flow.add{type='button', name='ssp_editor_dialog_confirm_button', style='confirm_button', caption={'gui.confirm'}}
    event.gui.on_click({element={confirm_button}}, confirm_button_clicked, 'editor_confirm_button_clicked', player_index)
    confirm_button_handler = confirm_handler
    return  {window=window, type_switch=type_switch, gif_delay_textfield=gif_delay_textfield, gif_length_textfield=gif_length_textfield,
             filename_textfield=filename_textfield, extension_dropdown=extension_dropdown, quality_textfield=quality_textfield,
             zoom_textfield=zoom_textfield, alt_info_checkbox=alt_info_checkbox, antialias_checkbox=antialias_checkbox, reset_button=reset_button},
            { -- textfield data
                ssp_editor_settings_filename_textfield={last_value=default_settings.filename},
                ssp_editor_settings_quality_textfield={last_value=default_settings.jpeg_quality, clamp_low=1, clamp_high=100},
                ssp_editor_settings_zoom_textfield={last_value=default_settings.zoom, clamp_low=0.01, clamp_high=2},
                ssp_editor_settings_gif_delay_textfield={last_value=default_settings.gif_delay, clamp_low=1},
                ssp_editor_settings_gif_length_textfield={last_value=default_settings.gif_length, clamp_low=1}
            }
end

-- enables / disables the reset button as needed
function editor_gui.update_reset_button(e)
    local player, player_table = util.get_player(e)
    local reset_button = player_table.gui.editor.reset_button
    local current = player_table.current
    if util.table_deep_compare(current.settings, current.initial_settings)
       and util.table_deep_compare(current.settings.area, current.initial_settings.area) then
        reset_button.enabled = false
    else
        reset_button.enabled = true
    end
end

local elem_to_setting_map = {
    gif_delay_textfield = {'text', 'gif_delay'},
    gif_length_textfield = {'text', 'gif_length'},
    filename_textfield = {'text', 'filename'},
    extension_dropdown = {'selected_index', 'extension'},
    quality_textfield = {'text', 'jpeg_quality'},
    zoom_textfield = {'text', 'zoom'},
    alt_info_checkbox = {'state', 'show_alt_info'},
    antialias_checkbox = {'state', 'antialias'}
}

-- updates the values of all modifiable elements and updates rectangle as well
function editor_gui.update(player_index)
    local player, player_table = util.get_player(player_index)
    local settings = player_table.current.settings
    local elems = player_table.gui.editor
    for n,t in pairs(elem_to_setting_map) do
        elems[n][t[1]] = settings[t[2]]
    end
    if elems.extension_dropdown.selected_index ~= 1 then
        elems.quality_textfield.enabled = false
    else
        elems.quality_textfield.enabled = true
    end
    elems.type_switch.switch_state = type_to_switch_state[settings.type]
    if elems.type_switch.switch_state == 'left' then
        elems.gif_delay_textfield.enabled = false
        elems.gif_length_textfield.enabled = false
    else
        elems.gif_delay_textfield.enabled = true
        elems.gif_length_textfield.enabled = true
    end
    editor_gui.update_reset_button{player_index=player_index}
    local rectangle = player_table.current.rectangle
    local area = player_table.current.settings.area
    rendering.set_left_top(rectangle, area.left_top)
    rendering.set_right_bottom(rectangle, area.right_bottom)
end

-- destroys the GUI and deregisters all handlers
function editor_gui.destroy(window, player_index)
    -- deregister all GUI events if needed
    local con_registry = global.conditional_event_registry
    for cn,h in pairs(handlers) do
        event.gui.deregister(con_registry[cn].id, h, cn, player_index)
    end
    window.destroy()
end

return editor_gui