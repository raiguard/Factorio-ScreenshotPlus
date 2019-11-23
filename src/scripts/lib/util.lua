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

util.constants = {
    quick_shots_path = 'ScreenshotPlus/Quick shots/',
    timelapse_path = 'ScreenshotPlus/Timelapse/',
    debug_path = 'ScreenshotPlus/Debug/'
}

util.oppositedirection_string = {north='south', east='west', south='north', west='east'}

return util