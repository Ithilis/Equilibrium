--Aeon Submarine Hunter Script

local oldXAS0204 = XAS0204
XAS0204 = Class(oldXAS0204) {

    OnMotionVertEventChange = function( self, new, old )
        ASubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetMaintenanceConsumptionInactive()
        elseif new == 'Down' then
            self:SetMaintenanceConsumptionActive()
        end
    end,
    
    OnCreate = function(self)
        ASubUnit.OnCreate(self)
        self:SetMaintenanceConsumptionActive()
    end,
}

TypeClass = XAS0204