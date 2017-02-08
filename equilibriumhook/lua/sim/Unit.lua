local multsTable = import('/lua/sim/BuffDefinitions.lua').MultsTable
local typeTable = import('/lua/sim/BuffDefinitions.lua').TypeTable

local oldUnit = Unit
Unit = Class(oldUnit) {

---------------
----VETERANCY------
---------------
    OnCreate = function(self) --this isnt great in terms of compatibility but we call on create to improve its performance.
    
        self.Instigators = {}
        self.totalDamageTaken = 0
        self.techLevel = self:FindTechLevel() --this bit added in eq
        
        Entity.OnCreate(self)
        --Turn off land bones if this unit has them.
        self:HideLandBones()
        --Set number of effects per damage depending on its volume
        local x, y, z = self:GetUnitSizes()
        local vol = x*y*z

        self:ShowPresetEnhancementBones()
        local damageamounts = 1
        if vol >= 20 then
            damageamounts = 6
            self.FxDamageScale = 2
        elseif vol >= 10 then
            damageamounts = 4
            self.FxDamageScale = 1.5
        elseif vol >= 0.5 then
            damageamounts = 2
        end
        self.FxDamage1Amount = self.FxDamage1Amount or damageamounts
        self.FxDamage2Amount = self.FxDamage2Amount or damageamounts
        self.FxDamage3Amount = self.FxDamage3Amount or damageamounts
        self.DamageEffectsBag = {
            {},
            {},
            {},
        }
        --Set up effect emitter bags
        self.MovementEffectsBag = {}
        self.IdleEffectsBag = {}
        self.TopSpeedEffectsBag = {}
        self.BeamExhaustEffectsBag = {}
        self.TransportBeamEffectsBag = {}
        self.BuildEffectsBag = TrashBag()
        self.ReclaimEffectsBag = TrashBag()
        self.OnBeingBuiltEffectsBag = TrashBag()
        self.CaptureEffectsBag = TrashBag()
        self.UpgradeEffectsBag = TrashBag()
        self.TeleportFxBag = TrashBag()

        --Store targets and attackers for proper Stealth management
        self.Targets = {}
        self.WeaponTargets = {}
        self.WeaponAttackers = {}

        --Set up veterancy
        self.xp = 0
        --self.Sync.xp = self.xp
        self.VeteranLevel = 0

        self.debris_Vector = Vector( 0, 0, 0 )

        --Get unit blueprint for setting variables
        local bp = self:GetBlueprint()
        --Define Economic modifications
        local bpEcon = bp.Economy
        self:SetConsumptionPerSecondEnergy(bpEcon.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetConsumptionPerSecondMass(bpEcon.MaintenanceConsumptionPerSecondMass or 0)
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        self.Dollah = bpEcon.MassCost
        if self.EconomyProductionInitiallyActive then
            self:SetProductionActive(true)
        end

        self.Buffs = {
            BuffTable = {},
            Affects = {},
        }

        local bpVision = bp.Intel.VisionRadius
        self:SetIntelRadius('Vision', bpVision or 0)

        self:SetCanTakeDamage(true)
        self:SetCanBeKilled(true)

        local bpDeathAnim = bp.Display.AnimationDeath
        if bpDeathAnim and table.getn(bpDeathAnim) > 0 then
            self.PlayDeathAnimation = true
        end

        --Used for keeping track of resource consumption
        self.MaintenanceConsumption = false
        self.ActiveConsumption = false
        self.ProductionEnabled = true
        self.EnergyModifier = 0
        self.MassModifier = 0

        --Cheating
        if self:GetAIBrain().CheatEnabled then
            AIUtils.ApplyCheatBuffs(self)
        end

        self.Dead = false

        self:InitBuffFields()
        self:OnCreated()

        --Ensure transport slots are available
        self.attachmentBone = nil

        -- Set up Adjacency container
        self.AdjacentUnits = {}

        self.Repairers = {}
        
        --this bit also added in eq, its lets us have a dynamic cost and change it on the fly if we need to.
        self.BuildCostM = bpEcon.BuildCostMass
        self.BuildCostE = bpEcon.BuildCostEnergy
        self.BuildT = bpEcon.BuildTime
    end,




    
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        -- Keep track of instigators, but only if it is a unit
        if instigator and IsUnit(instigator) then
            self.Instigators[instigator] = (self.Instigators[instigator] or 0) + amount
            self.totalDamageTaken = self.totalDamageTaken + amount
        end
        oldUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
    end,
    
    OnKilled = function(self, instigator, type, overkillRatio)
        self.Dead = true
        self:HandleStorage()        --Ithilis add only this 
        if instigator and self.totalDamageTaken ~= 0 then
            self:VeterancyDispersal()
        end
        oldUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
    
-- This section contains functions used by the new veterancy system
-------------------------------------------------------------------
    
    -- Tell any living instigators that they need to gain some veterancy
    VeterancyDispersal = function(unitKilled)
    
    -- We use a value stored in a table for support for changing mass cost on the fly, which is needed for upgrades
        local bp = unitKilled:GetBlueprint()
        local mass = 0
        
        if unitKilled.BuildCostM then
            mass = unitKilled.BuildCostM
        else -- Super redundancy and bulletproofing - if the value is missing due to mod nonsense overwriting OnCreate we don't break
            WARN('Equilibrium: did not find unit price in unit table! finding values from blueprint!')
            mass = bp.Economy.BuildCostMass
        end
        
        -- Allow units to count for more or less than their real mass if needed.
        mass = mass * (bp.Veteran.ImportanceMult or 1)
        
        for k, damageDealt in unitKilled.Instigators do
            -- k should be a unit's entity ID
            if k and not k.Dead and k.Sync.VeteranLevel ~= 5 then
                -- Make sure that if the unit dies and  did not recieve full damage, its total hp is used. this stops unfinished buildings from giving full vet; same with ctrlk.
                local TotalDamage = math.max(unitKilled.totalDamageTaken , unitKilled:GetMaxHealth())
                
                -- Find the proportion of yourself that each instigator killed
                local massKilled = math.floor(mass * (damageDealt / TotalDamage))
                k:OnKilledUnit(unitKilled, massKilled)
            end
        end
    end,
    
    OnKilledUnit = function(self, unitKilled, massKilled)
        if not massKilled then return end -- Make sure engine calls aren't passed with massKilled == 0
        
        if unitKilled.Sync.VeteranLevel then
            massKilled = massKilled * (1 + (0.2 * math.max((unitKilled.Sync.VeteranLevel - self.Sync.VeteranLevel), 0))) -- This lines mean that units with 1 veterancy level will add 20% more xp for every level = 5* unit get +100% = 2x more xp
        end
        
        if not IsAlly(self:GetArmy(), unitKilled:GetArmy()) then
            self:CalculateVeterancyLevel(massKilled) -- Bails if we've not gone up
        end
    end,
    
    CalculateVeterancyLevel = function(self, massKilled, defaultMult)
        local bp = self:GetBlueprint()

        -- Total up the mass the unit has killed overall, and store it
        if not self.Sync.totalMassKilled then --Equilibrium adds this so we know whats going on if this throws an error.
        WARN('Equilibrium: no totalMassKilled on unit trying to get veterancy! is it missing from the unit table?')
        end
        
        self.Sync.totalMassKilled = math.floor(self.Sync.totalMassKilled + massKilled)
        
        -- Calculate veterancy level. By default killing your own mass grants a level
        local newVetLevel = math.min(math.floor(self.Sync.totalMassKilled / self.Sync.myValue), 5)

        -- Bail if our veterancy hasn't increased
        if newVetLevel == self.Sync.VeteranLevel then
            return
        end
        
        -- Update our recorded veterancy level
        self.Sync.VeteranLevel = newVetLevel

        self:BuffVeterancy()
    end,
    
    BuffVeterancy = function(self)

        -- Create buffs
        local regenBuff = self:NewCreateVeterancyBuff(self.techLevel, 'VETERANCYREGEN', 'REPLACE', -1, 'Regen', 'Add')
        local healthBuff = self:NewCreateVeterancyBuff(self.techLevel, 'VETERANCYMAXHEALTH', 'REPLACE', -1, 'MaxHealth', 'Mult')
        
        -- Apply buffs
        Buff.ApplyBuff(self, regenBuff)
        Buff.ApplyBuff(self, healthBuff)
    end,
    
    NewCreateVeterancyBuff = function(self, techLevel, buffType, stacks, buffDuration, effectType, mathType)
        -- Generate a buffName based on the unit's tech level. This way, once we generate it once,
        -- We can just apply it for any future unit which fits.
        -- Example: TECH1VETERANCYREGEN1
        local vetLevel = self.Sync.VeteranLevel
        
        local buffName = false
        local subSection = false
        if buffType == 'VETERANCYREGEN' then
            subSection = typeTable[self:GetUnitId()] or 7-- Will be 1 through 6
            buffName = techLevel .. subSection .. buffType .. vetLevel
        else
            buffName = techLevel .. buffType .. vetLevel
        end
        
        -- Bail out if it already exists
        if Buffs[buffName] then
            return buffName
        end
        
        -- Each buffType should only ever be allowed to add OR mult, not both.
        local val = 1
        if buffType == 'VETERANCYMAXHEALTH' then
            val = 1 + ((multsTable[buffType][techLevel] - 1) * vetLevel)
        else
            if subSection == 1 or subSection == 3 then -- Combat or Ship
                val = multsTable[buffType][techLevel][subSection][vetLevel]
            elseif subSection == 2 or subSection == 4 then -- Raider or Sub
                val = multsTable[buffType][techLevel][subSection] * vetLevel
            elseif subSection == 5 then -- Experimental or sACU
                val = multsTable[buffType][techLevel][vetLevel]
            elseif subSection == 6 then -- ACU
                val = multsTable[buffType][techLevel] * vetLevel
            else -- non combat unit or modded unit
                WARN('we are applying a buff for a non-combat or modded unit! ')
                val = multsTable[buffType][techLevel][1][vetLevel] --we make it use default combat units if its not specified otherwise.
            end
        end
        
        if type(val) ~= 'number' then --catch any nonsense with buffs, so we at least make it not crash the script.
            WARN('Equilibrium: trying to assign a veterancy regen value which isnt a number! Likely due to strange unit categories! Assuming defaults!')
            if buffType == 'VETERANCYREGEN'  then
                val = 2 * vetLevel
            else
                val = 1.2 --just you know, whatever right?
            end
        end

        -- This creates a buff into the global bufftable
        -- First, we need to create the Affects section
        local affects = {}
        affects[effectType] = {
            DoNoFill = effectType == 'MaxHealth',
            Add = 0,
            Mult = 0,
        }
        affects[effectType][mathType] = val
        
        -- Then fill in the main, global table
        BuffBlueprint {
            Name = buffName,
            DisplayName = buffName,
            BuffType = buffType,
            Stacks = stacks,
            Duration = buffDuration,
            Affects = affects,
        }
        
        -- Return the buffname so the buff can be applied to the unit
        return buffName
    end,
    
    FindTechLevel = function(self)
        for k, cat in pairs({'EXPERIMENTAL', 'SUBCOMMANDER', 'COMMAND', 'TECH1', 'TECH2', 'TECH3'}) do
            if EntityCategoryContains(ParseEntityCategory(cat), self) then return cat end
        end
    end,
    
    OnStopBeingBuilt = function(self, builder, layer)        
        -- Set up Veterancy tracking here. Avoids needing to check completion later.
        -- Do all this here so we only have to do for things which get completed        
        -- To maintain mod compatibility, we have to track veterancy for all units by default.
        local bp = self:GetBlueprint()
        self.Sync.totalMassKilled = 0
        self.Sync.VeteranLevel = 0
        
        -- Allow units to require more or less mass to level up. Decimal multipliers mean
        -- faster leveling, >1 mean slower. Doing this here means doing it once instead of every kill.
        local defaultMult = 1.5
        self.Sync.myValue = math.floor(bp.Economy.BuildCostMass * (bp.Veteran.RequirementMult or defaultMult))
            
        oldUnit.OnStopBeingBuilt(self, builder, layer)
    end,

-------------------------------------------------------------------------------------------
-- DAMAGE
-------------------------------------------------------------------------------------------
    DoDeathWeapon = function(self)
        if self:IsBeingBuilt() then return end
        local bp = self:GetBlueprint()
        for k, v in bp.Weapon do
            if(v.Label == 'DeathWeapon') then
            if self.NewDeathDamage then
                --added a modifier to our deathweapon damage, if it was put into the unit script somewhere
                -- it needs to be dropped into the unit table since our weapon tables seem to be cleared on death,
                -- and this code fired based on the blueprint values, so we intercept them here
                --WARN('exploding with damage: ' .. self.NewDeathDamage)
                v.Damage = self.NewDeathDamage
            end
            
            
                if v.FireOnDeath == true then
                    self:SetWeaponEnabledByLabel('DeathWeapon', true)
                    self:GetWeaponByLabel('DeathWeapon'):Fire()
                else
                    self:ForkThread(self.DeathWeaponDamageThread, v.DamageRadius, v.Damage, v.DamageType, v.DamageFriendly)
                end
                break
            end
        end
    end,

-----
-- Water Guard: Underwater units take less damage from above water splash damage 
-- By Balthazar
-----
    
    OnDamage = function(self, instigator, amount, vector, damageType, ...)
        if damageType == 'NormalAboveWater' and (self:GetCurrentLayer() == 'Sub' or self:GetCurrentLayer() == 'Seabed') then
            local bp = self:GetBlueprint()
            local myheight = bp.Physics.MeshExtentsY or bp.SizeY or 0
            local depth = math.abs(vector[2]) - myheight
            --WARN(depth) -- use this to tune the cutoff depth for damage
            if depth > 1 then return --units deep underwater take 0 damage
            else
                oldUnit.OnDamage(self, instigator, amount, vector, damageType, unpack(arg))
                --the unpack here is to maintain compatibility incase some new arg is added
            end
        else
            -- units with their head poking above or only thin layer of water take full damage
            oldUnit.OnDamage(self, instigator, amount, vector, damageType, unpack(arg))
        end
    end, 

---------------    
----RECLAIM------
---------------

    CreateWreckageProp = function( self, overkillRatio )
        local bp = self:GetBlueprint()
        local wreck = bp.Wreckage.Blueprint

        if not wreck then
            return nil
        end

        local mass = bp.Economy.BuildCostMass * (bp.Wreckage.MassMult or 0)
        local energy = bp.Economy.BuildCostEnergy * (bp.Wreckage.EnergyMult or 0)
        local time = (bp.Wreckage.ReclaimTimeMultiplier or 1) * 2  --change by Ithilis it for doubled reclaim time 
        local pos = self:GetPosition()
        local layer = self:GetCurrentLayer()

        if layer == 'Water' then
            --Reduce the mass value of submerged wrecks
            mass = mass * 0.5
            energy = energy * 0.5
        end

        -- make sure air / naval wrecks stick to ground / seabottom
        if layer == 'Air' or EntityCategoryContains(categories.NAVAL - categories.STRUCTURE, self) then
            pos[2] = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
        end

        local overkillMultiplier = 1 - (overkillRatio or 1)
        mass = mass * overkillMultiplier * self:GetFractionComplete()
        energy = energy * overkillMultiplier * self:GetFractionComplete()
        time = time * overkillMultiplier

        local prop = Wreckage.CreateWreckage(bp, pos, self:GetOrientation(), mass, energy, time)

        -- Attempt to copy our animation pose to the prop. Only works if
        -- the mesh and skeletons are the same, but will not produce an error if not.
        if layer ~= 'Air' and self.PlayDeathAnimation then
            TryCopyPose(self, prop, true)
        end

        --Create some ambient wreckage smoke
        explosion.CreateWreckageEffects(self,prop)

        return prop
    end,    
    
-----
--Mass storages lose portion of mass when die  
-- code is from there  https://github.com/FAForever/fa/pull/581/files
-----

    HandleStorage = function(self, to_army)
        if EntityCategoryContains(categories.MOBILE, self) then
            return -- Exclude ACU / SCU / sparky
        end

        local bp = self:GetBlueprint()
        local brain = GetArmyBrain(self:GetArmy())
        for _, t in {'Mass', 'Energy'} do
            if bp.Economy['Storage' .. t] then
                local type = string.upper(t)
                local amount = bp.Economy['Storage' .. t] * brain:GetEconomyStoredRatio(type)

                brain:TakeResource(type, amount)
                if to_army then
                    local to = GetArmyBrain(to_army)
                    to:GiveResource(type, amount)
                end
            end
        end
    end,

----------------------------------------------------------------------------------------------
-- CONSTRUCTING - BUILDING - REPAIR
----------------------------------------------------------------------------------------------

    --global sacrifice system adjustment, the order itself is engine-side so we just pick up the pieces
    OnStartSacrifice = function(self, target_unit)
        EffectUtilities.PlaySacrificingEffects(self,target_unit)
        local bp = self:GetBlueprint().Economy
        local donatemass = bp.BuildCostMass*bp.SacrificeMassMult
        local donateenergy = bp.BuildCostEnergy*bp.SacrificeEnergyMult
        
        --uncomment the warnings to help understand the maths behind the sacrifice system and how we compute the wreck value
        
        --WARN(donatemass .. ' mass should be donated')
        --WARN(donateenergy .. ' energy should be donated')
        
        local tgbp = target_unit:GetBlueprint().Economy
        
        local OwnMER = donatemass/donateenergy
        local TargetMER = tgbp.BuildCostMass/tgbp.BuildCostEnergy
        
        --WARN(OwnMER .. ' own mass/energy ratio')
        --WARN(TargetMER .. ' target mass/energy ratio')
        
        local MDM = TargetMER/OwnMER
        self.ActMassDonation = math.min(donatemass*MDM, donatemass)
        
        --WARN(MDM .. ' mass donation multiplier; ' .. self.ActMassDonation .. ' mass actually donated')
        --WARN(donatemass - donatemass*MDM .. 'mass should be refunded')
        
        --this is how much we should be sacrificing
        self.RefundAmount = math.max((donatemass - donatemass*MDM), 0) --in case the MDM is above 1, we should not make mass out of thin air.
        
        
        
        --incase our project has less mass needed to finish it that we are about to donate to it.
        local buildProjRemain = (1 - target_unit:GetFractionComplete())*tgbp.BuildCostMass
        
        --WARN('unit fraction completion: ' .. target_unit:GetFractionComplete())
        --WARN('mass needed to complete the project: ' .. buildProjRemain)
        
        
        --because we cant just use GetFractionComplete in OnStopSacrifice we have to track sacrifices on the target unit
        if not target_unit.MassToBeSacrificed then
            target_unit.MassToBeSacrificed = 0
        end
        
        --WARN('mass about to be donated: ' .. target_unit.MassToBeSacrificed)
        
        --we refund the mass if our unit is about to be finished. we dont refund it if its used to repair a complete unit.
        if self.ActMassDonation > (buildProjRemain - target_unit.MassToBeSacrificed) and target_unit:GetFractionComplete() ~= 1 then
            self.RefundAmount = donatemass - math.max((buildProjRemain - target_unit.MassToBeSacrificed), 0)
            --WARN('refund amount: ' .. self.RefundAmount)
            --WARN('mass donation with refund into account: ' .. math.max((buildProjRemain - target_unit.MassToBeSacrificed), 0))
        end
        
        --similar case as above, we refund if were trying to repair something thats already nearly full hp
        if target_unit:GetFractionComplete() == 1 then
            local repairProjRemain = (1 - (target_unit:GetHealth()/target_unit:GetMaxHealth()))*tgbp.BuildCostMass
            
            self.RefundAmount = donatemass - math.max((repairProjRemain - target_unit.MassToBeSacrificed), 0)
            --WARN('refund amount: ' .. self.RefundAmount)
            --WARN('mass donation with refund into account: ' .. math.max((buildProjRemain - target_unit.MassToBeSacrificed), 0))
        end
        
        
        target_unit.MassToBeSacrificed = target_unit.MassToBeSacrificed + self.ActMassDonation
    end,
    
    OnStopSacrifice = function(self, target_unit) --we will refund the unused mass by placing it in a wreck
        if self.RefundAmount >= 1 then
            --the /0.9 is there since our wreck is at 90% hp of the unit and so it only contains 90% of the mass it should.
            self:CreateSacrificeWreckageProp(self.RefundAmount/0.9)
        end
        --after we sacrifce ourselved we remove our mass from the list.
        target_unit.MassToBeSacrificed = math.max((target_unit.MassToBeSacrificed - self.ActMassDonation), 0)
        EffectUtilities.PlaySacrificeEffects(self,target_unit)
        self:SetDeathWeaponEnabled(false)
        self:Destroy() -- commenting this doesn't even stop it from disappearing, must be engine things
    end,
    
    CreateSacrificeWreckageProp = function( self, refundamount )
        local bp = self:GetBlueprint()

        local wreck = bp.Wreckage.Blueprint

        if not wreck then
            return nil
        end

        local mass = refundamount
        local energy = 0
        local time = (bp.Wreckage.ReclaimTimeMultiplier or 1)
        local pos = self:GetPosition()
        local layer = self:GetCurrentLayer()
        
        local prop = Wreckage.CreateWreckage(bp, pos, self:GetOrientation(), mass, energy, time)
        
        -- if (layer == 'Water') or (layer == "Sub") then
            -- WARN('trying to sink')
        -- end
        --FIXME: make the wreck sink, or do something about it appearing on the sea surface and then not doinganything

        -- Attempt to copy our animation pose to the prop. Only works if
        -- the mesh and skeletons are the same, but will not produce an error if not.
        if (layer ~= 'Air' and self.PlayDeathAnimation) then
            TryCopyPose(self, prop, true)
        end
        
        return prop
    end,
    
-------------------------------------------------------------------------------------------
--LAYER EVENTS
-------------------------------------------------------------------------------------------
    OnLayerChange = function(self, new, old)
        oldUnit.OnLayerChange(self, new, old)
		--for units falling out of a dead transport - they are destined to die, so we kill them and leave the wreck.
		if self.falling and (new == 'Land' or new == 'Water' or new == 'Sub' or new == 'Seabed') and old == 'Air' then
			self.falling = nil
            self:Kill()
		end
    end,

}
