--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0106/UAL0106_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Light Assault Bot Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AWalkingLandUnit = import('/lua/aeonunits.lua').AWalkingLandUnit
local ADFSonicPulsarWeapon = import('/lua/aeonweapons.lua').ADFSonicPulsarWeapon
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

UAL0106 = Class(AWalkingLandUnit) {
    Weapons = {
        ArmLaserTurret = Class(ADFSonicPulsarWeapon) {}
    },
    
    OnCreate = function(self)
        AWalkingLandUnit.OnCreate(self)
        self.DefaultROF = self:GetBlueprint().Weapon[1].RateOfFire
    end,
    
    OnKilled = function(self, instigator, type, overkillRatio)
        AWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
        local pos = self:GetPosition()
        local spec = {
            X = pos[1],
            Z = pos[3],
            Radius = self:GetBlueprint().Intel.VisionRadiusOnDeath,
            LifeTime = self:GetBlueprint().Intel.IntelDurationOnDeath,
            Army = self:GetArmy(),
            Omni = false,
            WaterVision = false,
        }
        local vizEntity = VizMarker(spec)
      end,
    
    OnAttachedToTransport = function(self, transport, bone)
        local wep = self:GetWeaponByLabel('ArmLaserTurret')
        wep:ChangeRateOfFire((self.DefaultROF*0.75)) --we do this to make labs have less dps when in transports, since ghetto snipes are pretty damn good
        --we tried increasing firing randomness but it was totally useless against tanks so we had to nerf fire rate instead. shame.
        AWalkingLandUnit.OnAttachedToTransport(self, transport, bone)
    end,
    
    OnDetachedFromTransport = function(self, transport, bone)
        local wep = self:GetWeaponByLabel('ArmLaserTurret')
        wep:ChangeRateOfFire(self.DefaultROF)
        AWalkingLandUnit.OnDetachedFromTransport(self, transport, bone)
    end,
    
}

TypeClass = UAL0106
