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
local FlareUpper = import('/lua/defaultantiprojectile.lua').FlareUpper
local FlareLower = import('/lua/defaultantiprojectile.lua').FlareLower

local OldProjectile = Projectile
Projectile = Class(OldProjectile) {

    AddFlare = function(self, tbl)
        if not tbl then return end
        if not tbl.Radius then return end
        self.MyFlare = Flare {
            Owner = self,
            Radius = tbl.Radius or 5,
        }
        WARN('creating flare')
        if tbl.Stack == true then
            self.MyUpperFlare = FlareUpper {
                Owner = self,
                Radius = tbl.Radius or 5,
            }
            self.MyLowerFlare = FlareLower {
                Owner = self,
                Radius = tbl.Radius or 5,
            }
            self.Trash:Add(self.MyUpperFlare)
            self.Trash:Add(self.MyLowerFlare)
        end
        
        self.Trash:Add(self.MyFlare)
    end,
}
