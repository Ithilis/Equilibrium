--Aeon Attack Sub Script

local oldUAS0203 = UAS0203
UAS0203 = Class(oldUAS0203) {

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

TypeClass = UAS0203