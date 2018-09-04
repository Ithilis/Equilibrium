-----------------------------------------------------------------
-- File       : /lua/scenarioFramework.lua
-- Authors    : John Comes, Drew Staltman
-- Summary    : Functions for use in the scenario scripts.
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

--EQ:we end up using a system where each unit gets a timestamp, and this thread checks it,
--and removes the watervision effects of those that have expired.

SeabedRevealingUnits = {}

WaterVisionResetThread = function(self)
    --WARN('thread starting')
    WaitTicks(15) --initial delay

    while true do
        local tick = GetGameTick() --for some reason the timer ends a tick early but w.e.
        local units = SeabedRevealingUnits --get all units in our table
        
        --to avoid a complete mess, we filter the unit table and work out which units we need to touch.
        for key, unit in units do
            if not unit.Dead then
                if unit.WVizEndTick and unit.WVizEndTick <= tick then
                    unit.WVizEndTick = nil --clean the flag up when its not in use
                    if unit.NormalWVision then
                        --WARN('reseting wvision radius')
                        unit:SetIntelRadius('watervision', unit.NormalWVision)
                        unit.NormalWVision = nil --reset the variable so we can change it again if needed later
                    else
                        WARN('EQ:Unit is not dead and has expired watervision timestamp but no NormalWVision! Attempting to set to Blueprint value, then removing from table!')
                        WARN(unit.NormalWVision)
                        local bpValue = unit:GetBlueprint().Intel.WaterVisionRadius or 15
                        unit:SetIntelRadius('watervision', bpValue)
                    end
                    table.remove(SeabedRevealingUnits, key) --remove units with expired timers from our table
                end
            else
                table.remove(SeabedRevealingUnits, key) --remove dead units from our table
            end
        end
        
        --WARN(string.format('%s Units checked. GameTick: %s', table.getsize(units), tick))
        WaitTicks(11) --prepare to do the same thing next second. 11 because waitticks waits for ticks-1 for some reason.
    end
end

AutoRefuelingUnits = {}

AutoRefuelingPlatforms = {}

AirRefuelManagerThread = function()
    WaitTicks(15) --initial delay
    
    while true do
        --we stuff a table for each army with air units that need refueling, then assign them in a nice orderly fashion.
        local AirUnitsNeedServicing = {}
    
        local units = AutoRefuelingUnits --get all units in our table
        for key, unit in units do
            if unit.AutoRefuel == true and not unit.Dead then
                if (unit:GetFuelRatio() < 0.9 or unit:GetHealthPercent() < 0.6) and table.getsize(AutoRefuelingPlatforms) then
                    --ideally we would check the command queue to avoid refitting units that already have the command queued
                    --but that needs to go ui side to even run the command which seems pretty absurd
                    --really i just hate the sim side GetCommandQueue function - its so handicapped compared to the ui side one
                    local UnitCommandQ = unit:GetCommandQueue()
                    --we exclude units with multiple commands queued up since they have some job to do, this includes units ordered to refit.
                    if table.getn(UnitCommandQ) <= 1 then
                        --we need to check for the army every time instead of saving as a value since they can be given
                        local army = unit:GetArmy()
                        if not AirUnitsNeedServicing[army] then
                            AirUnitsNeedServicing[army] = {}
                        end
                        table.insert(AirUnitsNeedServicing[army], unit)
                    end
                end
            else
                table.remove(AutoRefuelingUnits, key) --remove dead/inactive units from our table
            end
        end
        
        for army, platforms in AutoRefuelingPlatforms do
            --assign 4 free slots to each staging platform, so we dont order more planes than it has space for.
            --this is because platform:TransportHasSpaceFor(unit) has a delay on being active so we cant assign slots in one tick.
            local checkedPlats = platforms
            for key, platform in checkedPlats do
                platform.TrueUsedSlots = 0
                if platform.Dead then
                    checkedPlats[key] = nil
                    AutoRefuelingPlatforms[army][key] = nil
                end
            end
            if AirUnitsNeedServicing[army][1] then
                AssignPlatforms(AirUnitsNeedServicing[army], checkedPlats)
            end
            --WARN('platforms monitored in global table: '..table.getsize(AutoRefuelingPlatforms[army]))
        end
        
        --WARN('units being monitored: '..table.getsize(AutoRefuelingUnits))
        WaitTicks(30)
    end
end



AssignPlatforms = function(unitsTable, platsTable)
    
    local unusedGlobalPlatforms = {}
    
    --apparently if we dont stuff the table like this, it will remove the platform from AutoRefuelingPlatforms which is outside this function, well whatever.
    for key, plat in platsTable do
        unusedGlobalPlatforms[key] = plat
    end
    
    -- Find air stage
    for key, unit in unitsTable do
        local unitPos = unit:GetPosition()
        local platPos = unitPos--temp value
        local freePlatsForUnit = {}
        for key, plat in unusedGlobalPlatforms do
            if plat:TransportHasSpaceFor(unit) then
                freePlatsForUnit[key] = plat
            end
        end
        
        
        if table.getsize(freePlatsForUnit) > 0 then
            --sort the list of empty platforms by distance
            local closest = FilterPlatforms(unitPos, freePlatsForUnit)
            --assign unit to dock at nearest platform
            if closest then
                IssueStop( {unit} )
                IssueClearCommands( {unit} )
                IssueTransportLoad( {unit}, closest )
                platPos = closest:GetPosition()
                platPos[3] = platPos[3] + 10
                IssueMove( {unit}, platPos) --queue move order after dock
                
                --tell the platform its being filled.
                closest.TrueUsedSlots = closest.TrueUsedSlots + (unit.TransportClass or 1)
            end
            
            if closest and closest.TrueUsedSlots > 3 then
                if closest.Dead then
                    WARN('EQ: found a dead platform when it just checked for dead platforms! skipping this one')
                else
                    unusedGlobalPlatforms[closest:GetEntityId()] = nil
                end
            end
            
        else
            --sort the list of all platforms by distance
            local closest, nearbyPlats = FilterPlatforms(unitPos, platsTable)
            if not nearbyPlats and closest then
            --assign unit to move to platform if none are nearby
                platPos = closest:GetPosition()
                IssueMove( {unit}, platPos)
            end
            --otherwise if we are already near a platform then do nothing, since we are waiting for them to free up, or we are way out.
        end
        
    end
    
end

--filters out staging platforms by distance category, returns the closest and a flag if its really close
FilterPlatforms = function(unitPos, platforms)
        local platsInRange = {}
        local nearbyPlats = false
        
        for k, plat in platforms do
            platPos = plat:GetPosition()
            local dist = VDist2(unitPos[1], unitPos[3], platPos[1], platPos[3])
            if dist < 400 then
                table.insert(platsInRange, plat)
                if dist < 15 then
                    return platsInRange[1], true --no need to bother sorting or continuing if the platforms so close, just use this one.
                end
            end
        end
        
        if not platsInRange[1] then
            return false, false
        elseif platsInRange[2] then
            table.sort(platsInRange, function(a,b)--sort all our staging platforms by distance
                local platPosA = a:GetPosition()
                local platPosB = b:GetPosition()
                local distA = VDist2(unitPos[1], unitPos[3], platPosA[1], platPosA[3])
                local distB = VDist2(unitPos[1], unitPos[3], platPosB[1], platPosB[3])
                return distA < distB
            end)
        end
        
        return platsInRange[1], nearbyPlats
end

