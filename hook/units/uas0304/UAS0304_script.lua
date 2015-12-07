--Aeon Strategic Missile Submarine

local oldUAS0304 = UAS0304
UAS0304 = Class(oldUAS0304) {

    OnCreate = function(self)
        ASubUnit.OnCreate(self)
        self:SetMaintenanceConsumptionActive()
    end,
}

TypeClass = UAS0304

