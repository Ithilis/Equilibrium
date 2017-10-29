#****************************************************************************
#**
#**  File     :  /units/XSL0307/XSL0307_script.lua
#**
#**  Summary  :  Seraphim Mobile Shield Generator Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon --import a default weapon so our pointer doesnt explode
local SmartPointer = import('/lua/SmartPointer.lua').SmartPointer --import our pointer disable code

local oldXSL0307 = XSL0307

oldXSL0307 = SmartPointer(oldXSL0307)

XSL0307 = Class(oldXSL0307) {
    Weapons = {
        TargetPointer = Class(DefaultProjectileWeapon) {},
    },
}

TypeClass = XSL0307
