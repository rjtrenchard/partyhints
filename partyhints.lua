--[[
Copyright (c) 2013, Nattack
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

    display images of a party members class type.
]]

_addon.name = "Party Hints"
_addon.author = "Nattack"
_addon.version = "0.1"
_addon.commands = {"partyhints"}

texts = require('texts')
config = require('config')
packets = require('packets')
res = require('resources')

require('icondb')
require('trusts')


defaults = {
    party_x_adjust = 0,
    party_y_adjust = 0,

    target_x_adjust = 0,
    target_y_adjust = 0,

    show_party_jobs = true,
    show_target_job = true
}

windower.register_event('load', function ()
    -- set base position data
    -- _pos_base = {-34, -389, -288}
    -- party_x_pos = windower.get_windower_settings().ui_x_res - (118 + party_x_adjust)
    -- party_y_pos = windower.get_windower_settings().ui_y_res - party_y_adjust

    -- target_x_pos = windower.get_windower_settings().ui_x_res - (118 + target_x_adjust)
    -- target_y_pos = windower.get_windower_settings().ui_y_res - (118 + target_y_adjust)

    -- set party count
    party={}
    alliance={}
    job_registry = {}
end)

--[[ 
    update_registry
    Update the job registry
    Does not update with 'NON' if the player already has a job in the registry

    name: string of the name of the player
    job_id: job index of the player
]]
function update_registry(name, job_id)
    job_registry[name] = job_registry[name] or 'NON'
    job_id = job_id or 0
    if res.jobs[job_id].english_short == 'NON' and job_registry[name] and job_registry[name] ~= 'NON' then 
        return 
    end
    job_registry[name] = res.jobs[job_id].english_short
end

--[[
    get_job_from_registry
    Safely gets the job from registry. 
    if the name does not exist, return UNK

    name: string of the name of the player
    return type: string
]]
function get_job_from_registry(name)
    job_registry[name] = job_registry[name] or 'UNK'
    return job_registry[name]
end

windower.register_event('incoming chunk', function(id,data)
    -- party update packet
    if id == 0x0DD then
        local p = packets.parse('incoming', data)
        update_registry(p['Name'], p['Main Job'])
        
    -- check packet
    elseif id == 0x0C9 then
        local p = packets.parse('incoming', data)
        t = windower.ffxi.get_mob_by_index(p["Target Index"])
        local job_id = p['Main Job']
        update_registry(t.name, job_id)
    end
end)

windower.register_event('target change', function(index)
    -- if not index then return end
    local t = windower.ffxi.get_mob_by_index(index)
    if not t then return end
    
end)

windower.register_event('addon command', function(arg)
    for k,v in pairs(job_registry) do
        windower.add_to_chat(144, k .. ',' .. v)
    end
end)