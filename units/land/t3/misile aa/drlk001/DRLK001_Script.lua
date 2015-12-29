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
local EffectUtils = import('/lua/effectutilities.lua')
local Effects = import('/lua/effecttemplates.lua')

DRLK001 = Class(CWalkingLandUnit) 
{
    Weapons = {
        AAGun = Class(CAANanoDartWeapon) {},
        GroundGun = Class(CAANanoDartWeapon) {},
    },
    
}

TypeClass = DRLK001