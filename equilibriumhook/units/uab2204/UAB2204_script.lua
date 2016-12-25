#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB2204/UAB2204_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
#**
#**  Summary  :  Aeon Flak Cannon
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local AAATemporalFizzWeapon = import('/lua/aeonweapons.lua').AAATemporalFizzWeapon

UAB2204 = Class(AStructureUnit) {
    Weapons = {
        AAFizz = Class(AAATemporalFizzWeapon) {
            ChargeEffectMuzzles = {'Turret_Right_Muzzle', 'Turret_Left_Muzzle'},
            
            PlayFxRackSalvoChargeSequence = function(self)
                AAATemporalFizzWeapon.PlayFxRackSalvoChargeSequence(self)
                CreateAttachedEmitter( self.unit, 'Turret_Right_Muzzle', self.unit:GetArmy(), '/effects/emitters/temporal_fizz_muzzle_charge_02_emit.bp')
                CreateAttachedEmitter( self.unit, 'Turret_Left_Muzzle', self.unit:GetArmy(), '/effects/emitters/temporal_fizz_muzzle_charge_03_emit.bp')
            end,
            
             -- here we are reseting some code all the way in weapon.lua 
             -- the reset pose time for the turret so that it returns to its original position after X and not 999999 seconds
             -- we need both SetupTurret and OnStopTracking to do this reliably.
            SetupTurret = function(self)
                AAATemporalFizzWeapon.SetupTurret(self)
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

TypeClass = UAB2204