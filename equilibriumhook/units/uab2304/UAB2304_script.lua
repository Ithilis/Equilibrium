#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB2304/UAB2304_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Aeon Advanced Anti-Air System Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local AAAZealotMissileWeapon = import('/lua/aeonweapons.lua').AAAZealotMissileWeapon

UAB2304 = Class(AStructureUnit) {
    Weapons = {
        AntiAirMissiles = Class(AAAZealotMissileWeapon) {
             -- here we are reseting some code all the way in weapon.lua 
             -- the reset pose time for the turret so that it returns to its original position after X and not 999999 seconds
             -- we need both SetupTurret and OnStopTracking to do this reliably.
            SetupTurret = function(self)
                AAAZealotMissileWeapon.SetupTurret(self)
                self.AimControl:SetResetPoseTime(1) --we simply run this at the end of the function to override it
            end,
            
            OnStopTracking = function(self, label)
                self:PlayWeaponSound('BarrelStop')
                self:StopWeaponAmbientSound('BarrelLoop')
                if EntityCategoryContains(categories.STRUCTURE, self.unit) then
                    self.AimControl:SetResetPoseTime(1)
                end
            end,
        },
    },
}

TypeClass = UAB2304