--Cybran Spy Plane Script

local oldURA0302 = URA0302
URA0302 = Class(oldURA0302) {
    
    OnStopBeingBuilt = function(self,builder,layer)
        CAirUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionInactive()
        self:SetScriptBit('RULEUTC_StealthToggle', true)
        self:RequestRefreshUI()
    end,
}
TypeClass = URA0302