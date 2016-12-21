#
# Aeon Mortar
#
local TLaserBotProjectile = import('/lua/terranprojectiles.lua').TLaserBotProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')




TDFOverCharge01 = Class(TLaserBotProjectile) {
    FxTrails = EffectTemplate.TCommanderOverchargeFXTrail01,
    FxTrailScale = 1.0,    

	# Hit Effects
    FxImpactUnit =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactProp =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactLand =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactAirUnit =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactUnderWater = {},
    
    OnImpact = function(self, targetType, targetEntity)
        --dynamic overcharge damage script
        --the OC damage scales with energy drain in tiers for ease of use, with a minimum drain of 2000
        if targetType == 'Unit' then
            
            local energyStored = self:GetLauncher():GetAIBrain():GetEconomyStored('ENERGY')
            local chargesAvailable = math.floor(energyStored/2000)
            --each charge is 4000 energy and adds damage
        
            --to enable the OC ui to work the first 2000 is drained on the weapon on fire, the rest is decided on impact.
            --the damage scales so that it doesnt overkill the target and waste energy, and it always spends enough to kill it, or try.
            
            --each charge adds 1000 damage, we dont want to overkill our target and waste energy
            local chargesNeeded = math.ceil(targetEntity:GetHealth()/1000)
            
                    --buildings + ACUs need a special exception to the damage calculation since they have armour.
            if EntityCategoryContains(categories.STRUCTURE, targetEntity) then
                chargesNeeded = math.ceil(targetEntity:GetHealth()/150)
            elseif EntityCategoryContains(categories.COMMAND, targetEntity) and not EntityCategoryContains(categories.TECH3, targetEntity) then
                chargesNeeded = math.ceil(targetEntity:GetHealth()/100)
            end
            
            --This is already after the initial 2000 has been drained from the weapon so we start from 0 and not 1
            local chargesUsed = math.min(chargesNeeded, chargesAvailable + 1)
            
            --cap our damage at 15000, so you cant own exps super easy.
            chargesUsed = math.min(chargesUsed, 15)
            
            local energyNeeded = math.max((chargesUsed)*2000 - 2000, 0) --we subtract the initial charge from the cost
            
            --drain the energy
            CreateEconomyEvent(self:GetLauncher(), energyNeeded, 0, 0.1)
            
            --apply our buffs
            self.DamageData.DamageAmount = 1000*chargesUsed
            --acus take 10x less damage so 100 per charge
            --buildings take 6.67x less damage so 150 per charge
            

            
            --logging - remember that we have one free charge to use from the weapon drain.
            
            -- WARN('target current hp: ' .. targetEntity:GetHealth())
            -- WARN('charges available: ' .. chargesAvailable)
            -- WARN('charges needed for target: ' .. chargesNeeded)
            -- WARN('charges used: ' .. chargesUsed)
            -- WARN('energy drained: ' .. energyNeeded)
        end
        
        TLaserBotProjectile.OnImpact(self, targetType, targetEntity)
    end,

}

TypeClass = TDFOverCharge01

