--****************************************************************************
--**
--**  File     :  /lua/SmartJamming.lua
--**  Author(s):  Exotic_Retard for Equilibrium Balance mod
--**
--**  Summary  :  File that refreshes jamming so its reset after scouting
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

function SmartJamming(SuperClass)
    return Class(SuperClass) {
        OnCreate = function(self)
            SuperClass.OnCreate(self)
        end,

        OnStopBeingBuilt = function(self,builder,layer)
            SuperClass.OnStopBeingBuilt(self,builder,layer)
            --set up a jamming delay, usually its fine but for some units might want to fine tune
            local bp = self:GetBlueprint()
            self.JammingDelay = bp.Intel.JammingDelay or 30
            
            self.JammingReset = self:ForkThread(self.WatchJamming)
        end,

        OnKilled = function(self, instigator, type, overkillRatio)
            SuperClass.OnKilled(self, instigator, type, overkillRatio)
        end,
        
        WatchJamming = function(self)
            while not self.Dead do
                if self:IsIntelEnabled('Jammer') then
                    self:DisableIntel('Jammer')
                    WaitSeconds(0.3) --need a delay to properly (and reliably) reset the jamming
                    self:EnableIntel('Jammer')
                end
                WaitSeconds(self.JammingDelay)
            end
        end,
    }    
end