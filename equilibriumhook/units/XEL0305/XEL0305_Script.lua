#****************************************************************************
#**
#**  File     :  /cdimage/units/XEL0305/XEL0305_script.lua
#**
#**  Summary  :  UEF Siege Assault Bot Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TerranWeaponFile = import('/lua/terranweapons.lua')
local TWalkingLandUnit = import('/lua/terranunits.lua').TWalkingLandUnit
local TDFIonizedPlasmaCannon = TerranWeaponFile.TDFIonizedPlasmaCannon
local SeabedRevealFile = import('/lua/SeabedReveal.lua') --import our intel relay entity code
local SeabedReveal = SeabedRevealFile.SeabedReveal --this part applies to the weapon
local SeabedRevealUnit = SeabedRevealFile.SeabedRevealUnit --this part applies to the unit

TDFIonizedPlasmaCannon = SeabedReveal(TDFIonizedPlasmaCannon) --inject our revealing code in here
TWalkingLandUnit = SeabedRevealUnit(TWalkingLandUnit)

XEL0305 = Class(TWalkingLandUnit) {

    Weapons = {
        PlasmaCannon01 = Class(TDFIonizedPlasmaCannon) {},
    },

}

TypeClass = XEL0305