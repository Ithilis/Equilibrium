--UEF Attack Sub Script

local oldUES0203 = UES0203
UES0203 = Class(oldUES0203) {

    OnMotionVertEventChange = function( self, new, old )
        TSubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetMaintenanceConsumptionInactive()
        elseif new == 'Down' then
            self:SetMaintenanceConsumptionActive()
        end
    end,
    
    OnCreate = function(self)
        TSubUnit.OnCreate(self)
        self:SetMaintenanceConsumptionActive()
    end,
}

TypeClass = UES0203