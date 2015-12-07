--Aeon Sniper Bot Script

local oldXAL0305 = XAL0305
XAL0305 = Class(oldXAL0305) {

    OnStopBeingBuilt = function(self,builder,layer)
        AWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionInactive()
        self:SetScriptBit('RULEUTC_StealthToggle', true)
        self:RequestRefreshUI()
    end,
}

TypeClass = XAL0305