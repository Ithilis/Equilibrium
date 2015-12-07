--mobile bomb

local oldXRL0302 = XRL0302
XRL0302 = Class(oldXRL0302) {

        OnStopBeingBuilt = function(self,builder,layer)
        CWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionInactive()
        self:SetScriptBit('RULEUTC_CloakToggle', true)
        self:RequestRefreshUI()
        end
}
TypeClass = XRL0302