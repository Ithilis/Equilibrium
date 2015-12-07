--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0104/URL0104_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Anti-Air Tank Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CLandUnit = import('/lua/cybranunits.lua').CLandUnit
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon

URL0104 = Class(CLandUnit) {
    Weapons = {
        AAGun = Class(CAANanoDartWeapon) {},
        GroundGun = Class(CAANanoDartWeapon) {},
    },
    
}
TypeClass = URL0104

