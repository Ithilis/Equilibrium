--Aeon Commander Script

local oldUAL0001 = UAL0001
UAL0001 = Class(oldUAL0001) {




    OnLayerChange = function(self, new, old)
        ACUUnit.OnLayerChange(self, new, old)
        if( old != 'None' ) then
            if( new == 'Air' ) then
                self:SetWeaponEnabledByLabel('OverCharge', false)
                self:SetWeaponEnabledByLabel('RightDisruptor', false)
            elseif( new == 'Land' ) then
                self:SetWeaponEnabledByLabel('OverCharge', true)
                self:SetWeaponEnabledByLabel('RightDisruptor', true)
            end
        end
    end,
    
    
    
    
    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        --Resource Allocation
        if enh == 'ResourceAllocation' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationAdvanced' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationAdvancedRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
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
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:ForkThread(self.CreateHeavyShield, bp)
        elseif enh == 'ShieldHeavyRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        --Teleporter
        elseif enh == 'Teleporter' then
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            self:RemoveCommandCap('RULEUCC_Teleport')
    
        --Chrono Dampener
        elseif enh == 'ChronoDampener' then
            self:SetWeaponEnabledByLabel('ChronoDampener', true)
            
            if not Buffs['AeonACUChronoBonus'] then
                BuffBlueprint {
                    Name = 'AeonACUChronoBonus',
                    DisplayName = 'AeonACUChronoBonus',
                    BuffType = 'ACUChronoBonus',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'AeonACUChronoBonus')
        elseif enh =='ChronoDampenerRemove' then
            self:SetWeaponEnabledByLabel('ChronoDampener', false)
            if Buff.HasBuff( self, 'AeonACUChronoBonus' ) then
                Buff.RemoveBuff( self, 'AeonACUChronoBonus' )
            end

        --T2 Engineering
        elseif enh =='AdvancedEngineering' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then return end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            
        if not Buffs['AeonACUT2BuildRate'] then
                BuffBlueprint {
                    Name = 'AeonACUT2BuildRate',
                    DisplayName = 'AeonACUT2BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'AeonACUT2BuildRate')
        -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
        self:updateBuildRestrictions()
        elseif enh =='AdvancedEngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction( categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
            if Buff.HasBuff( self, 'AeonACUT2BuildRate' ) then
                Buff.RemoveBuff( self, 'AeonACUT2BuildRate' )
         end
        -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
        self:updateBuildRestrictions()
        --T3 Engineering
        elseif enh =='T3Engineering' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then return end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['AeonACUT3BuildRate'] then
                BuffBlueprint {
                    Name = 'AeonACUT3BuildRate',
                    DisplayName = 'AeonCUT3BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'AeonACUT3BuildRate')
        -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
        self:updateBuildRestrictions()
        elseif enh =='T3EngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction( categories.AEON * ( categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
            if Buff.HasBuff( self, 'AeonACUT3BuildRate' ) then
                Buff.RemoveBuff( self, 'AeonACUT3BuildRate' )
         end
        -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
        self:updateBuildRestrictions()
        --Crysalis Beam
        elseif enh == 'CrysalisBeam' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius or 44)
        elseif enh == 'CrysalisBeamRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
            wep:ChangeMaxRadius(bpDisrupt or 23)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt or 23)
        --Heat Sink Augmentation
        elseif enh == 'HeatSink' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeRateOfFire(bp.NewRateOfFire or 2)
        elseif enh == 'HeatSinkRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            local bpDisrupt = self:GetBlueprint().Weapon[1].RateOfFire
            wep:ChangeRateOfFire(bpDisrupt or 1)
        --Enhanced Sensor Systems
        elseif enh == 'EnhancedSensors' then
            self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
            self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
        elseif enh == 'EnhancedSensorsRemove' then
            local bpIntel = self:GetBlueprint().Intel
            self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
            self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
      end
    end,
}

TypeClass = UAL0001
