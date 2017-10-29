--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0307/UAL0307_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Aeon Mobile Shield Generator Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon --import a default weapon so our pointer doesnt explode
local SmartPointer = import('/lua/SmartPointer.lua').SmartPointer --import our pointer disable code

local oldUAL0307 = UAL0307

oldUAL0307 = SmartPointer(oldUAL0307)

UAL0307 = Class(oldUAL0307) {
    Weapons = {
        TargetPointer = Class(DefaultProjectileWeapon) {},
    },
}

TypeClass = UAL0307
