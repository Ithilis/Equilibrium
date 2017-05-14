local AIUtils = import('/lua/ai/aiutilities.lua')
local GetRandomFloat = import('utilities.lua').GetRandomFloat

--------------------------------------------------------------
--  AIR UNITS
---------------------------------------------------------------

--veterancy system added
--auto refuel toggle button added
local oldAirUnit = AirUnit

AirUnit = Class(oldAirUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        local bp = self:GetBlueprint()
        if not bp.Air.DisableAutoRefuel then
            self:SetAutoRefuel(true) --on by default
        end
        --TODO: make this only work for units that have the dock order available.
        oldAirUnit.OnStopBeingBuilt(self,builder,layer)
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
        -- Find air stage
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