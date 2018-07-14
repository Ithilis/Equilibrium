-----------------------------------------------------------------
-- File     : /lua/defaultprojectiles.lua
-- Author(s): John Comes, Gordon Duclos
-- Summary  : Script for default projectiles
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local Projectile = import('/lua/sim/Projectile.lua').Projectile
local GetTrueEnemyUnitsInSphere = import('/lua/utilities.lua').GetTrueEnemyUnitsInSphere
local GetDistanceBetweenTwoEntities = import('/lua/utilities.lua').GetDistanceBetweenTwoEntities
local GetTrueEnemyUnitsInCylinder = import('/lua/utilities.lua').GetTrueEnemyUnitsInCylinder
local Get2DDistanceBetweenTwoEntities = import('/lua/utilities.lua').Get2DDistanceBetweenTwoEntities
-----------------------------------------------------------
-- PROJECTILE THAT ADJUSTS DAMAGE AND ENERGY COST ON IMPACT
-----------------------------------------------------------
local OCProjectiles = {} --EQ: add a shared table for the OC projectiles to use

--EQ:dynamic overcharge damage script rewritten from the ground
OverchargeProjectile = Class() {
    SmartOverChargeScale = 2000,
    MaxOverChargeCharges = 15,
    
    OnImpact = function(self, targetType, targetEntity)
        --the OC damage scales with energy drain in tiers for ease of use, with a minimum drain of 2000, normally
        local targetHealth = 0
        
        --this is to guarantee a hit on the target unit. technically its not needed but you know.
        if targetType == 'Unit' or targetType == 'Shield' then
            targetHealth = self:CalcEffectiveHP(targetType, targetEntity)
            --WARN('target total current hp: ' .. targetHealth)
        end
        
        targetHealth = self:AdjustForAOE(targetHealth)
        --adjust damage and drain energy. if we hit no units we use default values.
        self.DamageData.DamageAmount = self:CalcDamage(targetHealth)
    end,
    
    CalcDamage = function(self, Health)
        if not Health > 0 then
            WARN('Equilibrium - overcharge found a negative or nil hp value!')
            return 1000 --1 stacks worth of damage and call it a day.
        end
        
        local energyStored = self:GetLauncher():GetAIBrain():GetEconomyStored('ENERGY')
        
        --in case of multiple OC projectiles landing at the same time, adjust energy storage, we need a table since they all drain at the same time too.
        local army = self:GetArmy()
        if not OCProjectiles[army] then
            OCProjectiles[army] = {}
        end
        
        if OCProjectiles[army].LastTickChecked == GetGameTick() then
            if not OCProjectiles[army].TrueEnergyStored then
                WARN('Equilibrium - TrueEnergyStored not found in OC projectile table when there are multiple projectiles on impact!')
                OCProjectiles[army].TrueEnergyStored = energyStored
            end
            energyStored = OCProjectiles[army].TrueEnergyStored
        end
        --record the time this check was made so that if another projectile lands at the same time we know what to do.
        OCProjectiles[army].LastTickChecked = GetGameTick()
                
        -- Get max energy available to drain according to how much we have
        -- Minimum of one charge in cases where theres no energy left on impact. it will dip into negative but thats better than wasting oc completely.
        local chargesAvailable = math.max(math.floor(energyStored/self.SmartOverChargeScale), 1)
        
        --each charge is 2000(or however) energy and adds 1000 damage
        --and we dont want to overkill our target and waste energy
        --to enable the OC ui to work the first 2000(or however) is drained on the weapon on fire, the rest is decided on impact.
        
        local chargesNeeded = math.max( math.ceil(Health/1000), 1) -- we need to damage once at least to account for dead units
        --cap our damage to the energy available, and to 15000 to avoid owning exps too easily
        local chargesUsed = math.min(chargesNeeded, chargesAvailable, self.MaxOverChargeCharges)
        local energyNeeded = math.max((chargesUsed)*self.SmartOverChargeScale, 0) --math.max incase it aims for dead unit
        
        --drain the energy
        CreateEconomyEvent(self:GetLauncher(), energyNeeded, 0, 0.1)
        --update the amount of storage available during this tick
        OCProjectiles[army].TrueEnergyStored = math.max(energyStored - energyNeeded, 0)
        
        --apply our buffs
        local damage = 1000*chargesUsed
        --acus take 10x less damage so 100 per charge
        --buildings take 5x less damage so 200 per charge
        
        --logging - remember that we have one free charge to use from the weapon drain.
        --WARN('energy needed for one charge: ' .. self.SmartOverChargeScale)
        --WARN('charges needed for target: ' .. chargesNeeded)
        --WARN('charges available: ' .. chargesAvailable)
        --WARN('charges used: ' .. chargesUsed)
        --WARN('energy drained: ' .. energyNeeded)
        --WARN('damage dealt: ' .. damage)
        return damage
    end,
    
    AdjustForAOE = function(self, currentHealth)
        --Find all units around the radius, and then return the max HP of the unit for OC purposes.
        local launcher = self:GetLauncher()
        local maxHealth = currentHealth or 0 --if called when an hp value already exists.
        local TotalUnits = 0
        --Use special EQ magic code, low height so you avoid hitting air units. This is more accurate. probably.
        local nearbyUnits = GetTrueEnemyUnitsInCylinder(launcher, self:GetPosition(), 15, 5, categories.ALLUNITS) or {} --prevent nil values if nothing nearby
        for _, unit in nearbyUnits do
            local unitWidth = math.min(unit:GetBlueprint().SizeX, unit:GetBlueprint().SizeZ)
            local health = 0
            --adjust for unit hitbox sizes. this is an approximation since it considers unit hitboxes as cylinders but should work most of the time.
            if Get2DDistanceBetweenTwoEntities(unit, self) < unitWidth + self.DamageData.DamageRadius - 0.1 then
                health = self:CalcEffectiveHP('Unit', unit)
                TotalUnits = TotalUnits + 1 --count up the units. for logging mostly.
            end
            
            --deal with bubble shields. they are spheres so we can use distance from centre to check for intersections. magic!
            if unit.MyShield.ShieldType == 'Bubble' and unit.MyShield._IsUp then
                --we use 3d distance in this case because spheres.
                local distance = GetDistanceBetweenTwoEntities(unit.MyShield, self)
                local width = self.DamageData.DamageRadius
                --if the distance is within the shield radius +- the AOE range, then the aoe and shield intersect. mostly. aoe isnt a sphere (or is it?)
                if distance > (unit.MyShield.Size/2 - width) and distance < (unit.MyShield.Size/2 + width) then
                    health = self:CalcEffectiveHP('Shield', unit.MyShield)
                end
            end
            
            if health > maxHealth then
                maxHealth = health
            end
        end
        --WARN('max hp detected: '..maxHealth)
        --WARN('total enemies hit(?): '..TotalUnits)
        return maxHealth
    end,
    
    CalcEffectiveHP = function(self, targetType, targetEntity)
        --Find out how much damage we want to deal to the entity. Assumes Unit or Shield.
        if targetEntity.IsDead == true then WARN('Equilibrium - OC hit a dead unit. Assuming it has 0 hp. Not really an error') return 0 end --dead things dont have health
        local effectiveHealth = targetEntity:GetHealth() -- our target health, unit or shield
        
        --the damage scales so that it doesnt overkill the target and waste energy, and it always spends enough to kill it, or try.
        --armoured units need that taken into account, and shields need to work out their owner's armour.
        local armType = 1 --0.2 for structures, 0.1 for acu, 1 for everything else
        if targetType == 'Shield' and targetEntity.Owner then
            --WARN('shield armour mult: ' .. targetEntity.Owner:GetArmorMult('Overcharge'))
            armType = targetEntity.Owner:GetArmorMult('Overcharge')
        elseif targetType == 'Unit' then
            --WARN('unit armour mult: ' .. targetEntity:GetArmorMult('Overcharge'))
            armType = targetEntity:GetArmorMult('Overcharge')
            --if we have a personal shield we need to add its hp on.
            --we check for a bubble shield incase we hit a unit while inside the dome
            if targetEntity.MyShield and targetEntity.MyShield.ShieldType ~= 'Bubble' then
                -- WARN('shield hp: ' .. targetEntity.MyShield:GetHealth())
                effectiveHealth = effectiveHealth + targetEntity.MyShield:GetHealth()
            end
        else
            WARN('Equilibrium - somethings gone wrong with working out the armour! Assuming no armour.')
        end
        
        if armType > 0 then
            effectiveHealth = effectiveHealth/armType
        else
            WARN('Equilibrium - overcharge found an armour multiplier of 0 or less!')
        end
        
        return effectiveHealth
    end,
}
