--[[
Copyright (c) 2022, Nattack
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
    names of its contributors may be used to endorse or promote products
    derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

--[[
    Party Hints

    display images of a players class.
]]

_addon.name = "Party Hints"
_addon.author = "Nattack"
_addon.version = "0.1a"
_addon.commands = {"partyhints", "ph"}

config = require('config')
packets = require('packets')
res = require('resources')
images = require('images')
files = require('files')
require('tables')
require('sets')
require('functions')

require('icondb')
require('trusts')

defaults = {
    party_x_adjust = 0,
    party_y_adjust = 0,

    target_x_adjust = 0,
    target_y_adjust = 0,

    show_party_jobs = true,
    show_alliance_jobs = true,
    show_target_job = true,
    show_anon = true,
    show_unknown = false,
    show_self = true,
    show_last = true,
    show_trusts = true
}

--settings=config.load(defaults)
settings=defaults

-- initialize image objects
do
    local img_base = {
        color = {alpha = 255},
        texture = {fit = false},
        draggable = false,}
    local party_indices = {
        'p0','p1','p2','p3','p4','p5',
        'a10','a11','a12','a13','a14','a15',
        'a20','a21','a22','a23','a24','a25'}

    party_img = T{}
    target_img = images.new(img_base)
    for i,k in ipairs(party_indices) do
        party_img[k] = images.new(img_base)
    end
end

-- job registry is a key->value table/db of player name->jobs we have encountered this addon session
job_registry = T{}

party_count = 0
alliance1_count = 0
alliance2_count = 0


--[[ 
    set_registry
    Updates the job registry
    Does not update with 'NON' if the player already has a job in the registry

    arguments:
    name: string of the name of the player
    job_id: job index of the player

    return type: true if job is updated
]]
function set_registry(name, job_id)
    if not name then return false end
    job_registry[name] = job_registry[name] or 'NON'
    job_id = job_id or 0
    if res.jobs[job_id].english_short == 'NON' and job_registry[name] and not S{'NON', 'UNK'}:contains(job_registry[name]) then 
        return false
    end
    job_registry[name] = res.jobs[job_id].english_short
    return true
end

--[[
    get_registry
    Gets the players job from registry. 
    if the players name does not exist, return UNK

    arguments:
    name: string of the name of the player
    
    return type: 3 letter job code, or UNK for unknown, NON for anon
]]
function get_registry(name)
    if job_registry[name] then
        return job_registry[name]
    else
        return 'UNK'
    end
end

--[[
    update_party_icons
]]
function update_party_icons()
    if not settings.show_party_jobs then return end

    local pt = windower.ffxi.get_party()

    local function should_show_anon_state(name) return settings.show_anon or not S{'UNK','NON'}:contains(get_registry(name)) end
    local function should_show_alliance() return settings.show_alliance_jobs end
    local function should_show_self(index) return settings.show_self or (index ~= 1) end
    local function should_show_unknown(name) return settings.show_unknown or get_registry(name) ~= 'UNK' end
    local function should_show_last(index) return settings.show_last or (index ~= pt.party1_count) end
    
    local _path = windower.addon_path
    local p_indices = {'p0', 'p1', 'p2', 'p3', 'p4', 'p5'}
    local a1_indices = {'a10','a11','a12','a13','a14','a15'}
    local a2_indices = {'a20','a21','a22','a23','a24','a25'}

    local party_x_pos = windower.get_windower_settings().ui_x_res - (155 + settings.party_x_adjust * -1)
    local party_y_pos = windower.get_windower_settings().ui_y_res - (40 + settings.party_y_adjust * -1)
    local alliance1_y_pos = windower.get_windower_settings().ui_y_res - (295 + settings.party_y_adjust * -1)
    local alliance2_y_pos = windower.get_windower_settings().ui_y_res - (395 + settings.party_y_adjust * -1)
    local party_gap = 21
    local alliance_gap = 16

    for i,v in ipairs(p_indices) do
        -- draw party icons
        if i <= party_count
        and should_show_anon_state(pt[v].name)
        and should_show_unknown(pt[v].name)
        and should_show_self(i)
        and should_show_last(i) then
            party_img[p_indices[i]]:path(_path .. _icons.path_16px .. _icons._16px[get_registry(pt[v].name)])
            party_img[p_indices[i]]:transparency(0)
            party_img[p_indices[i]]:size(_icons.size_16px,_icons.size_16px)
            party_img[p_indices[i]]:pos_x(party_x_pos)
            party_img[p_indices[i]]:pos_y(party_y_pos-((party_count - i) * party_gap))
            party_img[p_indices[i]]:show()
        else
            party_img[p_indices[i]]:clear()
            party_img[p_indices[i]]:hide()
        end
    end
    for i,v in ipairs(a1_indices) do
        -- draw alliance 1 icons
        if i <= alliance1_count
        and should_show_anon_state(pt[v].name)
        and should_show_unknown(pt[v].name) 
        and should_show_alliance() then
            party_img[a1_indices[i]]:path(_path.._icons._16px[get_registry(pt[v].name)])
            party_img[a1_indices[i]]:transparency(0)
            party_img[a1_indices[i]]:size(_icons.size_16px,_icons.size_16px)
            party_img[a1_indices[i]]:pos_x(party_x_pos)
            party_img[a1_indices[i]]:pos_y(alliance1_y_pos + (i-1) * alliance_gap)
            party_img[a1_indices[i]]:show()
        else
            party_img[a1_indices[i]]:clear()
            party_img[a1_indices[i]]:hide()
        end
    end
    for i,v in ipairs(a2_indices) do
        -- draw alliance 2 icons
        if i <= alliance2_count
        and should_show_anon_state(pt[v].name)
        and should_show_unknown(pt[v].name)
        and should_show_alliance() then
            party_img[a2_indices[i]]:path(_path.._icons._16px[get_registry(pt[v].name)])
            party_img[a2_indices[i]]:transparency(0)
            party_img[a2_indices[i]]:size(_icons.size_16px,_icons.size_16px)
            party_img[a2_indices[i]]:pos_x(party_x_pos)
            party_img[a2_indices[i]]:pos_y(alliance2_y_pos + (alliance2_count - i) * alliance_gap)
            party_img[a2_indices[i]]:show()
        else
            party_img[a2_indices[i]]:clear()
            party_img[a2_indices[i]]:hide()
        end
    end
end

--[[
    update_target_icon
    updates the target image

    arguments:
    name:   string of name of the player
]]
function update_target_icon(name)
    local function should_show_anon_state(name)
        return settings.show_anon or not S{'NON','UNK'}:contains(get_registry(name))
    end

    local function should_show_unknown(name)
        return settings.show_unknown or not get_registry(name) == 'UNK'
    end

    if settings.show_target_job
    and not should_show_anon_state(name)
    and not should_show_unknown(name) then 
        target_img:clear()
        target_img:hide()
        return
    end

    local party_gap = 21
    local y_offset = (party_gap * (party_count-1))

    local target_x_pos = windower.get_windower_settings().ui_x_res - (165 + settings.target_x_adjust * -1)
    local target_y_pos = windower.get_windower_settings().ui_y_res - (89 + (settings.target_y_adjust * -1) + y_offset)
    
    --windower.add_to_chat(144, windower.addon_path .. _icons.path_32px .._icons._32px[get_registry(name)])
    target_img:path(windower.addon_path .. _icons.path_32px .._icons._32px[get_registry(name)])
    target_img:transparency(0)
    target_img:size(_icons.size_32px,_icons.size_32px)
    target_img:pos_x(target_x_pos)
    target_img:pos_y(target_y_pos)
    target_img:show()
end

--[[
    update

    updates all graphics
]]
function update()
    update_party_icons()
    target = windower.ffxi.get_mob_by_target('t')
    if target then
        update_target_icon(target.name)
    else
        target_img:clear()
        target_img:hide()
    end
end

--[[
    Event Driven Functions
]]
windower.register_event('incoming chunk', function(id,data)
    -- party update packet
    if id == 0x0DD then
        local p = packets.parse('incoming', data)
        set_registry(
            p['Name'],
            p['Main Job'])
        update()

    -- check packet
    elseif id == 0x0C9 then
        local p = packets.parse('incoming', data)
        set_registry(
            windower.ffxi.get_mob_by_index(p['Target Index']).name,
            p['Main Job'])
        update()

    -- possibly recieved when summoning trusts?
    -- elseif id == 0xE21 then
    --     update_party_icons()
    end
end)

windower.register_event('target change', function(index)
    -- if not index then return end
    local t = windower.ffxi.get_mob_by_index(index)
    if not t then
        target_img:clear()
        target_img:hide()
        return
    end

    if not t.is_npc then
        update_target_icon(t.name)
    -- elseif settings.show_trusts and t.is_npc and t.in_party then
    --     update_target_icon(t.name)
    else
        target_img:clear()
        target_img:hide()
    end
end)

windower.register_event('prerender', function()
    local pt_new = windower.ffxi.get_party_info()
    
    -- check party counts, if they change from what is known in memory, update them.
    -- should be a catch all for when trusts are summoned, or lost when zoning/dying.
    if pt_new.party1_count ~= party_count
    or pt_new.party2_count ~= alliance1_count
    or pt_new.party3_count ~= alliance2_count then
        party_count = pt_new.party1_count
        alliance1_count = pt_new.party2_count
        alliance2_count = pt_new.party3_count
        update()
    end
end)

windower.register_event('addon command', function(...)
    local args = T{...}
    local command = args[1] and args[1]:lower()
    
    local function write_to_chat(...)
        args = T{...}
        for i,v in pairs(args) do
            windower.add_to_chat(144,v)
        end
    end

    -- function get_party()
    --     local party_indices = {
    --         'p0','p1','p2','p3','p4','p5',
    --         'a10','a11','a12','a13','a14','a15',
    --         'a20','a21','a22','a23','a24','a25'}
        
    --     local pt = windower.ffxi.get_party()
    --     local pt_names = T{}
    --     for k,v in ipairs(party_indices) do
    --         pt_names.append(pt[v].name)
    --     end
    --     return pt_names
    -- end

    if command then
        if false then
        elseif command == 'update' then
            update()
        -- elseif command == 'list' then
        --     for k,v in pairs(job_registry) do
        --         windower.add_to_chat(144, k .. ':' .. v)
        --     end
        -- elseif command == 'export' then
        --     if not args[2] then
        --         -- export party information, in csv
        --         date = os.date('*t')
        --         name = windower.ffxi.get_player() and windower.ffxi.get_player().name
        --         local file = files.new('../../logs/ph_%s_%.4u.%.2u.%.2u.%.2u%2u.log':format(name,date.year,date.month,date.day,date.hour,date.min))
        --         if not file:exists() then
        --             file:create()
        --         end
                
        --         for k,v in ipairs(get_party()) do
        --             file.append('%s,%s\n':format(v,get_registry(v)))
        --         end
                
        --     elseif args[2] == 'all' then
        --         -- export party information, in csv
        --         date = os.date('*t')
        --         name = windower.ffxi.get_player() and windower.ffxi.get_player().name
        --         local file = files.new('../../logs/ph_all_%s_%.4u.%.2u.%.2u.%.2u%2u.log':format(name,date.year,date.month,date.day,date.hour,date.min))
        --         if not file:exists() then
        --             file:create()
        --         end
                
        --         for k,v in pairs(job_registry) do
        --             file.append('%s,%s\n':format(k,v))
        --         end
        --     end
        elseif S{'show', 'toggle'}:contains(command) then
            if not args[2] then
                write_to_chat("Partyhints: toggle subcommands:", " party, target, alliance, anon, unknown, self, last")
                return
            elseif args[2]:lower() == 'party' then
                settings.show_party_jobs = not settings.show_party_jobs
            elseif args[2]:lower() == 'target' then
                settings.show_target_job = not settings.show_target_job
            elseif args[2]:lower() == 'alliance' then
                settings.show_alliance_jobs = not settings.show_alliance_jobs
            elseif args[2]:lower() == 'anon' then
                settings.show_anon = not settings.show_anon
            elseif args[2]:lower() == 'unknown' then
                settings.show_unknown = not settings.show_unknown
            elseif args[2]:lower() == 'self' then
                settings.show_self = not settings.show_self
            elseif args[2]:lower() == 'last' then
                settings.show_last = not settings.show_last
            elseif S{'trust','trusts'}:contains(args[2]:lower()) then
                settings.show_trusts = not settings.show_trusts
            else
                write_to_chat(S{"unknown command: " .. args[2]})
            end
            update()
            --config.save(settings, windower.ffxi.get_player().name)

        elseif command == 'target' then
            if (not args[2] and not args[3]) then
                write_to_chat("Partyhints: target subcommands:",
                    " x [integer] - sets the offset of target x position",
                    " y [integer] - sets the offset of the target y position")
            elseif args[2] == 'x' then
                local n = tonumber(args[3])
                if type(n) == 'number' then settings.target_x_adjust = n end
            elseif args[2] == 'x' then
                local n = tonumber(args[3])
                if type(n) == 'number' then settings.target_y_adjust = n end
            end
            update()
            -- config.save(settings,windower.ffxi.get_player().name)

        elseif command == 'party' then
            if (not args[2] and not args[3]) then
                write_to_chat("Partyhints: party subcommands:",
                    " x [integer] - sets the offset of target x position",
                    " y [integer] - sets the offset of the target y position")
            elseif args[2] == 'x' then
                local n = tonumber(args[3])
                if type(n) == 'number' then settings.party_x_adjust = n end
            elseif args[2] == 'x' then
                local n = tonumber(args[3])
                if type(n) == 'number' then settings.party_y_adjust = n end
            end
            update()
            -- config.save(settings,windower.ffxi.get_player().name)

        elseif command == 'help' then   
            write_to_chat(
                'Usage: partyhints [command]',
                'valid options:',
                ' help - display this menu',
                -- ' list',
                -- ' export - exports the registry information to csv',
                --' export all - export everything in memory to csv',
                ' toggle [setting]',
                '  party - toggles showing of party jobs',
                '  target - toggles showing of target job',
                '  alliance - toggles showing of alliance jobs',
                '  anon - toggles showing of anon icon',
                '  unknown - toggles showing of jobs we don\'t yet know',
                '  self - toggles showing of own job',
                '  last - toggles showing of the last job'
            )
        end
    end
end)

-- populate your job on login, load, or job change
windower.register_event('login', function(name) set_registry(name, windower.ffxi.get_player().main_job_id) update() end)
windower.register_event('job change', function(main_job_id, main_job_level)
    set_registry(windower.ffxi.get_player().name, main_job_id)
    update()
end)
windower.register_event('load', function()
    -- dump trusts into job registry

    for k,v in ipairs(trusts) do
        set_registry(v.name, v.mjob)
    end

    if windower.ffxi.get_info().logged_in then
        local me = windower.ffxi.get_player()
        set_registry(me.name, me.main_job_id)
    end
    update()
end)