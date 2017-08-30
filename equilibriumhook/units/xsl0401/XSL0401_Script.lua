-----------------------------------------------------------------
-- File     :  /data/units/XSL0401/XSL0401_script.lua
-- Author(s):  Jessica St. Croix, Dru Staltman, Aaron Lundquist
-- Summary  :  Seraphim Experimental Assault Bot
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SWalkingLandUnit = import('/lua/seraphimunits.lua').SWalkingLandUnit
local WeaponsFile = import ('/lua/seraphimweapons.lua')
local SDFExperimentalPhasonProj = WeaponsFile.SDFExperimentalPhasonProj
local SDFAireauWeapon = WeaponsFile.SDFAireauWeapon
local SDFSinnuntheWeapon = WeaponsFile.SDFSinnuntheWeapon
local SAAOlarisCannonWeapon = WeaponsFile.SAAOlarisCannonWeapon
local utilities = import('/lua/utilities.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local explosion = import('/lua/defaultexplosions.lua')
local SeabedRevealFile = import('/lua/SeabedReveal.lua') --import our intel relay entity code
local SeabedReveal = SeabedRevealFile.SeabedReveal --this part applies to the weapon
local SeabedRevealUnit = SeabedRevealFile.SeabedRevealUnit --this part applies to the unit

local oldXSL0401 = XSL0401

SDFExperimentalPhasonProj = SeabedReveal(SDFExperimentalPhasonProj) --inject our revealing code in here
SDFSinnuntheWeapon = SeabedReveal(SDFSinnuntheWeapon) --inject our revealing code in here
oldXSL0401 = SeabedRevealUnit(oldXSL0401)


XSL0401 = Class(oldXSL0401) {
    Weapons = {
        EyeWeapon = Class(SDFExperimentalPhasonProj) {},
        LeftArm = Class(SDFAireauWeapon) {},
        RightArm = Class(SDFSinnuntheWeapon) {},
        LeftAA = Class(SAAOlarisCannonWeapon) {},
        RightAA = Class(SAAOlarisCannonWeapon) {},
    },
}

TypeClass = XSL0401
