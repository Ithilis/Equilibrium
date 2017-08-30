local multsTable = import('/lua/sim/BuffDefinitions.lua').MultsTable
local hideTable = import('/lua/sim/BuffDefinitions.lua').HideTable

local oldUnit = Unit
Unit = Class(oldUnit) {

---------------
----VETERANCY------
---------------
    OnCreate = function(self) --this isnt great in terms of compatibility but we call on create to improve its performance.
    
        self.Instigators = {}
        self.totalDamageTaken = 0
        self.EffectiveTechLevel = self:FindTechLevel() --this bit added in eq
        
        oldUnit.OnCreate(self)

        --Get unit blueprint for setting variables
        local bp = GetBlueprint(self)
        -- Define Economic modifications
        local bpEcon = bp.Economy

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
        
        if not IsAlly(self:GetArmy(), unitKilled:GetArmy()) then
            self:CalculateVeterancyLevel(massKilled) -- Bails if we've not gone up
        end
    end,
    
    CalculateVeterancyLevel = function(self, massKilled, defaultMult)
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
        local regenBuff = self:NewCreateVeterancyBuff(self.EffectiveTechLevel, 'VETERANCYREGEN', 'REPLACE', -1, 'Regen', 'Add')
        local healthBuff = self:NewCreateVeterancyBuff(self.EffectiveTechLevel, 'VETERANCYMAXHEALTH', 'REPLACE', -1, 'MaxHealth', 'Mult')
        
        -- Apply buffs
        Buff.ApplyBuff(self, regenBuff)
        Buff.ApplyBuff(self, healthBuff)
    end,
    
    NewCreateVeterancyBuff = function(self, EffectiveTechLevel, buffType, stacks, buffDuration, effectType, mathType)
        -- Generate a buffName based on the unit's tech level. This way, once we generate it once,
        -- We can just apply it for any future unit which fits.
        -- Example: TECH1VETERANCYREGEN1
        local vetLevel = self.Sync.VeteranLevel
        
        local buffName = false
        
        buffName = EffectiveTechLevel .. buffType .. vetLevel
        
        -- Bail out if it already exists
        if Buffs[buffName] then
            return buffName
        end
        
        -- Each buffType should only ever be allowed to add OR mult, not both.
        local val = 1
        if buffType == 'VETERANCYMAXHEALTH' then
            val = 1 + ((multsTable[buffType][EffectiveTechLevel] - 1) * vetLevel)
        else
            --WARN('we are applying a buff for a non-combat or modded unit! ')
            val = multsTable[buffType][EffectiveTechLevel] * vetLevel --we make it use default combat units if its not specified otherwise.
        end
        
        if type(val) ~= 'number' then --catch any nonsense with buffs, so we at least make it not crash the script.
            WARN('Equilibrium: trying to assign a veterancy regen value which isnt a number! Likely due to strange unit categories! Assuming defaults!')
            if buffType == 'VETERANCYREGEN'  then
                val = 2 * vetLevel
            else
                val = 1.1 --just you know, whatever right?
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
        local shiftTechLevels = { --for navy units
            TECH1 = 'TECH2',
            TECH2 = 'TECH3',
            TECH3 = 'SUBCOMMANDER',
            SUBCOMMANDER = 'EXPERIMENTAL',
            EXPERIMENTAL = 'EXPERIMENTAL',
            }
        local effectiveLevel = 'TECH2' --default
        
        for k, cat in pairs({'EXPERIMENTAL', 'SUBCOMMANDER', 'COMMAND', 'TECH1', 'TECH2', 'TECH3'}) do
            if EntityCategoryContains(ParseEntityCategory(cat), self) then effectiveLevel = cat  break end
        end
        
        --naval units need more vet so they jump up a tech level
        if EntityCategoryContains(ParseEntityCategory('NAVAL'), self) then
            effectiveLevel = shiftTechLevels[effectiveLevel]
        end
        
        --WARN("calcing tech level as: "..effectiveLevel)
        return effectiveLevel
    end,
    
    DetermineBarVisibilty = function(self)
        --we need to work out based on the units weapons if we show the veterancy bar for it.
        
        --manual exceptions table for suicide units and hidden ones
        if hideTable[self:GetUnitId()] then return true end
        
        --any unit with 0 weapons gets it hidden
        --any unit with 1 weapon thats crash damage/death nuke gets it hidden
        --for some reason the function doesnt return death weapons usually so it says 0 which makes our job easier
        local wepNum = self:GetWeaponCount()
        if wepNum == 0 then return true end
        
        return false
    end,

    OnStopBeingBuilt = function(self, builder, layer)        
        -- Set up Veterancy tracking here. Avoids needing to check completion later.
        -- Do all this here so we only have to do for things which get completed        
        -- To maintain mod compatibility, we have to track veterancy for all units by default.
        local bp = self:GetBlueprint()
        self.Sync.totalMassKilled = 0
        self.Sync.VeteranLevel = 0
        
        --some units need to get their bars hidden, since it doesnt make sense for them to get vet.
        self.Sync.hideProgressBar = self:DetermineBarVisibilty()
        
        -- Allow units to require more or less mass to level up. Decimal multipliers mean
        -- faster leveling, >1 mean slower. Doing this here means doing it once instead of every kill.
        local defaultMult = 2.0
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

 -- there used to be CreateWreckageProp but faf has since copied these changes so its no longer needed.

-----
--Mass storages lose the mass contained in them when they die  
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
-- LAYER EVENTS
-------------------------------------------------------------------------------------------

--here we let all units have proper watervision radii. helps with units shooting each other form the shore.
--we dont hook since normal faf has a vision disable code on amphibious units. bleh.
    OnLayerChange = function(self, new, old)
        -- Bail out early if dead. The engine calls this function AFTER entity:Destroy() has killed
        -- the C object. Any functions down this line which expect a live C object (self:CreateAnimator())
        -- for example, will throw an error.
        if self.Dead then return end

        for i = 1, self:GetWeaponCount() do
            self:GetWeapon(i):SetValidTargetsForCurrentLayer(new)
        end

        -- All units want normal vision!
        if old == 'None' then
            self:EnableIntel('Vision')
            self:EnableIntel('WaterVision')
        end
        
        --EQ: Units on land want a smaller watervision than units on water?
        --[[
        if (old == 'Seabed' or old == 'Water' or old == 'Sub' or old == 'None') and new == 'Land' then
            self:EnableIntel('WaterVision')
        elseif (old == 'Land' or old == 'None') and (new == 'Seabed' or new == 'Water' or new == 'Sub') then
            self:EnableIntel('WaterVision')
        end
        --]]

        if new == 'Land' then
            self:PlayUnitSound('TransitionLand')
            self:PlayUnitAmbientSound('AmbientMoveLand')
        elseif new == 'Water' or new == 'Seabed' then
            self:PlayUnitSound('TransitionWater')
            self:PlayUnitAmbientSound('AmbientMoveWater')
        elseif new == 'Sub' then
            self:PlayUnitAmbientSound('AmbientMoveSub')
        end

        local bpTable = self:GetBlueprint().Display.MovementEffects
        if not self.Footfalls and bpTable[new].Footfall then
            self.Footfalls = self:CreateFootFallManipulators(bpTable[new].Footfall)
        end
        self:CreateLayerChangeEffects(new, old)

        -- Trigger the re-worded stuff that used to be inherited, no longer because of the engine bug above.
        if self.LayerChangeTrigger then
            self:LayerChangeTrigger(new, old)
        end
    end,
    
-------------------------------------------------------------------------------------------
-- BUFFS
-------------------------------------------------------------------------------------------
--there was some fucked up changes to do with stun mechanics so we need to hook these to fix them
--no hardcoding to exclude air units please
--spheres make 500 times less sense than capped cylinders in supcom. ever heard of terrain?
    AddBuff = function(self, buffTable, PosEntity)
        local bt = buffTable.BuffType
        if not bt then
            error('*ERROR: Tried to add a unit buff in unit.lua but got no buff table.  Wierd.', 1)
            return
        end

        -- When adding debuffs we have to make sure that we check for permissions
        local category = buffTable.TargetAllow and ParseEntityCategory(buffTable.TargetAllow) or categories.ALLUNITS
        if buffTable.TargetDisallow then
            category = category - ParseEntityCategory(buffTable.TargetDisallow)
        end

        if bt == 'STUN' then
            local targets
            if buffTable.Radius and buffTable.Radius > 0 then
                -- If the radius is bigger than 0 then we will use the unit as the center of the stun blast
                targets = utilities.GetTrueEnemyUnitsInCylinder(self, PosEntity or self:GetPosition(), buffTable.Radius, buffTable.Height, category)
            else
                -- The buff will be applied to the unit only
                if EntityCategoryContains(category, self) then
                    targets = {self}
                end
            end
            for _, target in targets or {} do
                -- Exclude things currently flying around if we have a flag
                if not (buffTable.ExcludeAirLayer and target:GetCurrentLayer() == 'Air') then
                    target:SetStunned(buffTable.Duration or 1)
                end
            end
        elseif bt == 'MAXHEALTH' then
            self:SetMaxHealth(self:GetMaxHealth() + (buffTable.Value or 0))
        elseif bt == 'HEALTH' then
            self:SetHealth(self, self:GetHealth() + (buffTable.Value or 0))
        elseif bt == 'SPEEDMULT' then
            self:SetSpeedMult(buffTable.Value or 0)
        elseif bt == 'MAXFUEL' then
            self:SetFuelUseTime(buffTable.Value or 0)
        elseif bt == 'FUELRATIO' then
            self:SetFuelRatio(buffTable.Value or 0)
        elseif bt == 'HEALTHREGENRATE' then
            self:SetRegenRate(buffTable.Value or 0)
        end
    end,
    
}
