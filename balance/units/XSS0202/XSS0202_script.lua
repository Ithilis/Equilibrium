#****************************************************************************
#**
#**  File     :  /units/XSS0202/XSS0202_script.lua
#**  Author(s):  Drew Staltman, Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Seraphim Cruiser Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SeraphimWeapons = import('/lua/seraphimweapons.lua')
--local SSeaUnit = import('/lua/seraphimunits.lua').SSeaUnit
local SSubUnit = import('/lua/seraphimunits.lua').SSubUnit
local SLaanseMissileWeapon = SeraphimWeapons.SLaanseMissileWeapon
local SAAOlarisCannonWeapon = SeraphimWeapons.SAAOlarisCannonWeapon
local SAAShleoCannonWeapon = SeraphimWeapons.SAAShleoCannonWeapon
local SAMElectrumMissileDefense = SeraphimWeapons.SAMElectrumMissileDefense

XSS0202 = Class(SSubUnit) {
    Weapons = {
        Missile = Class(SLaanseMissileWeapon) {},
		RightAAGun = Class(SAAShleoCannonWeapon) {},
		LeftAAGun = Class(SAAOlarisCannonWeapon) {},
        AntiMissile = Class(SAMElectrumMissileDefense) {},
    },

    BackWakeEffect = {},
    
    OnMotionVertEventChange = function(self, new, old)
        SSubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetWeaponEnabledByLabel('Missile', true)
            self:SetWeaponEnabledByLabel('RightAAGun', true)
            self:SetWeaponEnabledByLabel('LeftAAGun', true)
            self:SetWeaponEnabledByLabel('AntiMissile', true)
        elseif new == 'Down' then
            self:SetWeaponEnabledByLabel('Missile', false)
            self:SetWeaponEnabledByLabel('RightAAGun', false)
            self:SetWeaponEnabledByLabel('LeftAAGun', false)
            self:SetWeaponEnabledByLabel('AntiMissile', false)
        end
    end,

    OnStopBeingBuilt = function(self, builer, layer)
        SSubUnit.OnStopBeingBuilt(self, builer, layer)
        if self.originalBuilder then
            IssueDive({self})
        end
    end
}

TypeClass = XSS0202