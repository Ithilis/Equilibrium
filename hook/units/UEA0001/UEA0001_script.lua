-----------------------------------------------------------------
-- File     :  /cdimage/units/UEA0001/UEA0001_script.lua
-- Author(s):  John Comes
-- Summary  :  UEF CDR Pod Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TConstructionUnit = import('/lua/terranunits.lua').TConstructionUnit
local EffectUtilities = import('/lua/EffectUtilities.lua')

local oldUEA0001 = UEA0001

UEA0001 = Class(oldUEA0001) {
    UpdateBuildRate = function(self, parenttechlevel)
        -- change the build rate of the pod based on the acus tech level upgrades.
        -- the acu script calls it on tech upgrade on drone build and rebuild
        if parenttechlevel ==  2 then
            self:SetBuildRate(10)
        elseif parenttechlevel ==  3 then
            self:SetBuildRate(20)
        else
            self:SetBuildRate(5)
        end
        
        
        self.MakeUpgFx = self:ForkThread(self.CreateUpgradeEffects)
    end,
    
    CreateUpgradeEffects = function(self) --shows that shits going down with the drone as well.
        local effects = TrashBag()
        EffectUtilities.CreateEnhancementEffectAtBone(self, 0, effects )
        EffectUtilities.CreateEnhancementUnitAmbient(self, 0, effects )
        local scale = 0.5
        for _, e in effects do
            e:ScaleEmitter(scale)
            self.UpgradeEffectsBag:Add(e)
        end
        WaitSeconds(1)
        if self.UpgradeEffectsBag then
            self.UpgradeEffectsBag:Destroy()
        end
    end,
}

TypeClass = UEA0001
