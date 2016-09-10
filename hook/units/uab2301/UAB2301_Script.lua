#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB2301/UAB2301_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Heavy Gun Tower Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local ADFCannonOblivionWeapon = import('/lua/aeonweapons.lua').ADFCannonOblivionWeapon

UAB2301 = Class(AStructureUnit) {
    Weapons = {
        MainGun = Class(ADFCannonOblivionWeapon) {
			FxMuzzleFlash = {
				'/effects/emitters/oblivion_cannon_flash_04_emit.bp',
				'/effects/emitters/oblivion_cannon_flash_05_emit.bp',				
				'/effects/emitters/oblivion_cannon_flash_06_emit.bp',
			},        
            
             -- here we are reseting some code all the way in weapon.lua 
             -- the reset pose time for the turret so that it returns to its original position after X and not 999999 seconds
             -- we need both SetupTurret and OnStopTracking to do this reliably.
            SetupTurret = function(self)
                ADFCannonOblivionWeapon.SetupTurret(self)
                self.AimControl:SetResetPoseTime(1) --we simply run this at the end of the function to override it
            end,
            
            OnStopTracking = function(self, label)
                self:PlayWeaponSound('BarrelStop')
                self:StopWeaponAmbientSound('BarrelLoop')
                if EntityCategoryContains(categories.STRUCTURE, self.unit) then
                    self.AimControl:SetResetPoseTime(1)
                end
            end,
        }
    },
}

TypeClass = UAB2301