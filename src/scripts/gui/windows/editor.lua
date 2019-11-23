-- ----------------------------------------------------------------------------------------------------
-- EDITOR GUI
-- Comes up when a player selects an area for screenshotting. Lets one edit the area and screenshot settings.

local event = require('scripts/lib/event-handler')
local titlebar = require('scripts/gui/gui-elems/titlebar')
local mod_gui = require('mod-gui')
local util = require('scripts/lib/util')

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

-- --------------------------------------------------
-- EVENT HANDLERS
-- All handlers are registered conditionally, and deregistered when the GUI is destroyed

local function area_adjustment_pad_adjustment_button_click(e)
    local player, player_table = util.get_player(e)
    local area = player_table.current.area
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
end

local function edge_adjustment_pad_adjustment_button_click(e)
    local player, player_table = util.get_player(e)
    local area = player_table.current.area
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
end

local function area_adjustment_pad_center_button_click(e)
    util.debug_print(e)
end

local function edge_adjustment_pad_center_button_click(e)
    util.debug_print(e)
end

local function preview_button_click(e)
    util.debug_print(e)
end

local function name_textfield_text_changed(e)
    util.debug_print(e)
end

local function name_textfield_confirmed(e)
    util.debug_print(e)
end

local function extension_dropdown_selection_changed(e)
    util.debug_print(e)
end

local function quality_textfield_text_changed(e)
    util.debug_print(e)
end

local function quality_textfield_confirmed(e)
    util.debug_print(e)
end

local function zoom_textfield_text_changed(e)
    util.debug_print(e)
end

local function zoom_textfield_confirmed(e)
    util.debug_print(e)
end

local function alt_info_checkbox_state_changed(e)
    util.debug_print(e)
end

local function antialias_checkbox_state_changed(e)
    util.debug_print(e)
end

local function back_button_clicked(e)
    local player, player_table = util.get_player(e)
    rendering.destroy(player_table.current.rectangle)
    player_table.current = nil
    editor_gui.destroy(player_table.gui.editor.window, player.index)
end

local extensions_by_index = {'.jpg', '.png', '.bmp'}

local function confirm_button_clicked(e)
    local player, player_table = util.get_player(e)
    rendering.destroy(player_table.current.rectangle)
    editor_gui.destroy(player_table.gui.editor.window, player.index)
    -- take screenshot
    local area = player_table.current.area
    local settings = player_table.current.settings
    game.take_screenshot{
        player = player,
        by_player = player,
        surface = player.surface,
        position = area.center,
        resolution = {x=area.width*settings.zoom*32, y=area.height*settings.zoom*32},
        zoom = settings.zoom,
        path = 'ScreenshotPlus/'..settings.filename..extensions_by_index[settings.extension],
        quality = settings.jpeg_quality,
        show_alt_info = settings.show_alt_info,
        anti_alias = settings.antialias,
        show_gui = false
    }
end

