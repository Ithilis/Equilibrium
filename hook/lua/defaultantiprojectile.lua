--****************************************************************************
--**
--**  File     :  /lua/defaultantimissile.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Default definitions collision beams
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local Entity = import('/lua/sim/Entity.lua').Entity



Flare = Class(Entity) {
    OnCreate = function(self, spec)
        self.Owner = spec.Owner
        self.Radius = spec.Radius or 5
        self.OffsetMult = spec.OffsetMult or 0
        self:SetCollisionShape('Sphere', 0, 0, self.Radius * self.OffsetMult, self.Radius)
        self:SetDrawScale(self.Radius)
        self:AttachTo(spec.Owner, -1)
        self.RedirectCat = spec.Category or 'MISSILE'
        self.RedirectIgnoreCat = spec.IgnoreCategory or 'STRATEGIC' --adding the option to ignore some projectiles, by default 'strategic', like nukes.
    end,

    -- We only divert projectiles. The flare-projectile itself will be responsible for
    -- accepting the collision and causing the hostile projectile to impact.
    OnCollisionCheck = function(self,other)
        myArmy = self:GetArmy()
        otherArmy = other:GetArmy()
        if EntityCategoryContains(ParseEntityCategory(self.RedirectCat), other) and not EntityCategoryContains(ParseEntityCategory(self.IgnoreCategory), other) and myArmy != otherArmy and IsAlly(myArmy, otherArmy) == false then
            other:SetNewTarget(self.Owner)
        end
        return false
    end,
}