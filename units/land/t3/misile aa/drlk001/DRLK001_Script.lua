--****************************************************************************
--**
--**  Author(s):  Mikko Tyster
--**
--**  Summary  :  Cybran T3 Mobile AA
--**
--**  Copyright © 2008 Blade Braver!
--****************************************************************************

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon
local TargetingLaser = import('/lua/kirvesweapons.lua').TargetingLaser
local EffectUtils = import('/lua/effectutilities.lua')
local Effects = import('/lua/effecttemplates.lua')

DRLK001 = Class(CWalkingLandUnit) 
{
    Weapons = {
        AAGun = Class(CAANanoDartWeapon) {},    
        Lazor = Class(TargetingLaser) {
            FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_02_emit.bp'},
        },
        GroundGun = Class(CAANanoDartWeapon) {},
    },
    
    OnKilled = function(self, instigator, type, overkillRatio)
        self:SetWeaponEnabledByLabel('Lazor', false)
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
    
}

TypeClass = DRLK001