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
        WaitTicks(11) --prepare to do the same thing next tick. 11 because waitticks waits for ticks-1 for some reason.
    end
end
