--------------------------------------------------------------------
-- File     :  /projectiles/ShieldCollider_script.lua
-- Author(s):  Exotic_Retard, made for Equilibrium Balance Mod
-- Summary  : Companion projectile enabling air units to hit shields
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------

local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat
local Projectile = import('/lua/sim/projectile.lua').Projectile

local oldShieldCollider = ShieldCollider

ShieldCollider = Class(oldShieldCollider) {
    -- Destroy the sinking unit when it hits the ground.
    OnImpact = function(self, targetType, targetEntity)
        if self and not self:BeenDestroyed() and self.Plane and not self.Plane:BeenDestroyed() then
            if targetType == 'Terrain' or targetType == 'Water' then
                -- Here it should be noted that bone 0 IS NOT what the ground checks for, so if you have a projectile at that bone
                -- and the units centre is below it, then its below the ground and that can cause it to hit water instead.
                -- All this is just to prevent that, because falling planes are stupid.

                self:SetVelocity(0, 0, 0)
                if not self.Plane.GroundImpacted then
                    self.Plane:OnImpact(targetType)
                end
                self:Destroy()
            elseif targetType == 'Shield' and targetEntity and not targetEntity:BeenDestroyed() and targetEntity.ShieldType == 'Bubble' then
                if not self.ShieldImpacted and not self.Plane.GroundImpacted then
                    self.ShieldImpacted = true -- Only impact once

                    -- Find the vector to the impact location, used for the impact ripple FX
                    local wx, wy, wz = unpack(VDiff(targetEntity:GetPosition(), self:GetPosition())) -- Vector from mid of shield to impact point
                    local shieldImpactVector = {x = wx, y = wy, z = wz}

                    local exclusions = categories.EXPERIMENTAL + categories.TRANSPORTATION - categories.uea0203
                    if not EntityCategoryContains(exclusions, self.Plane) then -- Exclude experimentals and transports from momentum system, but not damage
                        Warp(self, self.Plane:GetPosition(self.PlaneBone), self.Plane:GetOrientation())

                        self:DetachAll('anchor') -- Make sure to detach just in case, prior to trying to attach
                        self.Plane:DetachAll(self.PlaneBone)

                        self.Plane:AttachBoneTo(self.PlaneBone, self, 'anchor') -- We attach our bone at the very last moment when we need it
                        self.Plane.Detector = CreateCollisionDetector(self.Plane)
                        self.Plane.Detector:WatchBone(self.PlaneBone)
                        self.Plane.Detector:EnableTerrainCheck(true)
                        self.Plane.Detector:Enable()

                        -- If you try to deattach the plane, it has retarded game code that makes it continue falling in its original direction
                        self:ShieldBounce(targetEntity, shieldImpactVector) -- Calculate the appropriate change of velocity
                    end

                    if not self.Plane.deathWep or not self.Plane.DeathCrashDamage then -- Bail if stuff's missing.
                        WARN('ShieldCollider: did not find a deathWep on the plane! Is the weapon defined in the blueprint? - ' .. self:GetUnitId())
                        return
                    end

                    local initialDamage = self.Plane.DeathCrashDamage
                    local deathWep = self.Plane.deathWep

                    -- Calculate damage dealt, up to a maximum of 20% of the shield's maximum HP
                    local shieldDamageLimit = targetEntity:GetMaxHealth() * 0.2

                    local mult = deathWep.DeathCrashShieldMult or 1 -- Allow a unit to be designated as dealing less than normal damage to shields on crash
                    local damage = initialDamage * mult

                    -- Damage the shield
                    local finalDamage = math.min(shieldDamageLimit, damage)
                    targetEntity:ApplyDamage(self.Plane, finalDamage, shieldImpactVector or {x = 0, y = 0, z = 0}, deathWep.DamageType, false)

                    -- Create destruction effects at the shield impact. Ideally we would use air destruction effects here but they are ugly.
                    self.Plane:CreateDestructionEffects(self, self.OverKillRatio)

                    -- Update the unit's remaining crash damage
                    self.Plane.DeathCrashDamage = initialDamage - finalDamage
                end
            elseif targetType ~= 'Shield' then -- Don't go through here for non-bubble shield collisions
                self:Destroy()
            end
        end
    end,
}

TypeClass = ShieldCollider
