-----------------------------------------------------------------
-- File     :  /lua/sim/DefaultWeapons.lua
-- Author(s):  John Comes
-- Summary  :  Default definitions of weapons
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

--EQ: making compatible with released version, delete when faf beta OC is released.
local oldOverchargeWeapon = OverchargeWeapon
OverchargeWeapon = Class(oldOverchargeWeapon) {
    StartEconomyDrain = function(self) -- OverchargeWeapon drains energy on impact
    end,
}
