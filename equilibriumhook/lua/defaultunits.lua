local AIUtils = import('/lua/ai/aiutilities.lua')
--------------------------------------------------------------
--  AIR UNITS
---------------------------------------------------------------
--TODO- when the bounce code makes it into faf we need to hook this and not shadow it.

--veterancy system added
--auto refuel toggle button added
AirUnit = Class(MobileUnit) {

    -- Contrails
    ContrailEffects = {'/effects/emitters/contrail_polytrail_01_emit.bp',},
    BeamExhaustCruise = '/effects/emitters/air_move_trail_beam_03_emit.bp',
    BeamExhaustIdle = '/effects/emitters/air_idle_trail_beam_01_emit.bp',

    -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DestructionExplosionWaitDelayMax = 0,
    DestroyNoFallRandomChance = 0.5,

    OnCreate = function(self)
        MobileUnit.OnCreate(self)
        self.HasFuel = true
        self:SetAutoRefuel(true) --on by default
        --TODO: make this only work for units that have the dock order available.
        self:AddPingPong()
    end,

    AddPingPong = function(self)
        local bp = self:GetBlueprint()
        if bp.Display.PingPongScroller then
            bp = bp.Display.PingPongScroller
            if bp.Ping1 and bp.Ping1Speed and bp.Pong1 and bp.Pong1Speed and bp.Ping2 and bp.Ping2Speed
                and bp.Pong2 and bp.Pong2Speed then
                self:AddPingPongScroller(bp.Ping1, bp.Ping1Speed, bp.Pong1, bp.Pong1Speed,
                                         bp.Ping2, bp.Ping2Speed, bp.Pong2, bp.Pong2Speed)
            end
        end
    end,

    OnMotionVertEventChange = function( self, new, old )
        MobileUnit.OnMotionVertEventChange( self, new, old )
        --LOG( 'OnMotionVertEventChange, new = ', new, ', old = ', old )
        local army = self:GetArmy()
        if (new == 'Down') then
            -- Turn off the ambient hover sound
            self:StopUnitAmbientSound( 'ActiveLoop' )
        elseif (new == 'Bottom') then
            -- While landed, planes can only see half as far
            local vis = self:GetBlueprint().Intel.VisionRadius / 2
            self:SetIntelRadius('Vision', vis)

            -- Turn off the ambient hover sound
            -- It will probably already be off, but there are some odd cases that
            -- make this a good idea to include here as well.
            self:StopUnitAmbientSound( 'ActiveLoop' )
        elseif (new == 'Up' or ( new == 'Top' and ( old == 'Down' or old == 'Bottom' ))) then
            -- Set the vision radius back to default
            local bpVision = self:GetBlueprint().Intel.VisionRadius
            if bpVision then
                self:SetIntelRadius('Vision', bpVision)
            else
                self:SetIntelRadius('Vision', 0)
            end
        end
    end,

    OnStartRefueling = function(self)
        self:PlayUnitSound('Refueling')
    end,

    OnRunOutOfFuel = function(self)
        self.HasFuel = false
        self:DestroyTopSpeedEffects()

        -- penalize movement for running out of fuel
        self:SetSpeedMult(0.35)     -- change the speed of the unit by this mult
        self:SetAccMult(0.25)       -- change the acceleration of the unit by this mult
        self:SetTurnMult(0.25)      -- change the turn ability of the unit by this mult
    end,

    OnGotFuel = function(self)
        self.HasFuel = true
        -- revert these values to the blueprint values
        self:SetSpeedMult(1)
        self:SetAccMult(1)
        self:SetTurnMult(1)
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

local slotsData = {}
BaseTransport = Class() {
    OnTransportAttach = function(self, attachBone, unit)
        self:PlayUnitSound('Load')
        self:RequestRefreshUI()

        for i=1, self:GetBoneCount() do
            if self:GetBoneName(i) == attachBone then
                self.slots[i] = unit
                unit.attachmentBone = i
            end
        end
        
        unit:OnAttachedToTransport(self, attachBone)
    end,

    OnTransportDetach = function(self, attachBone, unit)
        self:PlayUnitSound('Unload')
        self:RequestRefreshUI()
        self.slots[unit.attachmentBone] = nil
        unit.attachmentBone = nil
        unit:OnDetachedFromTransport(self, attachBone)
    end,

    -- When one of our attached units gets killed, detach it
    OnAttachedKilled = function(self, attached)
        attached:DetachFrom()
    end,

    OnStartTransportLoading = function(self)
        -- We keep the aibrain up to date with the last transport to start loading so, among other
        -- things, we can determine which transport is being referenced during an OnTransportFull
        -- event (As this function is called immediately before that one).
        self.transData = {}
        self:GetAIBrain().loadingTransport = self
    end,

    OnStopTransportLoading = function(...)
    end,

    DestroyedOnTransport = function(self)
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
        AirUnit.OnKilled(self, instigator, type, overkillRatio)
        self:DetachCargo()
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

