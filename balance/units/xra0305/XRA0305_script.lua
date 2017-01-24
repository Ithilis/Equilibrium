--****************************************************************************
--**
--**  File     :  /cdimage/units/XRA0305/XRA0305_script.lua
--**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Cybran Heavy Gunship Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

oldCAirUnit = CAirUnit

XRA0305 = Class(oldCAirUnit) {
    OnStopBeingBuilt = function(self,builder,layer)
        oldCAirUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionInactive()
        self:SetScriptBit('RULEUTC_StealthToggle', true)
        self:RequestRefreshUI()
    end,
}
TypeClass = XRA0305