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
require('tables')

require('icondb')
require('trusts')

defaults = {
    party_x_adjust = 0,
    party_y_adjust = 0,

    target_x_adjust = 0,
    target_y_adjust = 0,

    show_party_jobs = true,
    show_target_job = true,
    show_anon = true,
    show_self = true
}

settings=config.load(defaults)
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
job_registry = {}

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
    update_party
    Updates party icons
]]
function update_party()
    if not settings.show_party_jobs then return end
    
    local function should_show_anon_state(name) 
        return settings.show_anon or not S{'UNK','NON'}:contains(get_registry(name))
    end

    local function should_show_self(i)
        return (not settings.show_self and i == 0) or settings.show_self
    end

    pt = windower.ffxi.get_party_info()
    
    local _path = windower.windower_path .. windower.addon_path
    local p_indices = {'p0', 'p1', 'p2', 'p3', 'p4', 'p5'}
    local a1_indices = {'a10','a11','a12','a13','a14','a15'}
    local a2_indices = {'a20','a21','a22','a23','a24','a25'}

    local party_x_pos = windower.get_windower_settings().ui_x_res - (118 + party_x_adjust)
    local party_y_pos = windower.get_windower_settings().ui_y_res - (50 + party_y_adjust)
    local alliance1_y_pos = windower.get_windower_settings().ui_y_res - (100 + party_y_adjust)
    local alliance2_y_pos = windower.get_windower_settings().ui_y_res - (200 + party_y_adjust)
    local party_gap = 20
    local alliance_gap = 16
    
    -- TODO: condense this into a function?
    for i = 0, 5 do
        -- party
        if i+1 <= pt.party1_count 
        and should_show_anon_state(pt[p_indices[i]].name) 
        and should_show_self(i) then
            party_img[p_indices[i]]:path(_path.._icons._16px[get_registry(pt[p_indices[i]].name)])
            party_img[p_indices[i]]:transparency(0)
            party_img[p_indices[i]]:size(_icons.size_16px,_icons.size_16px)
            party_img[p_indices[i]]:pos_x(party_x_pos)
            party_img[p_indices[i]]:pos_y(party_y_pos+i*party_gap)
            party_img[p_indices[i]]:show()
        else
            party_img[p_indices[i]]:clear()
            party_img[p_indices[i]]:hide()
        end

        -- alliance 1
        if i+1 <= pt.party2_count and should_show_anon_state(pt[a1_indices[i]].name) then
            party_img[a1_indices[i]]:path(_path.._icons._16px[get_registry(pt[a1_indices[i].name])])
            party_img[a1_indices[i]]:transparency(0)
            party_img[a1_indices[i]]:size(_icons.size_16px,_icons.size_16px)
            party_img[a1_indices[i]]:pos_x(party_x_pos)
            party_img[a1_indices[i]]:pos_y(alliance1_y_pos+i*alliance_gap)
            party_img[a1_indices[i]]:show()
        else
            party_img[a1_indices[i]]:clear()
            party_img[a1_indices[i]]:hide()
        end

        -- alliance 2
        if i+1 <= pt.party3_count and should_show_anon_state(pt[a2_indices[i]].name) then
            party_img[a2_indices[i]]:path(_path.._icons._16px[get_registry(pt[a2_indices[i].name])])
            party_img[a2_indices[i]]:transparency(0)
            party_img[a2_indices[i]]:size(_icons.size_16px,_icons.size_16px)
            party_img[a2_indices[i]]:pos_x(party_x_pos)
            party_img[a2_indices[i]]:pos_y(alliance2_y_pos + i*alliance_gap)
            party_img[a2_indices[i]]:show()
        else
            party_img[a2_indices[i]]:clear()
            party_img[a2_indices[i]]:hide()
        end
    end
end

--[[
    update_target
    updates the target image

    arguments:
    name:   string of name of the player
]]
function update_target(name)
    
    if not settings.show_target_job then return end
    if not settings.show_anon and S{'NON','UNK'}:contains(get_registry(name)) then return end
    local target_x_pos = windower.get_windower_settings().ui_x_res - (118 + settings.target_x_adjust)
    local target_y_pos = windower.get_windower_settings().ui_y_res - (118 + settings.target_y_adjust)

    
    windower.add_to_chat(144, windower.addon_path .. _icons.path_32px .._icons._32px[get_registry(name)])
    target_img:path(windower.addon_path .. _icons.path_32px .._icons._32px[get_registry(name)])
    target_img:transparency(0)
    target_img:size(_icons.size_32px,_icons.size_32px)
    target_img:pos_x(target_x_pos)
    target_img:pos_y(target_y_pos)
    target_img:show()
end

windower.register_event('incoming chunk', function(id,data)
    -- party update packet
    if id == 0x0DD then
        local p = packets.parse('incoming', data)
        set_registry(
            p['Name'],
            p['Main Job'])
        update_party()

    -- check packet
    elseif id == 0x0C9 then
        local p = packets.parse('incoming', data)
        set_registry(
            windower.ffxi.get_mob_by_index(p['Target Index']).name,
            p['Main Job'])
        if windower.ffxi.get_mob_by_target('t') then 
            update_target(windower.ffxi.get_mob_by_index(p['Target Index']).name)
        end
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
        update_target(t.name)
    else
        target_img:clear()
        target_img:hide()
    end
    -- TODO: show trust job
    -- elseif t.is_npc then
    --     for i,trust in trusts:it() do
    --         if trust.name == t.name then
    --             -- show trust job?
    --             break
    --         end
    --     end
    -- end
end)

windower.register_event('addon command', function(...)
    local args = T{...}
    local command = args[1] and args[1]:lower()

    local function write_to_chat(to_write)
        for i,v in ipairs(to_write) do
            windower.add_to_chat(144,v)
        end
    end

    if command then
        if command == 'list' then
            for k,v in pairs(job_registry) do
                windower.add_to_chat(144, k .. ':' .. v)
            end
        elseif command == 'export' then
            if not args[2] then
                -- export party information, in csv
            elseif args[2] == 'all' then
                -- export entire registry
            end
        elseif command == 'toggle' then
            if not args[2] then return
            elseif args[2].lower() == 'party' then
                -- toggle display of party members
            elseif args[2].lower() == 'target' then
                -- toggle display of target
            end
        end
    else
        write_to_chat(S{
            'Usage: partyhints [command]',
            'valid options:',
            ' list',
            ' export - exports the party information to csv',
            ' export all - export everything in memory to csv',
            ' toggle [setting]',
            '  party - toggles showing of party jobs',
            '  target - toggles showing of target job',
            '  anon - toggles showing of anon icon'

        })
    end
end)

-- populate your job on login, load, or job change
windower.register_event('login', function(name) set_registry(name, windower.ffxi.get_player().main_job_id) end)
windower.register_event('job change', function(main_job_id, main_job_level) set_registry(windower.ffxi.get_player().name, main_job_id) end)
windower.register_event('load', function()
    if windower.ffxi.get_info().logged_in then
        local me = windower.ffxi.get_player()
        set_registry(me.name, me.main_job_id)
    end
end)