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
        local neededUnits = {}
        local tick = GetGameTick() --for some reason the timer ends a tick early but w.e.
        local units = SeabedRevealingUnits --get all units in our table
        
        --to avoid a complete mess, we filter the unit table and work out which units we need to touch.
        for key, unit in units do
            if not unit.Dead then
                if unit.WVizEndTick ~= false and unit.WVizEndTick <= tick then
                    unit.WVizEndTick = nil --clean the flag up when its not in use
                    table.insert(neededUnits, unit)
                end
            else
            table.remove(SeabedRevealingUnits, key) --remove the units from our table
            end
        end
        
        for key, unit in neededUnits do
            --normally this should be checked for IsDead, but we already checked during the filtering.
            if unit.NormalWVision then
                --WARN('reseting wvision radius')
                unit:SetIntelRadius('watervision', unit.NormalWVision)
                unit.NormalWVision = nil --reset the variable so we can change it again if needed later
                table.remove(SeabedRevealingUnits, key) --remove the units from our table
            else
            WARN('EQ:Unit is not dead and has expired watervision timestamp but no NormalWVision! not removing from table!')
            end
        end
        --WARN(string.format('%s Units checked. %s Units Reset. GameTick: %s', table.getsize(units), table.getsize(neededUnits), tick))
        WaitTicks(11) --prepare to do the same thing next tick. 11 because waitticks waits for ticks-1 for some reason.
    end
end
