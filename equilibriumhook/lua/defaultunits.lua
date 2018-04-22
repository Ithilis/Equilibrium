local AIUtils = import('/lua/ai/aiutilities.lua')
local GetRandomFloat = import('utilities.lua').GetRandomFloat
--------------------------------------------------------------
--  AIR UNITS
---------------------------------------------------------------

--veterancy system added
--auto refuel toggle button added
oldAirUnit = AirUnit

AirUnit = Class(oldAirUnit) {
    
    OnStopBeingBuilt = function(self,builder,layer)
        local bp = self:GetBlueprint()
        if not bp.Air.DisableAutoRefuel then
            self:SetAutoRefuel(true) --on by default
        end
        --WARN('onstopbeingbuilt inside an air unit apparently')
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
        while self.AutoRefuel == true and not self:IsDead() do
            if (self.AutoRefuel and (self:GetFuelRatio() < 0.2 or self:GetHealthPercent() < 0.6)) and not self.AlreadyAttached then
                --ideally we would check the command queue to avoid refitting units that already have the command queued
                --but that needs to go ui side to even run the command which seems pretty absurd
                --really i just hate the sim side GetCommandQueue function - its so handicapped compared to the ui side one
                local UnitCommandQ = self:GetCommandQueue()
                --we exclude units with multiple commands queued up since they have some job to do, this includes units ordered to refit.
                if table.getn(UnitCommandQ) <= 1 then
                    self:AirUnitRefit()
                end
            end
            
            WaitSeconds(15)
        end
    end,

    AirUnitRefit = function(self)
        local aiBrain = self:GetAIBrain()
        -- Find air stage
        if aiBrain:GetCurrentUnits( categories.AIRSTAGINGPLATFORM ) > 0 then
            local unitPos = self:GetPosition()
            local plats = AIUtils.GetOwnUnitsAroundPoint( aiBrain, categories.AIRSTAGINGPLATFORM - categories.CARRIER - categories.NOAUTOREFUEL, unitPos, 400 )
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
                    platPos = plats[1]:GetPosition()
                    platPos[3] = platPos[3] + 10
                    IssueMove( {self}, platPos) --queue a move order for something like a rally point
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
                if EntityCategoryContains( categories.CARRIER, v ) or EntityCategoryContains( categories.NOAUTOREFUEL, v ) then
                    --roomAvailable = v:TransportHasAvailableStorage( self )
                    WARN('EQ: found a carrier or no auto fuel unit when refueling. issuing move order to location')
                    --we dont land on carriers and such since docking is bugged when the carrier is moving
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

oldAirTransport = AirTransport
AirTransport = Class(oldAirTransport, AirUnit) {} --disgusting.

oldACUUnit = ACUUnit

ACUUnit = Class(oldACUUnit) {
    OnKilledUnit = function(self, unitKilled, massKilled)
        --we intercept this function and just make it do nothing again so the acu doesnt follow any crazy rules regarding vet.
        CommandUnit.OnKilledUnit(self, unitKilled, massKilled)
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

--this is so maddening i cant begin to describe it.
--for some ABSURD reason only like half of the units decide to even notice StructureUnit in this file, and its NOTHING to do with function overwriting or anything else i could tell.
--if it hooks ANYTHING in defaultunits.lua (the fa version) it just goddamn ignores this class. you can put anything bar syntax errors in here and it wont care.
--as a result, i gave up and the great rebuild functionality works perfectly for only half of the buildings. i tried.
--m a d d e n i n g

-- STRUCTURE UNITS
StructureUnit = Class(oldStructureUnit) {

    OnKilled = function(self, instigator, type, overkillRatio)
        --WARN('m a d d e n i n g')
        oldStructureUnit.OnKilled(self, instigator, type, overkillRatio)
        local engies = EntityCategoryFilterDown(categories.ENGINEER * categories.TECH3, self:GetGuards())
        if engies[1] then
            for _, u in engies do
                u:SetFocusEntity(self)
                self.Repairers[u:GetEntityId()] = u
            end
        end

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
}

--i cant believe i had to do this. this is insane on so many levels. if you ever want to take this code just do it properly instead.
function RebuildUnitInsanity(SuperClass)
    return Class(SuperClass) {
        
        OnKilled = function(self, instigator, type, overKillRatio)
            SuperClass.OnKilled(self, instigator, type, overKillRatio)
            local engies = EntityCategoryFilterDown(categories.ENGINEER * categories.TECH3, self:GetGuards())
            if engies[1] then
                for _, u in engies do
                    u:SetFocusEntity(self)
                    self.Repairers[u:GetEntityId()] = u
                end
            end
            --WARN('m a d d e n i n g')
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
        
        --override OC changes so the structure damage isnt just capped.
        DoTakeDamage = function(self, instigator, amount, vector, damageType)
            Unit.DoTakeDamage(self, instigator, amount, vector, damageType)
        end,
    }    
end

--end me now i swear
StructureUnit = RebuildUnitInsanity(StructureUnit)
LandFactoryUnit = RebuildUnitInsanity(LandFactoryUnit)
AirFactoryUnit = RebuildUnitInsanity(AirFactoryUnit)
EnergyCreationUnit = RebuildUnitInsanity(EnergyCreationUnit)
EnergyStorageUnit = RebuildUnitInsanity(EnergyStorageUnit)
AirStagingPlatformUnit = RebuildUnitInsanity(AirStagingPlatformUnit)
--FactoryUnit = RebuildUnitInsanity(FactoryUnit)
MassCollectionUnit = RebuildUnitInsanity(MassCollectionUnit)
MassFabricationUnit = RebuildUnitInsanity(MassFabricationUnit)
MassStorageUnit = RebuildUnitInsanity(MassStorageUnit)
RadarUnit = RebuildUnitInsanity(RadarUnit)
RadarJammerUnit = RebuildUnitInsanity(RadarJammerUnit)
SonarUnit = RebuildUnitInsanity(SonarUnit)
ShieldStructureUnit = RebuildUnitInsanity(ShieldStructureUnit)
SeaFactoryUnit = RebuildUnitInsanity(SeaFactoryUnit)
QuantumGateUnit = RebuildUnitInsanity(QuantumGateUnit)


-- FACTORY UNITS
--same crap as above. disgusting.
--here we rotate units based on the direction they should be facing when they just finish building so they dont get stuck in there.

function FactoryRolloffInsanity(SuperClass)
    return Class(SuperClass) {
        FinishBuildThread = function(self, unitBeingBuilt, order)
            self:SetBusy(true)
            self:SetBlockCommandQueue(true)
            
            local spin, x, y, z = self:CalculateRollOffPoint() --eq: rotate the unit so it faces the right way when we finish not start building
            if self.BuildBoneRotator then
                self.BuildBoneRotator:SetGoal(spin)
            end
            WaitTicks(1) -- give the rotator time to rotate the unit before detaching
            SuperClass.FinishBuildThread(self, unitBeingBuilt, order)
        end,
    
    }
end

--apply the hook, this should have been so much easier inside FactoryUnit but that gets ignored since this file is added on the end of defaultunits.lua which makes the class inherited before
--so this is like an alternate reality version, so we need to re-apply it to all its child classes again. xdddddddddd
LandFactoryUnit = FactoryRolloffInsanity(LandFactoryUnit)
AirFactoryUnit = FactoryRolloffInsanity(AirFactoryUnit)
--SeaFactoryUnit = FactoryRolloffInsanity(SeaFactoryUnit)