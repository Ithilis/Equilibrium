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

-- Fixes the bug where aeon tmd redirects things it shouldnt
    AddFlare = function(self, tbl)
        if not tbl then return end
        if not tbl.Radius then return end
        self.MyFlare = Flare {
            Owner = self,
            Radius = tbl.Radius or 5,
            Category = tbl.Category or 'MISSILE', -- We pass the category bp value along so that it actually has a function.
        }
        if tbl.Stack == true then -- Secondary flare hitboxes, one above, one below (Aeon TMD)
            self.MyUpperFlare = Flare {
                Owner = self,
                Radius = tbl.Radius,
                OffsetMult = tbl.OffsetMult,
                Category = tbl.Category or 'MISSILE',
            }
            self.MyLowerFlare = Flare {
                Owner = self,
                Radius = tbl.Radius,
                OffsetMult = -tbl.OffsetMult,
                Category = tbl.Category or 'MISSILE',
            }
            self.Trash:Add(self.MyUpperFlare)
            self.Trash:Add(self.MyLowerFlare)
        end

        self.Trash:Add(self.MyFlare)
    end,
}
