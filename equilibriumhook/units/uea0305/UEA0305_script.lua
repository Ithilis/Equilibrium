--UEF Heavy Gunship Script
local SmartJamming = import('/lua/SmartJamming.lua').SmartJamming --import our jamming code


local oldUEA0305 = UEA0305
oldUEA0305 = SmartJamming( oldUEA0305 )--inject our jamming code here, so it refreshes properly

UEA0305 = Class(oldUEA0305) {

    OnStopBeingBuilt = function(self,builder,layer)
        oldUEA0305.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive() -- added by Ithilis
    end,

}
TypeClass = UEA0305