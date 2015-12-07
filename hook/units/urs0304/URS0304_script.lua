--Cybran Strategic Missile Submarine Script

local oldURS0304 = URS0304
URS0304 = Class(oldURS0304) {

    OnStopBeingBuilt = function(self, builder, layer)
        CSubUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

}

TypeClass = URS0304