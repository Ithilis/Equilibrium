#****************************************************************************
#**
#**  File     :  /cdimage/units/XSS0103/XSS0103_script.lua
#**
#**  Summary  :  Seraphim Frigate Script: XSS0103
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

--local SSeaUnit = import('/lua/seraphimunits.lua').SSeaUnit
local SSubUnit = import('/lua/seraphimunits.lua').SSubUnit
local SWeapon = import('/lua/seraphimweapons.lua')

XSS0103 = Class(SSubUnit) {
    Weapons = {
        MainGun = Class(SWeapon.SDFShriekerCannon){},
        AntiAir = Class(SWeapon.SAAShleoCannonWeapon){},
    },
    
    OnMotionVertEventChange = function(self, new, old)
        SSubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetWeaponEnabledByLabel('MainGun', true)
            self:SetWeaponEnabledByLabel('AntiAir', true)
        elseif new == 'Down' then
            self:SetWeaponEnabledByLabel('MainGun', false)
            self:SetWeaponEnabledByLabel('AntiAir', false)
        end
    end,

    OnStopBeingBuilt = function(self, builer, layer)
        SSubUnit.OnStopBeingBuilt(self, builer, layer)
        if self.originalBuilder then
            IssueDive({self})
        end
    end
    
}
TypeClass = XSS0103
