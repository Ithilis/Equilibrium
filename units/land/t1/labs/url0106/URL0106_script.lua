#****************************************************************************
#**
#**  File     :  /cdimage/units/URL0106/URL0106_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran Light Infantry Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

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
	
}

TypeClass = URL0106