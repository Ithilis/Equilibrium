-----------------------------------------------------------------
-- File     :  /cdimage/units/UAL0401/UAL0401_script.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Aeon Galactic Colossus Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local AWalkingLandUnit = import('/lua/aeonunits.lua').AWalkingLandUnit
local WeaponsFile = import ('/lua/aeonweapons.lua')
local ADFPhasonLaser = WeaponsFile.ADFPhasonLaser
local ADFTractorClaw = WeaponsFile.ADFTractorClaw
local utilities = import('/lua/utilities.lua')
local explosion = import('/lua/defaultexplosions.lua')
local SeabedRevealFile = import('/lua/SeabedReveal.lua') --import our intel relay entity code
local SeabedReveal = SeabedRevealFile.SeabedReveal --this part applies to the weapon
local SeabedRevealUnit = SeabedRevealFile.SeabedRevealUnit --this part applies to the unit

local oldUAL0401 = UAL0401

ADFPhasonLaser = SeabedReveal(ADFPhasonLaser) --inject our revealing code in here
oldUAL0401 = SeabedRevealUnit(oldUAL0401)


UAL0401 = Class(oldUAL0401) {
    Weapons = {
        EyeWeapon = Class(ADFPhasonLaser) {
        --[[
            OnFire = function(self)
                ADFPhasonLaser.OnFire(self)
                WARN('yeah')
            end,
        --]]
        },
        RightArmTractor = Class(ADFTractorClaw) {},
        LeftArmTractor = Class(ADFTractorClaw) {},
    },
}

TypeClass = UAL0401
