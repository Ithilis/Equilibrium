--****************************************************************************
--**
--**  File     :  /lua/SmartOverCharge.lua
--**  Author(s):  Exotic_Retard for Equilibrium Balance mod
--**
--**  Summary  :  Modifies OC projectile scripts to dynamically pick the best damage
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

function SmartOverCharge(SuperClass)
    return Class(SuperClass) {
    
    SmartOverChargeScale = 2000,
    MaxOverChargeCharges = 15,
    
    OnImpact = function(self, targetType, targetEntity)
        --dynamic overcharge damage script
        --the OC damage scales with energy drain in tiers for ease of use, with a minimum drain of 2000, normally
        if targetType == 'Unit' or targetType == 'Shield' then
            
            local targetHealth = targetEntity:GetHealth() -- our target health, unit or shield
            
            if targetType == 'Unit' and targetEntity.MyShield then --if we have a personal shield we need to add its hp on. doesnt apply to bubble shields
                -- WARN('shield hp: ' .. targetEntity.MyShield:GetHealth())
                targetHealth = targetHealth + targetEntity.MyShield:GetHealth()
            end
            
            --the damage scales so that it doesnt overkill the target and waste energy, and it always spends enough to kill it, or try.
            --armoured units need that taken into account, and shields need to work out their owner's armour.
            local armType = 1 --1 for units, 0.15 for structures, 0.1 for acu
            
            if targetType == 'Shield' and targetEntity.Owner then
                --WARN('shield armour mult: ' .. targetEntity.Owner:GetArmorMult('Overcharge'))
                armType = targetEntity.Owner:GetArmorMult('Overcharge')
            elseif targetType == 'Unit' then
                --WARN('unit armour mult: ' .. targetEntity:GetArmorMult('Overcharge'))
                armType = targetEntity:GetArmorMult('Overcharge')
            else
                WARN('Equilibrium - somethings gone wrong with working out the armour! Assuming no armour.')
            end
            
            --apply our buffs - we use a function to work out how much hp it has and how much damage to do.
            self.DamageData.DamageAmount = self:CalcDamage(armType, targetHealth)
            
            --logging
            
            -- WARN('target total current hp: ' .. targetHealth)
            -- WARN(repr(targetEntity))
        end
        
        SuperClass.OnImpact(self, targetType, targetEntity)
    end,
    
    CalcDamage = function(self, armourType, Health)
        
        local energyStored = self:GetLauncher():GetAIBrain():GetEconomyStored('ENERGY')
        local chargesAvailable = math.floor(energyStored/self.SmartOverChargeScale)
        
        --each charge is 2000(or however) energy and adds 1000 damage
        --and we dont want to overkill our target and waste energy
        --to enable the OC ui to work the first 2000(or however) is drained on the weapon on fire, the rest is decided on impact.
        
        local chargesNeeded = 1
        
        if armourType > 0 then
            chargesNeeded = math.ceil(Health/(1000*armourType))
        else
            WARN('Equilibrium - overcharge found an armour multiplier of 0 or less!')
        end
        
        --buildings + ACUs need a special exception to the damage calculation since they have armour.
        
        --This is already after the initial 2000(or however) has been drained from the weapon so we start from 0 and not 1
        local chargesUsed = math.min(chargesNeeded, chargesAvailable + 1)
        
        --cap our damage at 15000, so you cant own exps super easy.
        chargesUsed = math.min(chargesUsed, self.MaxOverChargeCharges)
        
        local energyNeeded = math.max((chargesUsed)*self.SmartOverChargeScale - self.SmartOverChargeScale, 0) --we subtract the initial charge from the cost, math.max incase it aims for dead unit
        
        --drain the energy
        CreateEconomyEvent(self:GetLauncher(), energyNeeded, 0, 0.1)
        
        --apply our buffs
        local damage = 1000*chargesUsed
        --acus take 10x less damage so 100 per charge
        --buildings take 5x less damage so 200 per charge
        
        
        --logging - remember that we have one free charge to use from the weapon drain.
        -- WARN('energy needed for one charge: ' .. self.SmartOverChargeScale)
         WARN('charges needed for target: ' .. chargesNeeded)
         WARN('charges available: ' .. chargesAvailable)
         WARN('charges used: ' .. chargesUsed)
         WARN('energy drained: ' .. energyNeeded)
        
        return damage
    end
    
    }    
end