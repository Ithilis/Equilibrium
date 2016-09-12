local multsTable = import('/lua/sim/BuffDefinitions.lua').MultsTable
local typeTable = import('/lua/sim/BuffDefinitions.lua').TypeTable

local oldUnit = Unit
Unit = Class(oldUnit) {


---------------
----VETERANCY------
---------------

    OnCreate = function(self)
        self.Instigators = {}
        self.totalDamageTaken = 0
        self.techLevel = self:FindTechLevel()
        oldUnit.OnCreate(self)
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
        local bp = unitKilled:GetBlueprint()
        local mass = bp.Economy.BuildCostMass
        
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
            subSection = typeTable[self:GetUnitId()] -- Will be 1 through 6
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
            else -- ACU
                val = multsTable[buffType][techLevel] * vetLevel
            end
        end

        -- This creates a buff into the global bufftable
        -- First, we need to create the Affects section
        local affects = {}
        affects[effectType] = {
            DoNotFill = effectType == 'MaxHealth',
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
        for k, cat in pairs({'TECH1', 'TECH2', 'TECH3', 'EXPERIMENTAL', 'COMMAND', 'SUBCOMMANDER'}) do
            if EntityCategoryContains(ParseEntityCategory(cat), self) then return cat end
        end
    end,
    
    OnStopBeingBuilt = function(self, builder, layer)        
        -- Set up Veterancy tracking here. Avoids needing to check completion later.
        -- Do all this here so we only have to do for things which get completed        
        -- Don't need to track damage for things which cannot attack!
        if typeTable[self:GetUnitId()] then
            local bp = self:GetBlueprint()
            self.Sync.totalMassKilled = 0
            self.Sync.VeteranLevel = 0
            
            -- Allow units to require more or less mass to level up. Decimal multipliers mean
            -- faster leveling, >1 mean slower. Doing this here means doing it once instead of every kill.
            local defaultMult = 1.5
            self.Sync.myValue = math.floor(bp.Economy.BuildCostMass * (bp.Veteran.RequirementMult or defaultMult))
        end
        oldUnit.OnStopBeingBuilt(self, builder, layer)
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

-----
-- Water Guard: Underwater units take less damage from above water splash damage 
-- By Balthazar
-----
    
    OnDamage = function(self, instigator, amount, vector, damageType, ...)
        if damageType == 'NormalAboveWater' and (self:GetCurrentLayer() == 'Sub' or self:GetCurrentLayer() == 'Seabed') then
            local bp = self:GetBlueprint()
            local myheight = bp.Physics.MeshExtentsY or bp.SizeY or 0
            local damagetotal = amount / math.max(math.abs(vector[2]) - myheight, 1)
            oldUnit.OnDamage(self, instigator, damagetotal, vector, damageType, unpack(arg))
        else
            oldUnit.OnDamage(self, instigator, amount, vector, damageType, unpack(arg))
        end
    end, 

}
