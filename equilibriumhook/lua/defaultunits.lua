local AIUtils = import('/lua/ai/aiutilities.lua')
local GetRandomFloat = import('utilities.lua').GetRandomFloat

--------------------------------------------------------------
--  AIR UNITS
---------------------------------------------------------------
--TODO- when the bounce code makes it into faf we need to hook this and not shadow it.

--veterancy system added
--auto refuel toggle button added
oldAirUnit = AirUnit

AirUnit = Class(oldAirUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        local bp = self:GetBlueprint()
        if not bp.Air.DisableAutoRefuel then
            self:SetAutoRefuel(true) --on by default
        end
        --TODO: make this only work for units that have the dock order available.
        oldAirUnit.OnStopBeingBuilt(self,builder,layer)
    end,
    
    OnImpact = function(self, with, other)
        if self.DeathBounce then
            return
        end
        self.DeathBounce = true

        -- Damage the area we have impacted with.
        local bp = self:GetBlueprint()
        local i = 1
        local numWeapons = table.getn(bp.Weapon)

        for i, numWeapons in bp.Weapon do
            if(bp.Weapon[i].Label == 'DeathImpact') then
                local Damage = (bp.Weapon[i].Damage - self.ShieldDamageAbsorbed)
                --WARN(Damage .. ' crash damage dealt to ground') -- since our shield collision subtracts damage, this may be nice to know how much is left
                if Damage > 0 then
                    DamageArea(self, self:GetPosition(), bp.Weapon[i].DamageRadius, (bp.Weapon[i].Damage - self.ShieldDamageAbsorbed), bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                end
                
                break
            end
        end

        if(with == 'Water') then
            self:PlayUnitSound('AirUnitWaterImpact')
            EffectUtil.CreateEffects( self, self:GetArmy(), EffectTemplate.DefaultProjectileWaterImpact )
        end
        self:ForkThread(self.DeathThread, self.OverKillRatio )
    end,

    CreateUnitAirDestructionEffects = function( self, scale )
        local army = self:GetArmy()
        local scale = explosion.GetAverageBoundingXZRadius(self)
        explosion.CreateDefaultHitExplosion( self, scale)
        if(self.ShowUnitDestructionDebris) then
            explosion.CreateDebrisProjectiles(self, scale, {self:GetUnitSizes()})
        end
    end,

    --- Called when the unit is killed, but before it falls out of the sky and blows up.
    OnKilled = function(self, instigator, type, overkillRatio)
        local bp = self:GetBlueprint()

        -- A completed, flying plane expects an OnImpact event due to air crash.
        -- An incomplete unit in the factory still reports as being in layer "Air", so needs this
        -- stupid check.
        if self:GetCurrentLayer() == 'Air' and self:GetFractionComplete() == 1  then
            self.Dead = true
            self.CreateUnitAirDestructionEffects(self, 1.0)
            self:DestroyTopSpeedEffects()
            self:DestroyBeamExhaust()
            self.OverKillRatio = overkillRatio
            self:PlayUnitSound('Killed')
            self:DoUnitCallbacks('OnKilled')
            self:DisableShield()
            
            self.ShieldDamageAbsorbed = 0 --we use this to work out how much damage to subtract from the deathimpact.
            
            local this = self --waiting for our projectile to collide with a shield or the ground, and then modifying deathweapon
            self:EnableShieldCollision(
                function()
                    local bp = self:GetBlueprint()
                    local i = 1
                    local numWeapons = table.getn(bp.Weapon)
                    
                    for i, numWeapons in bp.Weapon do
                        if(bp.Weapon[i].Label == 'DeathImpact') then
                            --self.ShieldCollideMaxHealth is passed from the shield when our companion projectile hits it
                            self.ShieldCollideMaxHealth = self.ShieldCollideMaxHealth or 0
                            --this 0.2 there is just a multiplier i liked; can be lower or higher; whatever
                            self.ShieldDamage = math.min(self.ShieldCollideMaxHealth*0.2, (bp.Weapon[i].Damage - self.ShieldDamageAbsorbed))
                            --should never be below 0
                            DamageArea(self, self:GetPosition(), bp.Weapon[i].DamageRadius, self.ShieldDamage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                            self.ShieldDamageAbsorbed = self.ShieldDamageAbsorbed + self.ShieldDamage
                            --WARN(self.ShieldDamageAbsorbed .. ' damage absorbed by shield') --very useful for testing shield absorb multipliers
                            break
                        end
                    end
                    
                    self.CreateDestructionEffects( self, self.OverKillRatio) -- explosion on the shield, honestly this is cos the air version is shit.
                end
            )
            
            if instigator and IsUnit(instigator) then
                instigator:OnKilledUnit(self)
            end
            
            if instigator and self.totalDamageTaken ~= 0 then
                self:VeterancyDispersal()
            end
        else
            self.DeathBounce = 1
            MobileUnit.OnKilled(self, instigator, type, overkillRatio)
        end
    end,

    EnableShieldCollision = function(self, callback)
        local bone = 0

        --Create companion projectile
        local proj = self:CreateProjectileAtBone('/projectiles/ShieldCollider/ShieldCollider_proj.bp', bone)
        
        -- start following our plane, attaching to a given bone and entity on shield collision
        proj:Start(self, bone, callback)
        self.Trash:Add(proj)
    end,
    
    SetAutoRefuel = function(self, auto)
        --WARN('callbackreached unit, setting autorefuel to:'..repr(auto))
        self.Sync.AutoRefuel = auto
        self.AutoRefuel = auto
        
        --self.AlreadyOrdered = false --reset the ordered flag if we toggle all the buttons
        
        if self.AutoRefuel then
            if not self.AutoFuelThread then
                self.AutoFuelThread = self:ForkThread(self.AutoRefuelThread)
            end
        else
            if self.AutoFuelThread then
                KillThread(self.AutoFuelThread)
                self.AutoFuelThread = nil
            end
        end
    end,

    AutoRefuelThread = function(self)
        --when turned on this spreads the wait time around so planes dont look for empty staging platforms in the same tick
        --this causes them to bunch up instead of landing nicely, and spam transport commands.
        --this is only an issue when they are spawned in large numbers, or you toggle the button on a lot of planes at a time
        local waitTime = GetRandomFloat(0, 5)
        WaitSeconds(waitTime)
        while self.AutoRefuel == true do
            --WARN('checking for refuel need')
            if (self.AutoRefuel and (self:GetFuelRatio() < 0.2 or self:GetHealthPercent() < .6)) and not self.AlreadyAttached then
                --WARN('criteria for fueling met, nice')
                
                --ideally we would check the command queue to avoid refitting units that already have the command queued
                --but that needs to go ui side to even run the command which seems pretty absurd
                --and doing this with a flag would just mean that we need to reset it on command given?
                --if not self.AlreadyOrdered then
                    --WARN('ordering refit')
                    self:AirUnitRefit()
                --end
            end
            
            WaitSeconds(15)
        end
    end,

    AirUnitRefit = function(self)
        local aiBrain = self:GetAIBrain()
        # Find air stage
        if aiBrain:GetCurrentUnits( categories.AIRSTAGINGPLATFORM ) > 0 then
            local unitPos = self:GetPosition()
            local plats = AIUtils.GetOwnUnitsAroundPoint( aiBrain, categories.AIRSTAGINGPLATFORM, unitPos, 400 )
            if table.getn( plats ) > 0 then
                table.sort(plats, function(a,b)--sort all our staging platforms by distance
                    local platPosA = a:GetPosition()
                    local platPosB = b:GetPosition()
                    local distA = VDist2(unitPos[1], unitPos[3], platPosA[1], platPosA[3])
                    local distB = VDist2(unitPos[1], unitPos[3], platPosB[1], platPosB[3])
                    return distA < distB
                end)
                
                local closest = self:FindPlatforms(plats)
                
                if closest then
                    IssueStop( {self} )
                    IssueClearCommands( {self} )
                    IssueTransportLoad( {self}, closest )
                else
                    --if there are no available platforms (all full) then we move near one so when its empty we can fuel
                    platPos = plats[1]:GetPosition()
                    local dist = VDist2(unitPos[1], unitPos[3], platPos[1], platPos[3])
                    if dist > 20 then --dont spam the order if we are close already
                        IssueMove( {self}, platPos)
                    end
                end
            end
        end
    end,

    FindPlatforms = function(self, plats)
    --find the first platform in our list thats not empty. 
    --the list is pre-sorted so it will find the closest one as well.
        for k,v in plats do
            if not v.Dead then
                local roomAvailable = false
                if EntityCategoryContains( categories.CARRIER, v ) then
                    --roomAvailable = v:TransportHasAvailableStorage( self )
                else
                    roomAvailable = v:TransportHasSpaceFor( self )
                end
                if roomAvailable then
                        return v
                end
            end
        end
        return false
    end,
}

-------------------------------------------------------------
--  AIR STAGING PLATFORMS UNITS
-------------------------------------------------------------
oldAirStagingPlatformUnit = AirStagingPlatformUnit

AirStagingPlatformUnit = Class(oldAirStagingPlatformUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        oldAirStagingPlatformUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,
    
    OnTransportAttach = function(self, attachBone, unit)
    unit.AlreadyAttached = true --flag our unit to not try to attach if its docked - it can cause an error
    end,

    OnTransportDetach = function(self, attachBone, unit)
    unit.AlreadyAttached = false
    end,
}

--- Mixin transports (air, sea, space, whatever). Sellotape onto concrete transport base classes as
-- desired.

oldBaseTransport = BaseTransport

BaseTransport = Class(oldBaseTransport) {
    -- When one of our attached units gets killed, detach it
    OnAttachedKilled = function(self, attached)
        attached:DetachFrom()
    end,

    DetachCargo = function(self)
        if self.Dead then return end --due to overkill damage this can get called when trans is hit after it dies and cause errors since it doesnt have any cargo
        local units = self:GetCargo()
        for k, v in units do
            if EntityCategoryContains(categories.TRANSPORTATION, v) then
                for k, u in self:GetCargo() do
                    u:Kill()
                end
            end
            v:DetachFrom()
            v.falling = true --set flag to kill units on impact.
        end
    end
}
--note - this doesnt work on insta crtl k because of .. nonsense. maybe its fixed later.
--- Base class for air transports.
AirTransport = Class(AirUnit, BaseTransport) {

    DestroyNoFallRandomChance = 1, --tbh i have no idea what this does
    
    OnTransportAborted = function(self)
    end,

    OnTransportOrdered = function(self)
    end,

    OnCreate = function(self)
        AirUnit.OnCreate(self)
        self.slots = {}
        self.transData = {}
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self:DetachCargo()
        AirUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnStorageChange = function(self, loading)
        AirUnit.OnStorageChange(self, loading)
        for k, v in self:GetCargo() do
            v:OnStorageChange(loading)
        end
    end,
    
    Kill = function(self, ...) --pure black magic thats called when the unit is killed. not on insta ctrl-k mind you
        self:DetachCargo()
        AirUnit.Kill(self, unpack(arg))
    end,
}

-----------------------------------------------------------------
--  STRUCTURE UNITS
-----------------------------------------------------------------
oldStructureUnit = StructureUnit

StructureUnit = Class(oldStructureUnit) {

    OnKilled = function(self, instigator, type, overKillRatio)
        local engies = EntityCategoryFilterDown(categories.ENGINEER * categories.TECH3, self:GetGuards())
        if engies[1] then
            for _, u in engies do
                u:SetFocusEntity(self)
                self.Repairers[u:GetEntityId()] = u
            end
        end

        oldStructureUnit.OnKilled(self, instigator, type, overKillRatio)
    end,

    CheckRepairersForRebuild = function(self, wreckage)
        local units = {}
        for id, u in self.Repairers do
            if u:BeenDestroyed() then
                self.Repairers[id] = nil
            else
                local focus = u:GetFocusUnit()
                if focus == self and ((u:IsUnitState('Repairing') and not u:GetGuardedUnit()) or
                                      EntityCategoryContains(categories.ENGINEER * categories.TECH3, u)) then
                    table.insert(units, u)
                end
            end
        end

        if not units[1] then return end

        wreckage:Rebuild(units)
    end,

    CreateWreckage = function(self, overkillRatio)
        local wreckage = Unit.CreateWreckage(self, overkillRatio)
        if wreckage then
            self:CheckRepairersForRebuild(wreckage)
        end

        return wreckage
    end,
}

oldMassStorageUnit = MassStorageUnit

MassStorageUnit = Class(oldMassStorageUnit) {

    OnKilled = function(self, instigator, type, overKillRatio)
        local engies = EntityCategoryFilterDown(categories.ENGINEER * categories.TECH3, self:GetGuards())
        if engies[1] then
            for _, u in engies do
                u:SetFocusEntity(self)
                self.Repairers[u:GetEntityId()] = u
            end
        end

        oldMassStorageUnit.OnKilled(self, instigator, type, overKillRatio)
    end,

    CheckRepairersForRebuild = function(self, wreckage)
        local units = {}
        for id, u in self.Repairers do
            if u:BeenDestroyed() then
                self.Repairers[id] = nil
            else
                local focus = u:GetFocusUnit()
                if focus == self and ((u:IsUnitState('Repairing') and not u:GetGuardedUnit()) or
                                      EntityCategoryContains(categories.ENGINEER * categories.TECH3, u)) then
                    table.insert(units, u)
                end
            end
        end

        if not units[1] then return end

        wreckage:Rebuild(units)
    end,

    CreateWreckage = function(self, overkillRatio)
        local wreckage = Unit.CreateWreckage(self, overkillRatio)
        if wreckage then
            self:CheckRepairersForRebuild(wreckage)
        end

        return wreckage
    end,
    
}