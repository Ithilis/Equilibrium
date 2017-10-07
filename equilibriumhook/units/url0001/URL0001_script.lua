
--Cybran ACU

local oldURL0001 = URL0001
local SeabedRevealFile = import('/lua/SeabedReveal.lua') --import our intel relay entity code
local SeabedReveal = SeabedRevealFile.SeabedReveal --this part applies to the weapon
local SeabedRevealUnit = SeabedRevealFile.SeabedRevealUnit --this part applies to the unit

CCannonMolecularWeapon = SeabedReveal(CCannonMolecularWeapon) --inject our revealing code in here
--SDFSinnuntheWeapon = SeabedReveal(SDFSinnuntheWeapon) --inject our revealing code in here
oldURL0001 = SeabedRevealUnit(oldURL0001)
URL0001 = Class(oldURL0001) {
 Weapons = {
        DeathWeapon = Class(DeathNukeWeapon) {},
        RightRipper = Class(CCannonMolecularWeapon) {},
        Torpedo = Class(CANTorpedoLauncherWeapon) {},
        },



    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)
        if enh == 'Teleporter' then
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            RemoveUnitEnhancement(self, 'Teleporter')
            RemoveUnitEnhancement(self, 'TeleporterRemove')
            self:RemoveCommandCap('RULEUCC_Teleport')
        elseif enh == 'StealthGenerator' then
            self:AddToggleCap('RULEUTC_CloakToggle')
            if self.IntelEffectsBag then
                EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
                self.IntelEffectsBag = nil
            end
            self.CloakEnh = false
            self.StealthEnh = true
            self:EnableUnitIntel('Enhancement', 'RadarStealth')
            self:EnableUnitIntel('Enhancement', 'SonarStealth')
            if not Buffs['CybranACUStealthBonus'] then
            local bp = self:GetBlueprint().Enhancements[enh]
               BuffBlueprint {
                    Name = 'CybranACUStealthBonus',
                    DisplayName = 'CybranACUStealthBonus',
                    BuffType = 'ACUSTEALTHBONUS',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                } 
            end
            if Buff.HasBuff( self, 'CybranACUStealthBonus' ) then
                Buff.RemoveBuff( self, 'CybranACUStealthBonus' )
            end  
            Buff.ApplyBuff(self, 'CybranACUStealthBonus')
        elseif enh == 'StealthGeneratorRemove' then
            self:RemoveToggleCap('RULEUTC_CloakToggle')
            self:DisableUnitIntel('Enhancement', 'RadarStealth')
            self:DisableUnitIntel('Enhancement', 'SonarStealth')
            if Buff.HasBuff( self, 'CybranACUStealthBonus' ) then
                Buff.RemoveBuff( self, 'CybranACUStealthBonus' )
            end
            self.StealthEnh = false
            self.CloakEnh = false
            self.StealthFieldEffects = false
            self.CloakingEffects = false
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
        elseif enh == 'CloakingGenerator' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then return end
            self.StealthEnh = false
            self.CloakEnh = true
            self:EnableUnitIntel('Enhancement', 'Cloak')
            if Buff.HasBuff( self, 'CybranACUStealthBonus' ) then
                Buff.RemoveBuff( self, 'CybranACUStealthBonus' )
            end              
            if not Buffs['CybranACUCloakBonus'] then
               BuffBlueprint {
                    Name = 'CybranACUCloakBonus',
                    DisplayName = 'CybranACUCloakBonus',
                    BuffType = 'ACUCLOAKBONUS',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
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
            if Buff.HasBuff(self, 'CybranACUCloakBonus') then
                Buff.RemoveBuff(self, 'CybranACUCloakBonus')
            end
            Buff.ApplyBuff(self, 'CybranACUCloakBonus')
        elseif enh == 'CloakingGeneratorRemove' then
            self:RemoveToggleCap('RULEUTC_CloakToggle')
            self:DisableUnitIntel('Enhancement', 'Cloak')
            self:DisableUnitIntel('Enhancement', 'RadarStealth')
            self:DisableUnitIntel('Enhancement', 'SonarStealth')
            self.CloakEnh = false
            self.StealthEnh = false
            if Buff.HasBuff(self, 'CybranACUCloakBonus') then
                Buff.RemoveBuff(self, 'CybranACUCloakBonus')
            end
            if Buff.HasBuff( self, 'CybranACUStealthBonus' ) then
                Buff.RemoveBuff( self, 'CybranACUStealthBonus' )
            end              
        -- T2 Engineering
        elseif enh =='AdvancedEngineering' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then return end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['CybranACUT2BuildRate'] then
                BuffBlueprint {
                    Name = 'CybranACUT2BuildRate',
                    DisplayName = 'CybranACUT2BuildRate',
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
            Buff.ApplyBuff(self, 'CybranACUT2BuildRate')
            self:updateBuildRestrictions()
        elseif enh =='AdvancedEngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction(categories.CYBRAN * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            if Buff.HasBuff(self, 'CybranACUT2BuildRate') then
                Buff.RemoveBuff(self, 'CybranACUT2BuildRate')
            end
            self:updateBuildRestrictions()
        -- T3 Engineering
        elseif enh =='T3Engineering' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then return end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['CybranACUT3BuildRate'] then
                BuffBlueprint {
                    Name = 'CybranACUT3BuildRate',
                    DisplayName = 'CybranCUT3BuildRate',
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
            Buff.ApplyBuff(self, 'CybranACUT3BuildRate')
            self:updateBuildRestrictions()
        elseif enh =='T3EngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            if Buff.HasBuff(self, 'CybranACUT3BuildRate') then
                Buff.RemoveBuff(self, 'CybranACUT3BuildRate')
            end
            self:AddBuildRestriction(categories.CYBRAN * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            self:updateBuildRestrictions()
        elseif enh =='CoolingUpgrade' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local wep = self:GetWeaponByLabel('RightRipper')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 28)
            self.normalRange = bp.NewMaxRadius or 28
            wep:ChangeRateOfFire(bp.NewRateOfFire or 2)
            local microwave = self:GetWeaponByLabel('MLG')
            microwave:ChangeMaxRadius(bp.NewMaxRadius or 28)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius or 28)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius or 28)
            --EQ: increase torpedo upgrade range too
            local torpRange = self:GetBlueprint().Weapon[7].MaxRadius
            self:GetWeaponByLabel('Torpedo'):ChangeMaxRadius(torpRange + 10)
            if not (self:GetCurrentLayer() == 'Seabed' and self:HasEnhancement('NaniteTorpedoTube')) then
                self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.normalRange)
            end
        elseif enh == 'CoolingUpgradeRemove' then
            local wep = self:GetWeaponByLabel('RightRipper')
            local wepBp = self:GetBlueprint().Weapon
            for k, v in wepBp do
                if v.Label == 'RightRipper' then
                    wep:ChangeRateOfFire(v.RateOfFire or 1)
                    wep:ChangeMaxRadius(v.MaxRadius or 23)
                    self.normalRange = v.MaxRadius or 23
                    self:GetWeaponByLabel('MLG'):ChangeMaxRadius(v.MaxRadius or 23)
                    self:GetWeaponByLabel('OverCharge'):ChangeMaxRadius(v.MaxRadius or 23)
                    self:GetWeaponByLabel('AutoOverCharge'):ChangeMaxRadius(v.MaxRadius or 23)
                    self.normalRange = v.MaxRadius or 22
                    if not (self:GetCurrentLayer() == 'Seabed' and self:HasEnhancement('NaniteTorpedoTube')) then
                        self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.normalRange)
                    end
                    break
                end
            end
            --EQ: reset the range of torpedo upgrade
            local torpRange = self:GetBlueprint().Weapon[7].MaxRadius
            self:GetWeaponByLabel('Torpedo'):ChangeMaxRadius(torpRange)
        elseif enh == 'MicrowaveLaserGenerator' then
            self:SetWeaponEnabledByLabel('MLG', true)
        elseif enh == 'MicrowaveLaserGeneratorRemove' then
            self:SetWeaponEnabledByLabel('MLG', false)
        elseif enh == 'NaniteTorpedoTube' then
            self:SetWeaponEnabledByLabel('Torpedo', true)
            self:EnableUnitIntel('Enhancement', 'Sonar')
            if self:GetCurrentLayer() == 'Seabed' then
                self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.torpRange)
            end
        elseif enh == 'NaniteTorpedoTubeRemove' then
            self:SetWeaponEnabledByLabel('Torpedo', false)
            self:DisableUnitIntel('Enhancement', 'Sonar')
            if self:GetCurrentLayer() == 'Seabed' then
                self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.normalRange)
            end
        end
    end,

}

TypeClass = URL0001
