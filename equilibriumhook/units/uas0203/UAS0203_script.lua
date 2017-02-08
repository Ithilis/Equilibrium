--****************************************************************************
--**
--**  File     :  /cdimage/units/uas0203/uas0203_script.lua
--**  Author(s):  John Comes, Jessica St. Croix
--**
--**  Summary  :  Aeon Attack Sub Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ASubUnit = import('/lua/aeonunits.lua').ASubUnit
local AANChronoTorpedoWeapon = import('/lua/aeonweapons.lua').AANChronoTorpedoWeapon

oldASubUnit = ASubUnit

UAS0203 = Class(oldASubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        Torpedo01 = Class(AANChronoTorpedoWeapon) {},
    },
    
    OnMotionVertEventChange = function( self, new, old )
        oldASubUnit.OnMotionVertEventChange( self, new, old )
        local army = self:GetArmy()
        if new == 'Down' or new == 'Bottom' then
            
            -- Set the vision radius back to default
            local bpVision = self:GetBlueprint().Intel.VisionRadius or 0
            self:SetIntelRadius('Vision', bpVision)
        elseif new == 'Top' then
            -- While surfaced, the aeon sub can see 3 times as far
            local vis = (self:GetBlueprint().Intel.VisionRadius * 3) or 0
            self:SetIntelRadius('Vision', vis)
        end
    end,
    
}

TypeClass = UAS0203