        ------------------------------------------------------------------------------------------------------------------------------------
        ---- TIER 1 ENERGY STORAGE
        ------------------------------------------------------------------------------------------------------------------------------------
 
        T1EnergyStorageAdjacencyBuffs = {
            'T1EnergyStorageEnergyProductionBonusSize4-2',
            'T1EnergyStorageEnergyProductionBonusSize8-2',
            'T1EnergyStorageEnergyProductionBonusSize12-2',
            'T1EnergyStorageEnergyProductionBonusSize16-2',
            'T1EnergyStorageEnergyProductionBonusSize20-2',
        }
 
        ------------------------------------------------------------------------------------------------------------------------------------
        ---- ENERGY PRODUCTION BONUS - TIER 1 ENERGY STORAGE
        ------------------------------------------------------------------------------------------------------------------------------------
 
        BuffBlueprint {
            Name = 'T1EnergyStorageEnergyProductionBonusSize4-2',
            DisplayName = 'T1EnergyStorageEnergyProductionBonus',
            BuffType = 'MASSBUILDBONUS',
            Stacks = 'ALWAYS',
            Duration = -1,
            EntityCategory = 'STRUCTURE SIZE4',
            BuffCheckFunction = AdjBuffFuncs.EnergyProductionBuffCheck,
            OnBuffAffect = AdjBuffFuncs.EnergyProductionBuffAffect,
            OnBuffRemove = AdjBuffFuncs.EnergyProductionBuffRemove,
            Affects = {
                EnergyProduction = {
                    Add = 0.25,     --from 0,125 Add by Ithilis
                    Mult = 1.0,
                },
            },
        }
 
        BuffBlueprint {
            Name = 'T1EnergyStorageEnergyProductionBonusSize8-2',
            DisplayName = 'T1EnergyStorageEnergyProductionBonus',
            BuffType = 'MASSBUILDBONUS',
            Stacks = 'ALWAYS',
            Duration = -1,
            EntityCategory = 'STRUCTURE SIZE8',
            BuffCheckFunction = AdjBuffFuncs.EnergyProductionBuffCheck,
            OnBuffAffect = AdjBuffFuncs.EnergyProductionBuffAffect,
            OnBuffRemove = AdjBuffFuncs.EnergyProductionBuffRemove,
            Affects = {
                EnergyProduction = {
                    Add = 0.125,    --from 0,0625
                    Mult = 1.0,
                },
            },
        }
 
        BuffBlueprint {
            Name = 'T1EnergyStorageEnergyProductionBonusSize12-2',
            DisplayName = 'T1EnergyStorageEnergyProductionBonus',
            BuffType = 'MASSBUILDBONUS',
            Stacks = 'ALWAYS',
            Duration = -1,
            EntityCategory = 'STRUCTURE SIZE12',
            BuffCheckFunction = AdjBuffFuncs.EnergyProductionBuffCheck,
            OnBuffAffect = AdjBuffFuncs.EnergyProductionBuffAffect,
            OnBuffRemove = AdjBuffFuncs.EnergyProductionBuffRemove,
            Affects = {
                EnergyProduction = {
                    Add = 0.083334,     --from 0,041667
                    Mult = 1.0,
                },
            },
        }
 
        BuffBlueprint {
            Name = 'T1EnergyStorageEnergyProductionBonusSize16-2',
            DisplayName = 'T1EnergyStorageEnergyProductionBonus',
            BuffType = 'MASSBUILDBONUS',
            Stacks = 'ALWAYS',
            Duration = -1,
            EntityCategory = 'STRUCTURE SIZE16',
            BuffCheckFunction = AdjBuffFuncs.EnergyProductionBuffCheck,
            OnBuffAffect = AdjBuffFuncs.EnergyProductionBuffAffect,
            OnBuffRemove = AdjBuffFuncs.EnergyProductionBuffRemove,
            Affects = {
                EnergyProduction = {
                    Add = 0.0625,       --from 0.03125
                    Mult = 1.0,
                },
            },
        }
 
        BuffBlueprint {
            Name = 'T1EnergyStorageEnergyProductionBonusSize20-2',
            DisplayName = 'T1EnergyStorageEnergyProductionBonus',
            BuffType = 'MASSBUILDBONUS',
            Stacks = 'ALWAYS',
            Duration = -1,
            EntityCategory = 'STRUCTURE SIZE20',
            BuffCheckFunction = AdjBuffFuncs.EnergyProductionBuffCheck,
            OnBuffAffect = AdjBuffFuncs.EnergyProductionBuffAffect,
            OnBuffRemove = AdjBuffFuncs.EnergyProductionBuffRemove,
            Affects = {
                EnergyProduction = {
                    Add = 0.05,         --from 0,025
                    Mult = 1.0,
                },
            },
        }
    
        ------------------------------------------------------------------------------------------------------------------------------------
        ---- TIER 1 MASS STORAGE
        ------------------------------------------------------------------------------------------------------------------------------------

        T1MassStorageAdjacencyBuffs = {
            'T1MassStorageMassProductionBonusSize4-2',
            'T1MassStorageMassProductionBonusSize8',
            'T1MassStorageMassProductionBonusSize12',
            'T1MassStorageMassProductionBonusSize16',
            'T1MassStorageMassProductionBonusSize20',
        }
            
        BuffBlueprint {
            Name = 'T1MassStorageMassProductionBonusSize4-2',
            DisplayName = 'T1MassStorageMassProductionBonus',
            BuffType = 'MASSBUILDBONUS',
            Stacks = 'ALWAYS',
            Duration = -1,
            EntityCategory = 'STRUCTURE SIZE4',
            BuffCheckFunction = AdjBuffFuncs.MassProductionBuffCheck,
            OnBuffAffect = AdjBuffFuncs.MassProductionBuffAffect,
            OnBuffRemove = AdjBuffFuncs.MassProductionBuffRemove,
            Affects = {
                MassProduction = {
                    Add = 0.0625,    --from 12,5%
                    Mult = 1.0,
                },
            },
        }