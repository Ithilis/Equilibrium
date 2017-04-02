-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0301/UEL0301_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  UEF Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local Shield = import('/lua/shield.lua').Shield
local EffectUtil = import('/lua/EffectUtilities.lua')
local CommandUnit = import('/lua/defaultunits.lua').CommandUnit
local TWeapons = import('/lua/terranweapons.lua')
local TDFHeavyPlasmaCannonWeapon = TWeapons.TDFHeavyPlasmaCannonWeapon
local SCUDeathWeapon = import('/lua/sim/defaultweapons.lua').SCUDeathWeapon

OldUEL0301 = UEL0301

UEL0301 = Class(OldUEL0301) {
    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end
        if enh == 'Pod' then
            if not self.HasPod then --added this so that there should be no way to stack pods, interested as to why this check wasnt here before (also in case this function is called twice cos of hooking)
                local location = self:GetPosition('AttachSpecial01')
                local pod = CreateUnitHPR('UEA0003', self:GetArmy(), location[1], location[2], location[3], 0, 0, 0)
                pod:SetParent(self, 'Pod')
                pod:SetCreator(self)
                self.Trash:Add(pod)
                self.HasPod = true
                self.Pod = pod
            else
                WARN('trying to create pod when pod already exists!')
            end
        elseif enh == 'PodRemove' then
            if self.HasPod == true then
                self.HasPod = false
                if self.Pod and not self.Pod:BeenDestroyed() then
                    self.Pod:Kill()
                    self.Pod = nil
                end
                if self.RebuildingPod ~= nil then
                    RemoveEconomyEvent(self, self.RebuildingPod)
                    self.RebuildingPod = nil
                end
            end
            KillThread(self.RebuildThread)
        elseif enh == 'Shield' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bp)
        elseif enh == 'ShieldRemove' then
            RemoveUnitEnhancement(self, 'Shield')
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        elseif enh == 'ShieldGeneratorField' then
            self:DestroyShield()    
            ForkThread(function()
                WaitTicks(1)   
                self:CreateShield(bp)
                self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
                self:SetMaintenanceConsumptionActive()
            end)
        elseif enh == 'ShieldGeneratorFieldRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')    
        elseif enh =='ResourceAllocation' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
            self.NewDeathDamage = (bp.NewDeathDamage or 5000) --insert our new death damage value into our unit table
            --this will be picked up by DoDeathWeapon in unit.lua and replace the blueprint value.
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
            self.NewDeathDamage = (bp.NewDeathDamage or 2500)
            --we dont use self:GetBlueprint().Weapon[2].Damage because thats set to 5000 for some reason
        elseif enh == 'SensorRangeEnhancer' then
            self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
            self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
        elseif enh == 'SensorRangeEnhancerRemove' then
            local bpIntel = self:GetBlueprint().Intel
            self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
            self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
        elseif enh == 'RadarJammer' then
            self:SetIntelRadius('Jammer', bp.NewJammerRadius or 26)
            self.RadarJammerEnh = true 
            self:EnableUnitIntel('Enhancement', 'Jammer')
            self:AddToggleCap('RULEUTC_JammingToggle')              
        elseif enh == 'RadarJammerRemove' then
            local bpIntel = self:GetBlueprint().Intel
            self:SetIntelRadius('Jammer', 0)
            self:DisableUnitIntel('Enhancement', 'Jammer')
            self.RadarJammerEnh = false
            self:RemoveToggleCap('RULEUTC_JammingToggle')
        elseif enh =='AdvancedCoolingUpgrade' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:ChangeRateOfFire(bp.NewRateOfFire)
        elseif enh =='AdvancedCoolingUpgradeRemove' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:ChangeRateOfFire(self:GetBlueprint().Weapon[1].RateOfFire or 1)
        elseif enh =='HighExplosiveOrdnance' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
        elseif enh =='HighExplosiveOrdnanceRemove' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius or -2)
            wep:ChangeMaxRadius(self:GetBlueprint().Weapon[1].MaxRadius or 23)
        end
        self:AdjustPriceOnEnh() --EQ: we adjust our sacus price when we get or lose an enhancement
    end,

    AdjustPriceOnEnh = function(self)
        -- change cost of the new unit to match unit base cost + enhancement costs.
        
        local bp = self:GetBlueprint()
        
        -- In the case of presets, use the base bp for prices. and stuff.
        if bp.EnhancementPresetAssigned.BaseBlueprintId then
            bp = GetUnitBlueprintByName(bp.EnhancementPresetAssigned.BaseBlueprintId)
        end
        
        local e, m, t = 0, 0, 0
        
        local enhCommon = import('/lua/enhancementcommon.lua') --get our unit enhs
        local unitEnhancements = enhCommon.GetEnhancements(self:GetEntityId())
        
        if unitEnhancements then --If we have no enh this is a nil value, so we bail
            for k, enh in unitEnhancements do
                -- replaced continue by reversing if statement
                if bp.Enhancements[enh] then
                    e = e + (bp.Enhancements[enh].BuildCostEnergy or 0)
                    m = m + (bp.Enhancements[enh].BuildCostMass or 0)
                    t = t + (bp.Enhancements[enh].BuildTime or 0)
                    -- HUSSAR added name of the enhancement so that preset units cannot be built
                end
            end
        end
        
        --add our enh costs onto our base costs.
        self.BuildCostM = bp.Economy.BuildCostMass + m
        self.BuildCostE = bp.Economy.BuildCostEnergy + e
        self.BuildT = bp.Economy.BuildTime + t
        
        --WARN('enhancement mass/energy/time: ' .. m .. ', ' .. e .. ', ' .. t)
        --WARN('total mass/energy/time: ' .. self.BuildCostM .. ', ' .. self.BuildCostE .. ', ' .. self.BuildT)
    end,

    CreateWreckageProp = function( self, overkillRatio )
    --intercept the wreckage creation code so it changes the wreckage value as well. we just pass a modified overkill multiplier for that.
        local bp = self:GetBlueprint()
        
        local adjustedOKRMass = ((bp.Economy.BuildCostMass - self.BuildCostM) / bp.Economy.BuildCostMass) + (overkillRatio or 1)
        --WARN('regular reclaim value: '..bp.Economy.BuildCostMass*0.81 .. ' adjusted reclaim value: '..self.BuildCostM*0.81)
        CommandUnit.CreateWreckageProp(self, adjustedOKRMass)
    end,
}

TypeClass = UEL0301
