#****************************************************************************
#**
#**  File     :  /cdimage/units/UEL0106/UEL0106_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Light Assault Bot Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local TWalkingLandUnit = import('/lua/terranunits.lua').TWalkingLandUnit
local Unit = import('/lua/sim/Unit.lua').Unit
local TDFMachineGunWeapon = import('/lua/terranweapons.lua').TDFMachineGunWeapon


UEL0106 = Class(TWalkingLandUnit) {
    Weapons = {
        ArmCannonTurret = Class(TDFMachineGunWeapon) {
            DisabledFiringBones = {
                'Torso', 'Head',  'Arm_Right_B01', 'Arm_Right_B02','Arm_Right_Muzzle',
                'Arm_Left_B01', 'Arm_Left_B02','Arm_Left_Muzzle'
                },
        },
    },
    
    OnCreate = function(self)
        TWalkingLandUnit.OnCreate(self)
        self.DefaultROF = self:GetBlueprint().Weapon[1].RateOfFire
    end,
    
    OnAttachedToTransport = function(self, transport, bone)
        local wep = self:GetWeaponByLabel('ArmCannonTurret')
        wep:ChangeRateOfFire((self.DefaultROF*0.75)) --we do this to make labs have less dps when in transports, since ghetto snipes are pretty damn good
        --we tried increasing firing randomness but it was totally useless against tanks so we had to nerf fire rate instead. shame.
        TWalkingLandUnit.OnAttachedToTransport(self, transport, bone)
    end,
    
    OnDetachedFromTransport = function(self, transport, bone)
        local wep = self:GetWeaponByLabel('ArmCannonTurret')
        self.DefaultROF = self:GetBlueprint().Weapon[1].RateOfFire
        wep:ChangeRateOfFire(self.DefaultROF)
        TWalkingLandUnit.OnDetachedFromTransport(self, transport, bone)
    end,
    
}
TypeClass = UEL0106

