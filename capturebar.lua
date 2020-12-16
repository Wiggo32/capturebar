_addon.name = 'capturebar'
_addon.author = 'infobar-Kenshi'
_addon.version = '1.0'
_addon.commands = {'cb', 'capturebar'}

config = require('config')
texts = require('texts')
require('vectors')
res = require('resources')

defaults = {}
defaults.NoTarget = "[${zone_number}]${zone_name} - ${name} (${x},${z},${y}) R(${player_rot}) (${main_job}${main_job_level}/${sub_job}${sub_job_level}) Moon: ${game_moon_pct} ${game_moon}"
defaults.TargetPC = "[${zone_number}]${zone_name} - ${name} (${x},${z},${y}) R(${player_rot}) (${main_job}${main_job_level}/${sub_job}${sub_job_level}) Moon: ${game_moon_pct} ${game_moon}"
defaults.TargetNPC = "[${zone_number}]${zone_name} - ${name} (${x},${z},${y}) R(${facing_rot}) (${main_job}${main_job_level}/${sub_job}${sub_job_level}) Moon: ${game_moon_pct} ${game_moon}"
defaults.TargetMOB = "[${zone_number}]${zone_name} - ${name} (${x},${z},${y}) R(${facing_rot}) (${main_job}${main_job_level}/${sub_job}${sub_job_level}) Moon: ${game_moon_pct} ${game_moon}"
defaults.display = {}
defaults.display.pos = {}
defaults.display.pos.x = 20  -- 1280x720 display
-- defaults.display.pos.x = 0  -- 800x600 display
defaults.display.pos.y = 0
defaults.display.bg = {}
defaults.display.bg.red = 0
defaults.display.bg.green = 0
defaults.display.bg.blue = 0
defaults.display.bg.alpha = 127
defaults.display.text = {}
defaults.display.text.font = 'Arial'
defaults.display.text.red = 255
defaults.display.text.green = 255
defaults.display.text.blue = 255
defaults.display.text.alpha = 255
defaults.display.text.size = 12

settings = config.load(defaults)

box = texts.new("", settings.display, settings)

local capturebar = {}
capturebar.new_line = '\n'

windower.register_event('load',function()
    if not windower.ffxi.get_info().logged_in then return end
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or windower.ffxi.get_player()
    get_target(target.index)
end)

function getPlayerRot(value)
    local plrRot = math.round(256 / math.tau * value)
        if plrRot < 0 then
            plrRot = plrRot + 256
        end
    return plrRot
end

function getRot(value)
    return math.round(256 / math.tau * value)
end

function get_target(index)
    local player = windower.ffxi.get_player()
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or player
    capturebar.name = target.name
    capturebar.id = target.id
    capturebar.index = target.index
    if index == 0 then
        capturebar.main_job = player.main_job
        capturebar.main_job_level = player.main_job_level
        capturebar.sub_job = player.sub_job
        capturebar.sub_job_level = player.sub_job_level
        box:color(255,255,255)
        box:bold(false)
        box:text(settings.NoTarget)
    else
        if target.spawn_type == 13 or target.spawn_type == 14 or target.spawn_type == 9 or target.spawn_type == 1 then
            box:bold(false)
            if target.spawn_type == 1 then
                box:color(255,255,255)
            else
                box:color(128,255,255)
            end
            box:text(settings.TargetPC)
        elseif target.spawn_type == 2 or target.spawn_type == 34 then
            box:color(128,255,128)
            box:text(settings.TargetNPC)
            box:bold(false)
        elseif target.spawn_type == 16 then
            local zone = res.zones[windower.ffxi.get_info().zone].name
            box:color(255,255,128)
            box:text(settings.TargetMOB)
        end
    end
    box:update(capturebar)
end

windower.register_event('incoming chunk',function(id,org,modi,is_injected,is_blocked)
    if id == 0xB then
        zoning_bool = true
    elseif id == 0xA then
        zoning_bool = false
    end
end)

windower.register_event('prerender', function()
    local info = windower.ffxi.get_info()
    
    if not info.logged_in or not windower.ffxi.get_player() or zoning_bool then
        box:hide()
        return
    end

-- corrected because windower moon phase resource is wrong
    if info.moon_phase < 6 then
        if info.moon >= 0 and info.moon < 7 then
            capturebar.game_moon = 'New Moon'
        elseif info.moon >= 7 and info.moon < 40 then
            capturebar.game_moon = 'Waxing Crescent'
        elseif info.moon >= 40 and info.moon < 57 then
            capturebar.game_moon = 'First Quarter'
        elseif info.moon >= 57 and info.moon < 90 then
            capturebar.game_moon = 'Waxing Gibbous'
        elseif info.moon >= 90 and info.moon <= 100 then
            capturebar.game_moon = 'Full Moon'
        end
    elseif info.moon_phase >= 6 then
        if info.moon >= 0 and info.moon < 12 then
            capturebar.game_moon = 'New Moon'
        elseif info.moon >= 12 and info.moon < 43 then
            capturebar.game_moon = 'Waning Crescent'
        elseif info.moon >= 43 and info.moon < 62 then
            capturebar.game_moon = 'Last Quarter'
        elseif info.moon >= 62 and info.moon < 95 then
            capturebar.game_moon = 'Waning Gibbous'
        elseif info.moon >= 95 and info.moon <= 100 then
            capturebar.game_moon = 'Full Moon'
        end
    end

    capturebar.game_moon_pct = info.moon..'%'
    capturebar.zone_name = res.zones[info.zone].name
    capturebar.zone_number = info.zone

    local pos = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or windower.ffxi.get_mob_by_target('me')
    if not pos then return end
    capturebar.x = string.format('%0.3f', pos.x)
    capturebar.y = string.format('%0.3f', pos.y)
    capturebar.z = string.format('%0.3f', pos.z)
    capturebar.facing_rot = getRot(pos.facing)
    capturebar.player_rot = getPlayerRot(pos.facing)

    box:update(capturebar)
    box:show()
end)

windower.register_event('target change', get_target)
windower.register_event('job change', function()
    get_target(windower.ffxi.get_player().index)
end)