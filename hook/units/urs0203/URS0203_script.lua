--Cybran Attack Sub Script

local oldURS0203 = URS0203
URS0203 = Class(oldURS0203) {

    OnMotionVertEventChange = function( self, new, old )
        CSubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetMaintenanceConsumptionInactive()
        elseif new == 'Down' then
            self:SetMaintenanceConsumptionActive()
        end
    end,
    
    OnCreate = function(self)
        CSubUnit.OnCreate(self)
        self:SetMaintenanceConsumptionActive()
    end,
}

TypeClass = URS0203