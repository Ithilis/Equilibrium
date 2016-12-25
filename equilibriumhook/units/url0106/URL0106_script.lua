--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0106/URL0106_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Light Infantry Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CDFLaserPulseLightWeapon = import('/lua/cybranweapons.lua').CDFLaserPulseLightWeapon

local Weapon = import('/lua/sim/Weapon.lua').Weapon
local cWeapons = import('/lua/cybranweapons.lua')

local EMPDeathWeapon = Class(Weapon) {
    OnCreate = function(self)
        Weapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,

    OnFire = function(self)
        local blueprint = self:GetBlueprint()
        DamageArea(self.unit, self.unit:GetPosition(), blueprint.DamageRadius,
                   blueprint.Damage, blueprint.DamageType, blueprint.DamageFriendly)
    end,
}


URL0106 = Class(CWalkingLandUnit) {
    Weapons = {
        MainGun = Class(CDFLaserPulseLightWeapon) {},
        MainGun2 = Class(CDFLaserPulseLightWeapon) {},
        EMP = Class(EMPDeathWeapon) {},
    },
    
    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)
        self.DefaultROF = self:GetBlueprint().Weapon[1].RateOfFire
    end,
    
    OnKilled = function(self, instigator, type, overkillRatio)
        local emp = self:GetWeaponByLabel('EMP')
        local bp
        for k, v in self:GetBlueprint().Buffs do
            if v.Add.OnDeath then
                bp = v
            end
        end
        if bp != nil then 
            self:AddBuff(bp)
        end
           
        if self.UnitComplete then
            CreateLightParticle( self, -1, -1, 24, 62, 'flare_lens_add_02', 'ramp_red_10' )
            emp:SetWeaponEnabled(true)
            emp:OnFire()
        end
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
    
    OnAttachedToTransport = function(self, transport, bone)
        local wep = self:GetWeaponByLabel('MainGun')
        wep:ChangeRateOfFire((self.DefaultROF*0.75)) --we do this to make labs have less dps when in transports, since ghetto snipes are pretty damn good
        --we tried increasing firing randomness but it was totally useless against tanks so we had to nerf fire rate instead. shame.
        CWalkingLandUnit.OnAttachedToTransport(self, transport, bone)
    end,
    
    OnDetachedFromTransport = function(self, transport, bone)
        local wep = self:GetWeaponByLabel('MainGun')
        self.DefaultROF = self:GetBlueprint().Weapon[1].RateOfFire
        wep:ChangeRateOfFire(self.DefaultROF)
        CWalkingLandUnit.OnDetachedFromTransport(self, transport, bone)
    end,
    
}

TypeClass = URL0106