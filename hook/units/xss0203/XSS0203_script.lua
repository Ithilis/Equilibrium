--Seraphim Attack Sub Script

local oldXSS0203 = XSS0203
XSS0203 = Class(oldXSS0203) {

    OnMotionVertEventChange = function( self, new, old )
        SSubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetMaintenanceConsumptionInactive()
        elseif new == 'Down' then
            self:SetMaintenanceConsumptionActive()
        end
    end,
    
    OnCreate = function(self)
        SSubUnit.OnCreate(self)
        self:SetMaintenanceConsumptionActive()
    end,
    
}
TypeClass = XSS0203