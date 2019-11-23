local math2d = require('math2d')
local util = require('__core__/lualib/util')

function util.get_player(obj)
    if type(obj) == 'number' then return game.players[obj], global.players[obj]
    else return game.players[obj.player_index], global.players[obj.player_index] end
end

function util.setup_area(area)
    return {
        left_top = area.left_top,
        right_bottom = area.right_bottom,
        center = math2d.bounding_box.get_centre(area),
        width = area.right_bottom.x - area.left_top.x,
        height = area.right_bottom.y - area.left_top.y
    }
end

function util.add_positions(pos1, pos2)
    return {x=pos1.x+pos2.x, y=pos1.y+pos2.y}
end

function util.debug_print(e)
    print(serpent.block(e))
end

-- borrowed from STDLIB: compares two tables for inner equality
function util.table_deep_compare(t1, t2, ignore_mt)
    local ty1, ty2 = type(t1), type(t2)
    if ty1 ~= ty2 then
        return false
    end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then
        return t1 == t2
    end
    -- as well as tables which have the metamethod __eq
    if not ignore_mt then
        local mt = getmetatable(t1)
        if mt and mt.__eq then
            return t1 == t2
        end
    end
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not util.table_deep_compare(v1, v2) then
            return false
        end
    end
    for k in pairs(t2) do
        if t1[k] == nil then
            return false
        end
    end

    return true
end

util.textfield = {}

function util.textfield.clamp_number_input(e)
    local player, player_table = util.get_player(e)
    local textfield_data = player_table.gui.textfields[e.element.name]
    local text = e.element.text
    if text == ''
    or (textfield_data.clamp_low and tonumber(text) < textfield_data.clamp_low)
    or (textfield_data.clamp_high and tonumber(text) > textfield_data.clamp_high) then
        e.element.style = 'invalid_short_number_textfield'
        return false
    else
        e.element.style = 'textbox'
        textfield_data.last_value = text
        return true
    end
end

function util.textfield.set_last_valid_value(element, player_table)
    local textfield_data = player_table.gui.textfields[element.name]
    if element.text ~= textfield_data.last_value then
        element.text = textfield_data.last_value
        element.style = 'textbox'
    end
end

util.constants = {
    quick_shots_path = 'ScreenshotPlus/Quick shots/',
    timelapse_path = 'ScreenshotPlus/Timelapse/',
    debug_path = 'ScreenshotPlus/Debug/'
}

util.oppositedirection_string = {north='south', east='west', south='north', west='east'}

return util