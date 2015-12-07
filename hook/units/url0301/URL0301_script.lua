--Cybran Sub Commander Script

local oldURL0301 = URL0301
URL0301 = Class(oldURL0301) {


    OnStopBeingBuilt = function(self,builder,layer)
        CommandUnit.OnStopBeingBuilt(self,builder,layer)
        self:BuildManipulatorSetEnabled(false)
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('RadarStealthField')
        self:DisableUnitIntel('SonarStealthField')
        self:DisableUnitIntel('Cloak')
        self.LeftArmUpgrade = 'EngineeringArm'
        self.RightArmUpgrade = 'Disintegrator'
    end,


    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end
        if enh == 'CloakingGenerator' then
            self.StealthEnh = false
            self.CloakEnh = true
            self:EnableUnitIntel('Cloak')
            if not Buffs['CybranSCUCloakBonus'] then
               BuffBlueprint {
                    Name = 'CybranSCUCloakBonus',
                    DisplayName = 'CybranSCUCloakBonus',
                    BuffType = 'SCUCLOAKBONUS',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                    },
                }
            end
            if Buff.HasBuff( self, 'CybranSCUCloakBonus' ) then
                Buff.RemoveBuff( self, 'CybranSCUCloakBonus' )
            end
            Buff.ApplyBuff(self, 'CybranSCUCloakBonus')
        elseif enh == 'CloakingGeneratorRemove' then
            self:DisableUnitIntel('Cloak')
            self.StealthEnh = false
            self.CloakEnh = false
            self:RemoveToggleCap('RULEUTC_CloakToggle')
            if Buff.HasBuff( self, 'CybranSCUCloakBonus' ) then
                Buff.RemoveBuff( self, 'CybranSCUCloakBonus' )
            end
        elseif enh == 'StealthGenerator' then
            self:AddToggleCap('RULEUTC_CloakToggle')
            if self.IntelEffectsBag then
                EffectUtil.CleanupEffectBag(self,'IntelEffectsBag')
                self.IntelEffectsBag = nil
            end
            self.CloakEnh = false
            self.StealthEnh = true
            self:EnableUnitIntel('RadarStealthField')        -- by ithilis
            self:EnableUnitIntel('SonarStealthField')        -- by ithilis
        elseif enh == 'StealthGeneratorRemove' then
            self:RemoveToggleCap('RULEUTC_CloakToggle')
            self:DisableUnitIntel('RadarStealthField')    -- by ithilis
            self:DisableUnitIntel('SonarStealthField')    -- by ithilis
            self.StealthEnh = false
            self.CloakEnh = false
        elseif enh == 'NaniteMissileSystem' then
            self:ShowBone('AA_Gun', true)
            self:SetWeaponEnabledByLabel('NMissile', true)
        elseif enh == 'NaniteMissileSystemRemove' then
            self:HideBone('AA_Gun', true)
            self:SetWeaponEnabledByLabel('NMissile', false)
        elseif enh == 'SelfRepairSystem' then
            -- added by brute51 - fix for bug SCU regen upgrade doesnt stack with veteran bonus [140]
            CommandUnit.CreateEnhancement(self, enh)
            local bpRegenRate = self:GetBlueprint().Enhancements.SelfRepairSystem.NewRegenRate or 0
            if not Buffs['CybranSCURegenerateBonus'] then
               BuffBlueprint {
                    Name = 'CybranSCURegenerateBonus',
                    DisplayName = 'CybranSCURegenerateBonus',
                    BuffType = 'SCUREGENERATEBONUS',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        Regen = {
                            Add = bpRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            if Buff.HasBuff( self, 'CybranSCURegenerateBonus' ) then
                Buff.RemoveBuff( self, 'CybranSCURegenerateBonus' )
            end
            Buff.ApplyBuff(self, 'CybranSCURegenerateBonus')
        elseif enh == 'SelfRepairSystemRemove' then
            -- added by brute51 - fix for bug SCU regen upgrade doesnt stack with veteran bonus [140]
            CommandUnit.CreateEnhancement(self, enh)
            if Buff.HasBuff( self, 'CybranSCURegenerateBonus' ) then
                Buff.RemoveBuff( self, 'CybranSCURegenerateBonus' )
            end
        elseif enh =='ResourceAllocation' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        elseif enh =='Switchback' then
            if not Buffs['CybranSCUBuildRate'] then
                BuffBlueprint {
                    Name = 'CybranSCUBuildRate',
                    DisplayName = 'CybranSCUBuildRate',
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
            Buff.ApplyBuff(self, 'CybranSCUBuildRate')
        elseif enh == 'SwitchbackRemove' then
            if Buff.HasBuff( self, 'CybranSCUBuildRate' ) then
                Buff.RemoveBuff( self, 'CybranSCUBuildRate' )
            end

        --Fixed damage stacking infinitely and range not being reduced on removal (IceDreamer)
        elseif enh == 'FocusConvertor' then
            local wep = self:GetWeaponByLabel('RightDisintegrator')
            wep:AddDamageMod(bp.NewDamageMod or 0)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
            wep:AddDamageRadiusMod(bp.NewDamageRadius)        --ADD by itilis
        elseif enh == 'FocusConvertorRemove' then
            local wep = self:GetWeaponByLabel('RightDisintegrator')
            wep:AddDamageMod(-self:GetBlueprint().Enhancements['FocusConvertor'].NewDamageMod)
            wep:ChangeMaxRadius(self:GetBlueprint().Weapon[1].MaxRadius or 25)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)        --add by ihtilis
        elseif enh == 'EMPCharge' then
            local wep = self:GetWeaponByLabel('RightDisintegrator')
            wep:ReEnableBuff('STUN')
        elseif enh == 'EMPChargeRemove' then
            local wep = self:GetWeaponByLabel('RightDisintegrator')
            wep:DisableBuff('STUN')
        end
    end,
    
    
    OnIntelEnabled = function(self)
        CommandUnit.OnIntelEnabled(self)
        if self.CloakEnh and self:IsIntelEnabled('Cloak') then
            self:SetEnergyMaintenanceConsumptionOverride(self:GetBlueprint().Enhancements['CloakingGenerator'].MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self.CreateTerrainTypeEffects( self, self.IntelEffects.Cloak, 'FXIdle',  self:GetCurrentLayer(), nil, self.IntelEffectsBag )
            end
        elseif self.StealthEnh and self:IsIntelEnabled('RadarStealthField') and self:IsIntelEnabled('SonarStealthField') then
            self:SetEnergyMaintenanceConsumptionOverride(self:GetBlueprint().Enhancements['StealthGenerator'].MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self.CreateTerrainTypeEffects( self, self.IntelEffects.Field, 'FXIdle',  self:GetCurrentLayer(), nil, self.IntelEffectsBag )
            end
        end
    end,

    OnIntelDisabled = function(self)
        CommandUnit.OnIntelDisabled(self)
        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self,'IntelEffectsBag')
            self.IntelEffectsBag = nil
        end
        if self.CloakEnh and not self:IsIntelEnabled('Cloak') then
            self:SetMaintenanceConsumptionInactive()
        elseif self.StealthEnh and not self:IsIntelEnabled('RadarStealthField') and not self:IsIntelEnabled('SonarStealthField') then
            self:SetMaintenanceConsumptionInactive()
        end
    end

}

TypeClass = URL0301