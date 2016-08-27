--****************************************************************************
--**
--**  File     :  /lua/sim/Projectile.lua
--**  Author(s):  John Comes, Gordon Duclos
--**
--**  Summary  :  Base Projectile Definition
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local Entity = import('/lua/sim/Entity.lua').Entity
local Explosion = import('/lua/defaultexplosions.lua')
local DefaultDamage = import('/lua/sim/defaultdamage.lua')
local Flare = import('/lua/defaultantiprojectile.lua').Flare

local OldProjectile = Projectile
Projectile = Class(OldProjectile) {


    AddFlare = function(self, tbl)
        if not tbl then return end
        if not tbl.Radius then return end
        self.MyFlare = Flare {
            Owner = self,
            Radius = tbl.Radius or 5,
        }
        if tbl.Stack == true then -- Secondary flare hitboxes, one above, one below (Aeon TMD)
            self.MyUpperFlare = Flare {
                Owner = self,
                Radius = tbl.Radius,
                OffsetMult = tbl.OffsetMult,
            }
            self.MyLowerFlare = Flare {
                Owner = self,
                Radius = tbl.Radius,
                OffsetMult = -tbl.OffsetMult,
            }
            self.Trash:Add(self.MyUpperFlare)
            self.Trash:Add(self.MyLowerFlare)
        end

        self.Trash:Add(self.MyFlare)
    end,
}
