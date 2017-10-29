--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0307/UEL0307_script.lua
--**  Author(s):  David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Mobile Shield Generator Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon --import a default weapon so our pointer doesnt explode
local SmartPointer = import('/lua/SmartPointer.lua').SmartPointer --import our pointer disable code

local oldUEL0307 = UEL0307

oldUEL0307 = SmartPointer(oldUEL0307)


UEL0307 = Class(oldUEL0307) {
    Weapons = {        
        TargetPointer = Class(DefaultProjectileWeapon) {},
    },
}

TypeClass = UEL0307