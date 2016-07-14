-- ok so what is being changed here is only the OnKilled function inside airunit, to give veterancy according to the new vet system.
-- what is extra strange is that this file is being hooked. but if we delete these other classes then it gives and error and doesnt work.
-- so we have them here as well. whatever



--------------------------------------------------------------
--  AIR UNITS
--------------------------------------------------------------
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
                DamageArea(self, self:GetPosition(), bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
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
}

--- Mixin transports (air, sea, space, whatever). Sellotape onto concrete transport base classes as desired.

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
        local units = self:GetCargo()
        for k, v in units do
            if EntityCategoryContains(categories.TRANSPORTATION, v) then
                for k, u in self:GetCargo() do
                    u:Kill()
                end
            end
            v:DetachFrom()
        end
    end
}

--- Base class for air transports.
AirTransport = Class(AirUnit, BaseTransport) {
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
}

