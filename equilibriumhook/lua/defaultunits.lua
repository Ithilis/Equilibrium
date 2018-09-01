--------------------------------------------------------------
--  AIR UNITS
---------------------------------------------------------------
--auto refuel toggle button added

local AutoRefuelingUnits = import('/lua/scenarioFramework.lua').AutoRefuelingUnits --import our table for storing units
oldAirUnit = AirUnit

AirUnit = Class(oldAirUnit) {
    
    OnStopBeingBuilt = function(self,builder,layer)
        local bp = self:GetBlueprint()
        if not bp.Air.DisableAutoRefuel then
            self:SetAutoRefuel(true) --on by default
        end
        local ClassTranslate = {1,2,4}
        self.TransportClass = ClassTranslate[bp.Transport.TransportClass]
        --TODO: make this only work for units that have the dock order available.
        oldAirUnit.OnStopBeingBuilt(self,builder,layer)
    end,
    
    SetAutoRefuel = function(self, auto)
        self.Sync.AutoRefuel = auto
        self.AutoRefuel = auto
        
        if self.AutoRefuel == true then
            table.insert(AutoRefuelingUnits, self) --insert our unit into a table to be monitored later
        end
    end,
}

oldAirTransport = AirTransport
AirTransport = Class(oldAirTransport, AirUnit) {} --disgusting.



-------------------------------------------------------------
--  AIR STAGING PLATFORMS UNITS
-------------------------------------------------------------
oldAirStagingPlatformUnit = AirStagingPlatformUnit

local AutoRefuelingPlatforms = import('/lua/scenarioFramework.lua').AutoRefuelingPlatforms --import table for keeping track of platforms

AirStagingPlatformUnit = Class(oldAirStagingPlatformUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        oldAirStagingPlatformUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
        
        local army = self:GetArmy()
        if not AutoRefuelingPlatforms[army] then
            AutoRefuelingPlatforms[army] = {}
        end
        AutoRefuelingPlatforms[army][self:GetEntityId()] = self
    end,
}

-----------------------------------------------------------------
--  ACU UNITS
-----------------------------------------------------------------
--veterancy system added

oldACUUnit = ACUUnit

ACUUnit = Class(oldACUUnit) {
    OnKilledUnit = function(self, unitKilled, massKilled)
        --we intercept this function and just make it do nothing again so the acu doesnt follow any crazy rules regarding vet.
        CommandUnit.OnKilledUnit(self, unitKilled, massKilled)
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
        
        --replace this so that everything rotates to nearest 90 and not just whatever
        RotateTowardsEnemy = function(self)
            local bp = self:GetBlueprint()
            local army = self:GetArmy()
            local brain = self:GetAIBrain()
            local pos = self:GetPosition()
            local x, y = GetMapSize()
            local threats = {{pos = {x / 2, 0, y / 2}, dist = VDist2(pos[1], pos[3], x, y), threat = -1}}
            local cats = EntityCategoryContains(categories.ANTIAIR, self) and categories.AIR or (categories.STRUCTURE + categories.LAND + categories.NAVAL)
            local units = brain:GetUnitsAroundPoint(cats, pos, 2 * (bp.AI.GuardScanRadius or 100), 'Enemy')
            for _, u in units do
                local blip = u:GetBlip(army)
                if blip then
                    local on_radar = blip:IsOnRadar(army)
                    local seen = blip:IsSeenEver(army)

                    if on_radar or seen then
                        local epos = u:GetPosition()
                        local threat = seen and (u:GetBlueprint().Defense.SurfaceThreatLevel or 0) or 1

                        table.insert(threats, {pos = epos, threat = threat, dist = VDist2(pos[1], pos[3], epos[1], epos[3])})
                    end
                end
            end

            table.sort(threats, function(a, b)
                if a.threat <= 0 and b.threat <= 0 then
                    return a.threat == b.threat and a.dist < b.dist or a.threat > b.threat
                elseif a.threat <= 0 then return false
                elseif b.threat <= 0 then return true
                else return a.dist < b.dist end
            end)

            local t = threats[1]
            local rad = math.atan2(t.pos[1]-pos[1], t.pos[3]-pos[3])
            local degrees = rad * (180 / math.pi)
            
            --EQ:only bit we change, just remove the if condition
            degrees = math.floor((degrees + 45) / 90) * 90

            self:SetRotation(degrees)
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