local handlers = {
    area_adjustment_pad_adjustment_button_click = area_adjustment_pad_adjustment_button_click,
    edge_adjustment_pad_adjustment_button_click = edge_adjustment_pad_adjustment_button_click,
    area_adjustment_pad_center_button_click = area_adjustment_pad_center_button_click,
    edge_adjustment_pad_center_button_click = edge_adjustment_pad_center_button_click,
    editor_preview_button_click = preview_button_click,
    editor_name_textfield_text_changed = name_textfield_text_changed,
    editor_name_textfield_confirmed = name_textfield_confirmed,
    editor_extension_dropdown_selection_changed = extension_dropdown_selection_changed,
    editor_quality_textfield_text_changed = quality_textfield_text_changed,
    editor_quality_textfield_confirmed = quality_textfield_confirmed,
    editor_zoom_textfield_text_changed = zoom_textfield_text_changed,
    editor_zoom_textfield_confirmed = zoom_textfield_confirmed,
    editor_alt_info_checkbox_state_changed = alt_info_checkbox_state_changed,
    editor_antialias_checkbox_state_changed = antialias_checkbox_state_changed,
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
function editor_gui.create(parent, gui_pinned, player_index, default_settings)
    local window = parent.add{type='frame', name='ssp_editor_window', style=gui_pinned and mod_gui.frame_style or 'dialog_frame', direction='vertical'}
    local titlebar = titlebar.create(window, 'ssp_editor_titlebar', {label={'gui-screenshot-editor.titlebar-label-caption'}, draggable= not gui_pinned})
    local content_frame = window.add{type='frame', name='ssp_editor_content_frame', style='window_content_frame_packed', direction='vertical'}
    content_frame.style.horizontally_stretchable = true    
    local toolbar = content_frame.add{type='frame', name='ssp_editor_toolbar', style='subheader_frame'}
    toolbar.style.horizontally_stretchable = true
    toolbar.add{type='empty-widget', name='ssp_editor_toolbar_filler', style='invisible_horizontal_filler'}
    -- toolbar.add{type='textfield', name='ssp_editor_toolbar_textfield'}
    toolbar.add{type='sprite-button', name='ssp_editor_toolbar_button', style='red_icon_button', sprite='utility/reset'}.enabled = false
    -- positioning
    local pos_frame = content_frame.add{type='frame', name='ssp_editor_pos_frame', style='ssp_bordered_frame', direction='vertical'}
    pos_frame.add{type='label', name='ssp_editor_pos_label', style='caption_label', caption={'gui-screenshot-editor.section-positioning-label'}}
    local pad_flow = pos_frame.add{type='flow', name='ssp_editor_pos_pad_flow', direction='horizontal'}
    local area_adjustment_pad = create_adjustment_pad(pad_flow, 'area', 'ssp-square', false)
    event.gui.on_click({element=area_adjustment_pad.adjustment}, area_adjustment_pad_adjustment_button_click, 'area_adjustment_pad_adjustment_button_click',
                       player_index)
    event.gui.on_click({element=area_adjustment_pad.center}, area_adjustment_pad_center_button_click, 'area_adjustment_pad_center_button_click', player_index)
    local edge_adjustment_pad = create_adjustment_pad(pad_flow, 'edge', 'ssp-square-sides', true)
    event.gui.on_click({element=edge_adjustment_pad.adjustment}, edge_adjustment_pad_adjustment_button_click, 'edge_adjustment_pad_adjustment_button_click',
                       player_index)
    event.gui.on_click({element=edge_adjustment_pad.center}, edge_adjustment_pad_center_button_click, 'edge_adjustment_pad_center_button_click', player_index)
    -- settings
    local settings_frame = content_frame.add{type='frame', name='ssp_editor_settings_frame', style='ssp_bordered_frame', direction='vertical'}
    settings_frame.style.top_margin = -2
    settings_frame.add{type='label', name='ssp_editor_settings_label', style='caption_label', caption={'gui-screenshot-editor.section-settings-label'}}
    local filename_flow = create_setting_flow(settings_frame, 'filename', false)
    local filename_textfield = filename_flow.add{type='textfield', name='ssp_editor_settings_filename_textfield', style='long_number_textfield',
                                                 lose_focus_on_confirm=true, clear_and_focus_on_right_click=true, text=default_settings.filename}
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
                                               lose_focus_on_confirm=true, clear_and_focus_on_right_click=true}
    quality_textfield.style.width = 50
    quality_textfield.style.horizontal_align = 'center'
    event.gui.on_text_changed({element={quality_textfield}}, quality_textfield_text_changed, 'editor_quality_textfield_text_changed', player_index)
    event.gui.on_confirmed({element={quality_textfield}}, quality_textfield_confirmed, 'editor_quality_textfield_confirmed', player_index)
    local zoom_flow = create_setting_flow(settings_frame, 'zoom', true)
    local zoom_textfield = zoom_flow.add{type='textfield', name='ssp_editor_settings_zoom_textfield', text=default_settings.zoom,
                                         lose_focus_on_confirm=true, clear_and_focus_on_right_click=true}
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
    return {window=window, filename_textfield=filename_textfield, extension_dropdown=extension_dropdown, quality_textfield=quality_textfield,
            zoom_textfield=zoom_textfield, alt_info_checkbox=alt_info_checkbox, antialias_checkbox=antialias_checkbox}
end

function editor_gui.update_reset_button()

end

function editor_gui.update()

end

function editor_gui.refresh()

end

function editor_gui.destroy(window, player_index)
    -- deregister all GUI events if needed
    local con_registry = global.conditional_event_registry
    for cn,h in pairs(handlers) do
        event.gui.deregister(con_registry[cn].id, h, cn, player_index)
    end
    window.destroy()
end

return editor_gui