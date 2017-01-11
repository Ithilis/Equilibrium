--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0301/UAL0301_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Aeon Sub Commander Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CommandUnit = import('/lua/defaultunits.lua').CommandUnit

local AWeapons = import('/lua/aeonweapons.lua')
local ADFReactonCannon = AWeapons.ADFReactonCannon
local SCUDeathWeapon = import('/lua/sim/defaultweapons.lua').SCUDeathWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')
local Buff = import('/lua/sim/Buff.lua')

UAL0301 = Class(CommandUnit) {
    Weapons = {
        RightReactonCannon = Class(ADFReactonCannon) {},
        DeathWeapon = Class(SCUDeathWeapon) {},
    },

    __init = function(self)
        CommandUnit.__init(self, 'RightReactonCannon')
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        CommandUnit.OnStopBuild(self, unitBeingBuilt)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel('RightReactonCannon', true)
        self:GetWeaponManipulatorByLabel('RightReactonCannon'):SetHeadingPitch( self.BuildArmManipulator:GetHeadingPitch() )
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Turbine', true)
        self:SetupBuildBones()
    end,

    CreateBuildEffects = function( self, unitBeingBuilt, order )
        EffectUtil.CreateAeonCommanderBuildingEffects( self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
    end,

    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end
        --Teleporter
        if enh == 'Teleporter' then
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            self:RemoveCommandCap('RULEUCC_Teleport')
        --Shields
        elseif enh == 'Shield' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bp)
        elseif enh == 'ShieldRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        elseif enh == 'ShieldHeavy' then
            self:ForkThread(self.CreateHeavyShield, bp)
        elseif enh == 'ShieldHeavyRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        --ResourceAllocation
        elseif enh =='ResourceAllocation' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
            self.NewDeathDamage = bp.NewDeathDamage --insert our new death damage value into our unit table
            --this will be picked up by DoDeathWeapon in unit.lua and replace the blueprint value.
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
            self.NewDeathDamage = (bp.NewDeathDamage or 2500)
            --we dont use self:GetBlueprint().Weapon[2].Damage because thats set to 5000 for some reason
        --Engineering Focus Module
        elseif enh =='EngineeringFocusingModule' then
            if not Buffs['AeonSCUBuildRate'] then
                BuffBlueprint {
                    Name = 'AeonSCUBuildRate',
                    DisplayName = 'AeonSCUBuildRate',
                    BuffType = 'SCUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'AeonSCUBuildRate')
            self:AddCommandCap('RULEUCC_Sacrifice')            -- added by ithilis
        elseif enh == 'EngineeringFocusingModuleRemove' then
            self:RemoveCommandCap('RULEUCC_Sacrifice')        -- added by ithilis
            if Buff.HasBuff( self, 'AeonSCUBuildRate' ) then
                Buff.RemoveBuff( self, 'AeonSCUBuildRate' )
            end
        --SystemIntegrityCompensator
        elseif enh == 'SystemIntegrityCompensator' then
            local name = 'AeonSCURegenRate'
            if not Buffs[name] then
                BuffBlueprint {
                    Name = name,
                    DisplayName = name,
                    BuffType = 'SCUREGENRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        Regen = {
                            Add =  bp.NewRegenRate - self:GetBlueprint().Defense.RegenRate,
                            Mult = 1,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, name)        
        elseif enh == 'SystemIntegrityCompensatorRemove' then
            if Buff.HasBuff( self, 'AeonSCURegenRate' ) then
                Buff.RemoveBuff( self, 'AeonSCURegenRate' )
            end
            
        --sarcifice system moved to engineering upgrade
        
        --StabilitySupressant
        elseif enh =='StabilitySuppressant' then
            local wep = self:GetWeaponByLabel('RightReactonCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 0)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
        elseif enh =='StabilitySuppressantRemove' then
            local wep = self:GetWeaponByLabel('RightReactonCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 0)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
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


    CreateHeavyShield = function(self, bp)
        WaitTicks(1)
        self:CreateShield(bp)
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
    end
}

TypeClass = UAL0301
