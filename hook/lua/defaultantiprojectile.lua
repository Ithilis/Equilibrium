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


FlareUpper = Class(Entity) {

    OnCreate = function(self, spec)
        self.Owner = spec.Owner
        self.Radius = spec.Radius or 5
        self:SetCollisionShape('Sphere', 0, 0, self.Radius*1.33, self.Radius) -- this is the only difference
        self:SetDrawScale(self.Radius)
        self:AttachTo(spec.Owner, -1)
        self.RedirectCat = spec.Category or 'MISSILE'
    end,

    -- We only divert projectiles. The flare-projectile itself will be responsible for
    -- accepting the collision and causing the hostile projectile to impact.
    OnCollisionCheck = function(self,other)
        if EntityCategoryContains(ParseEntityCategory(self.RedirectCat), other) and (self:GetArmy() != other:GetArmy())then
            --LOG('*DEBUG FLARE COLLISION CHECK')
            other:SetNewTarget(self.Owner)
        end
        return false
    end,
}

FlareLower = Class(Entity) {

    OnCreate = function(self, spec)
        self.Owner = spec.Owner
        self.Radius = spec.Radius or 5
        self:SetCollisionShape('Sphere', 0, 0, -self.Radius*1.33, self.Radius) -- this is the only difference
        self:SetDrawScale(self.Radius)
        self:AttachTo(spec.Owner, -1)
        self.RedirectCat = spec.Category or 'MISSILE'
    end,

    -- We only divert projectiles. The flare-projectile itself will be responsible for
    -- accepting the collision and causing the hostile projectile to impact.
    OnCollisionCheck = function(self,other)
        if EntityCategoryContains(ParseEntityCategory(self.RedirectCat), other) and (self:GetArmy() != other:GetArmy())then
            --LOG('*DEBUG FLARE COLLISION CHECK')
            other:SetNewTarget(self.Owner)
        end
        return false
    end,
}