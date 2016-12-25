-- ****************************************************************************
-- **
-- **  File     :  /lua/sim/Weapon.lua
-- **  Author(s):  John Comes
-- **
-- **  Summary  : The base weapon class for all weapons in the game.
-- **
-- **  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local Entity = import('/lua/sim/Entity.lua').Entity
local NukeDamage = import('/lua/sim/NukeDamage.lua').NukeAOE
local Set = import('/lua/system/setutils.lua')

OldWeapon = Weapon

Weapon = Class(OldWeapon) {

    AddMaxRadiusMod = function(self, maxRadMod)
        if not self.MaxRadiusMod then
            self.MaxRadiusMod = 0
            self.DefaultMaxRad = self:GetBlueprint().MaxRadius
        end
        self.MaxRadiusMod = self.MaxRadiusMod + (maxRadMod or 0)
        self:ChangeMaxRadius((self.DefaultMaxRad + self.MaxRadiusMod)) 
    end,

}
