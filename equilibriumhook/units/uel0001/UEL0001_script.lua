--UEF ACU

local oldUEL0001 = UEL0001
local SeabedRevealFile = import('/lua/SeabedReveal.lua') --import our intel relay entity code
local SeabedReveal = SeabedRevealFile.SeabedReveal --this part applies to the weapon
local SeabedRevealUnit = SeabedRevealFile.SeabedRevealUnit --this part applies to the unit

TDFZephyrCannonWeapon = SeabedReveal(TDFZephyrCannonWeapon) --inject our revealing code in here
--SDFSinnuntheWeapon = SeabedReveal(SDFSinnuntheWeapon) --inject our revealing code in here
oldUEL0001 = SeabedRevealUnit(oldUEL0001)

UEL0001 = Class(oldUEL0001) {
    Weapons = {
        DeathWeapon = Class(DeathNukeWeapon) {},
        RightZephyr = Class(TDFZephyrCannonWeapon) {},
        OverCharge = Class(TDFOverchargeWeapon) {},
        AutoOverCharge = Class(TDFOverchargeWeapon) {},
        TacMissile = Class(TIFCruiseMissileLauncher) {},
        TacNukeMissile = Class(TIFCruiseMissileLauncher) {},
    },
    
    RebuildPod = function(self, PodNumber)
        if PodNumber == 1 then
            -- Force pod rebuilds to queue up
            if self.RebuildingPod2 ~= nil then
                WaitFor(self.RebuildingPod2)
            end
            if self.HasLeftPod == true then
                self.RebuildingPod = CreateEconomyEvent(self, 750, 75, 15, self.SetWorkProgress) --drones cheaper to rebuild than build
                self:RequestRefreshUI()
                WaitFor(self.RebuildingPod)
                self:SetWorkProgress(0.0)
                RemoveEconomyEvent(self, self.RebuildingPod)
                self.RebuildingPod = nil
                local location = self:GetPosition('AttachSpecial02')
                local pod = CreateUnitHPR('UEA0001', self:GetArmy(), location[1], location[2], location[3], 0, 0, 0)
                pod:SetParent(self, 'LeftPod')
                pod:SetCreator(self)
                pod:UpdateBuildRate(self.TechUpgrade or 1)
                self.Trash:Add(pod)
                self.LeftPod = pod
            end
        elseif PodNumber == 2 then
            -- Force pod rebuilds to queue up
            if self.RebuildingPod ~= nil then
                WaitFor(self.RebuildingPod)
            end
            if self.HasRightPod == true then
                self.RebuildingPod2 = CreateEconomyEvent(self, 750, 75, 15, self.SetWorkProgress) --drones cheaper to rebuild than build
                self:RequestRefreshUI()
                WaitFor(self.RebuildingPod2)
                self:SetWorkProgress(0.0)
                RemoveEconomyEvent(self, self.RebuildingPod)
                self.RebuildingPod2 = nil
                local location = self:GetPosition('AttachSpecial01')
                local pod = CreateUnitHPR('UEA0003', self:GetArmy(), location[1], location[2], location[3], 0, 0, 0)
                pod:SetParent(self, 'RightPod')
                pod:SetCreator(self)
                pod:UpdateBuildRate(self.TechUpgrade or 1)
                --add build restrictions since cd-2 is from the sacu
                pod:AddBuildRestriction( categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
                -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
                pod:updateBuildRestrictions()
                self.Trash:Add(pod)
                self.RightPod = pod
            end
        end
        self:RequestRefreshUI()
    end,

    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)

        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end
        if enh == 'LeftPod' then
            local location = self:GetPosition('AttachSpecial02')
            local pod = CreateUnitHPR('UEA0001', self:GetArmy(), location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'LeftPod')
            pod:SetCreator(self)
            pod:UpdateBuildRate(self.TechUpgrade or 1)
            self.Trash:Add(pod)
            self.HasLeftPod = true
            self.LeftPod = pod
        elseif enh == 'RightPod' then --now spawns the CD-2 because its epic to have both, theyre identical anyway since br is set (cd2 is for scus as well)
            local location = self:GetPosition('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0003', self:GetArmy(), location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'RightPod')
            pod:SetCreator(self)
            pod:UpdateBuildRate(self.TechUpgrade or 1)
            --add build restrictions since cd-2 is from the sacu
            pod:AddBuildRestriction( categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
            -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
            pod:updateBuildRestrictions()
            self.Trash:Add(pod)
            self.HasRightPod = true
            self.RightPod = pod
        elseif enh == 'LeftPodRemove' or enh == 'RightPodRemove' then
            if self.HasLeftPod == true then
                self.HasLeftPod = false
                if self.LeftPod and not self.LeftPod.Dead then
                    self.LeftPod:Kill()
                    self.LeftPod = nil
                end
                if self.RebuildingPod ~= nil then
                    RemoveEconomyEvent(self, self.RebuildingPod)
                    self.RebuildingPod = nil
                end
            end
            if self.HasRightPod == true then
                self.HasRightPod = false
                if self.RightPod and not self.RightPod.Dead then
                    self.RightPod:Kill()
                    self.RightPod = nil
                end
                if self.RebuildingPod2 ~= nil then
                    RemoveEconomyEvent(self, self.RebuildingPod2)
                    self.RebuildingPod2 = nil
                end
            end
            KillThread(self.RebuildThread)
            KillThread(self.RebuildThread2)
        elseif enh == 'Teleporter' then
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            self:RemoveCommandCap('RULEUCC_Teleport')
        elseif enh == 'Shield' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:CreateShield(bp)
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
        elseif enh == 'ShieldRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            RemoveUnitEnhancement(self, 'ShieldRemove')
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
        elseif enh =='AdvancedEngineering' then
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['UEFACUT2BuildRate'] then
                BuffBlueprint {
                    Name = 'UEFACUT2BuildRate',
                    DisplayName = 'UEFACUT2BuildRate',
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
            Buff.ApplyBuff(self, 'UEFACUT2BuildRate')
            -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
            self:updateBuildRestrictions()
            self.TechUpgrade = 2
            if self.RightPod then
                self.RightPod:UpdateBuildRate(self.TechUpgrade or 1)
            end
            if self.LeftPod then
                self.LeftPod:UpdateBuildRate(self.TechUpgrade or 1)
            end
        elseif enh =='AdvancedEngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction( categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
            self:AddBuildRestriction( categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
            if Buff.HasBuff( self, 'UEFACUT2BuildRate' ) then
                Buff.RemoveBuff( self, 'UEFACUT2BuildRate' )
            end
            -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
            self:updateBuildRestrictions()
            self.TechUpgrade = 1
            if self.RightPod then
                self.RightPod:UpdateBuildRate(self.TechUpgrade or 1)
            end
            if self.LeftPod then
                self.LeftPod:UpdateBuildRate(self.TechUpgrade or 1)
            end
        elseif enh =='T3Engineering' then
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['UEFACUT3BuildRate'] then
                BuffBlueprint {
                    Name = 'UEFACUT3BuildRate',
                    DisplayName = 'UEFCUT3BuildRate',
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
            Buff.ApplyBuff(self, 'UEFACUT3BuildRate')
            -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
            self:updateBuildRestrictions()
            self.TechUpgrade = 3
            if self.RightPod then
                self.RightPod:UpdateBuildRate(self.TechUpgrade or 1)
            end
            if self.LeftPod then
                self.LeftPod:UpdateBuildRate(self.TechUpgrade or 1)
            end
        elseif enh =='T3EngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            if Buff.HasBuff( self, 'UEFACUT3BuildRate' ) then
                Buff.RemoveBuff( self, 'UEFACUT3BuildRate' )
            end
            self:AddBuildRestriction( categories.UEF * ( categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
            -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
            self:updateBuildRestrictions()
            self.TechUpgrade = 1
            if self.RightPod then
                self.RightPod:UpdateBuildRate(self.TechUpgrade or 1)
            end
            if self.LeftPod then
                self.LeftPod:UpdateBuildRate(self.TechUpgrade or 1)
            end
        elseif enh =='DamageStabilization' then
            if not Buffs['UEFACUDamageStabilization'] then
                BuffBlueprint {
                    Name = 'UEFACUDamageStabilization',
                    DisplayName = 'UEFACUDamageStabilization',
                    BuffType = 'DamageStabilization',
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
            Buff.ApplyBuff(self, 'UEFACUDamageStabilization')
        elseif enh =='DamageStabilizationRemove' then
            if Buff.HasBuff( self, 'UEFACUDamageStabilization' ) then
                Buff.RemoveBuff( self, 'UEFACUDamageStabilization' )
            end
        elseif enh =='HeavyAntiMatterCannon' then
            local wep = self:GetWeaponByLabel('RightZephyr')
            wep:AddDamageMod(bp.ZephyrDamageMod)        
            wep:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius or 44)
        elseif enh =='HeavyAntiMatterCannonRemove' then
            local bp = self:GetBlueprint().Enhancements['HeavyAntiMatterCannon']
            if not bp then return end
            local wep = self:GetWeaponByLabel('RightZephyr')
            wep:AddDamageMod(-bp.ZephyrDamageMod)
            local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
            wep:ChangeMaxRadius(bpDisrupt or 22)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt or 22)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpDisrupt or 22)
        elseif enh == 'ResourceAllocation' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        elseif enh =='TacticalMissile' then
            self:AddCommandCap('RULEUCC_Tactical')
            self:AddCommandCap('RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('TacMissile', true)
        elseif enh =='TacticalNukeMissile' then
            self:RemoveCommandCap('RULEUCC_Tactical')
            self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
            self:AddCommandCap('RULEUCC_Nuke')
            self:AddCommandCap('RULEUCC_SiloBuildNuke')
            self:SetWeaponEnabledByLabel('TacMissile', false)
            self:SetWeaponEnabledByLabel('TacNukeMissile', true)
            local amt = self:GetTacticalSiloAmmoCount()
            self:RemoveTacticalSiloAmmo(amt or 0)
            self:StopSiloBuild()
        elseif enh == 'TacticalMissileRemove' or enh == 'TacticalNukeMissileRemove' then
            self:RemoveCommandCap('RULEUCC_Nuke')
            self:RemoveCommandCap('RULEUCC_SiloBuildNuke')
            self:RemoveCommandCap('RULEUCC_Tactical')
            self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('TacMissile', false)
            self:SetWeaponEnabledByLabel('TacNukeMissile', false)
            local amt = self:GetTacticalSiloAmmoCount()
            self:RemoveTacticalSiloAmmo(amt or 0)
            local amt = self:GetNukeSiloAmmoCount()
            self:RemoveNukeSiloAmmo(amt or 0)
            self:StopSiloBuild()
        end
    end,
}

TypeClass = UEL0001
