--UEF Strategic Missile Submarine Script

local oldUES0304 = UES0304
UES0304 = Class(oldUES0304) {

    OnCreate = function(self)
        TSubUnit.OnCreate(self)
        self:SetMaintenanceConsumptionActive()
    end,
}

TypeClass = UES0304

