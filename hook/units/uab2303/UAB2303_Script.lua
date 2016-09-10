#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB2303/UAB2303_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Light Artillery Installation Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local AIFArtilleryMiasmaShellWeapon = import('/lua/aeonweapons.lua').AIFArtilleryMiasmaShellWeapon

UAB2303 = Class(AStructureUnit) {

    Weapons = {
        MainGun = Class(AIFArtilleryMiasmaShellWeapon) {
             -- here we are reseting some code all the way in weapon.lua 
             -- the reset pose time for the turret so that it returns to its original position after X and not 999999 seconds
             -- we need both SetupTurret and OnStopTracking to do this reliably.
            SetupTurret = function(self)
                AIFArtilleryMiasmaShellWeapon.SetupTurret(self)
                self.AimControl:SetResetPoseTime(2) --we simply run this at the end of the function to override it
            end,
            
            OnStopTracking = function(self, label)
                self:PlayWeaponSound('BarrelStop')
                self:StopWeaponAmbientSound('BarrelLoop')
                if EntityCategoryContains(categories.STRUCTURE, self.unit) then
                    self.AimControl:SetResetPoseTime(2)
                end
            end,
        },
    },
}

TypeClass = UAB2303