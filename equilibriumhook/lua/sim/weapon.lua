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

    --we dont hook in this case less compatible with change but more robust, and its not like this will change much anyway.
    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()

        if proj and not proj:BeenDestroyed() then
            local bp = self:GetBlueprint()
            --EQ:Store the weapon so we can use it for later for lots of things!
            proj:PassDamageData(damageTable)
            proj.Weapon = self
            proj.BlueprintId = bp.ProjectileId --store the bpid as well so it doesnt rely on the parent unit
            if bp.NukeOuterRingDamage and bp.NukeOuterRingRadius and bp.NukeOuterRingTicks and bp.NukeOuterRingTotalTime and
                bp.NukeInnerRingDamage and bp.NukeInnerRingRadius and bp.NukeInnerRingTicks and bp.NukeInnerRingTotalTime then
                proj.InnerRing = NukeDamage()
                proj.InnerRing:OnCreate(bp.NukeInnerRingDamage, bp.NukeInnerRingRadius, bp.NukeInnerRingTicks, bp.NukeInnerRingTotalTime)
                proj.OuterRing = NukeDamage()
                proj.OuterRing:OnCreate(bp.NukeOuterRingDamage, bp.NukeOuterRingRadius, bp.NukeOuterRingTicks, bp.NukeOuterRingTotalTime)

                -- Need to store these three for later, in case the missile lands after the launcher dies
                proj.Launcher = self.unit
                proj.Army = self.unit:GetArmy()
                proj.Brain = self.unit:GetAIBrain()
            end
        end
        return proj
    end,

}
