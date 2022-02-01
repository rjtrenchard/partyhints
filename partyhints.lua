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
require('sets')
require('functions')

icons = require('icondb.lua')

defaults = {
    x_adjust = 0,
    y_adjust = 0,
    show_party_jobs = true,
    show_target_job = true
}


MP_job = S{'WHM','BLM','SCH','RDM','SMN','DRK','PLD','RUN','GEO','BLU'} -- jobs that use MP
Healer_job = S{'WHM', 'RDM', 'SCH'}
Caster_job = S{'BLM', 'SCH', 'RDM'} -- jobs that may cast magic damage
Melee_job = S{'WAR','MNK','THF','PLD','DRK','BST','BRD','SAM','NIN','DRG','BLU','PUP','DNC','RUN'} -- Jobs that may need haste
Ranged_job = S{'RNG','COR'} -- jobs that may use Flurry
Pet_job = S{'BST','DRG','PUP','SMN'} -- jobs that may benefit from pet buffs

job_types = S{'MP', 'Healer', 'Caster', 'Melee', 'Ranged', 'Pet'}


windower.register_event('load', function ()
    _pos_base = {-34, -389, -288}
    x_pos = windower.get_windower_settings().ui_x_res - (118 + x_adjust)
    y_pos = 0
end)

windower.register_event('prerender', function()
    -- do something!
    
end
)

local party={}
local alliance={}

function get_party_job()
    local _party = windower.ffxi.get_party()

end

function get_target_job(target)

end


