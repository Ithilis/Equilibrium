--Seaphim Submarine Hunter Script

local oldXSS0304 = XSS0304
XSS0304 = Class(oldXSS0304) {

    OnCreate = function(self)
        SSubUnit.OnCreate(self)
        self:SetMaintenanceConsumptionActive()
    end,
    
    OnMotionVertEventChange = function( self, new, old )
        SSubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetMaintenanceConsumptionInactive()
        elseif new == 'Down' then
            self:SetMaintenanceConsumptionActive()
        end
    end,

}
TypeClass = XSS0304