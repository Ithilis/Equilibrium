-----------------------------------------------------------------
-- File     :  /lua/utilities.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Utility functions for scripts.
-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Quite similar in use to get GetTrueEnemyUnitsInSphere, but is more suitable for range finding applications due to terrain heights
function GetTrueEnemyUnitsInCylinder(unit, position, radius, height, categories)
    local x1 = position.x - radius
    local y1 = position.y - radius
    local z1 = position.z - radius
    local x2 = position.x + radius
    local y2 = position.y + radius
    local z2 = position.z + radius
    local UnitsinRec = GetUnitsInRect(Rect(x1, z1, x2, z2))
    local cylHeight = (height or 2*radius)/2
    --actually this is half of the height - the centre of the cyl is at the unit position
    --the stupid looking maths is so you dont perform arithmetic on a nil value

    -- Check for empty rectangle
    if not UnitsinRec then
        return UnitsinRec
    end

    local RadEntities = {}
    local unitArmy = unit:GetArmy()
    for _, v in UnitsinRec do
        local vpos = v:GetPosition()
        local dist = VDist2(position[1], position[3], vpos[1], vpos[3])
        if dist <= radius then --its less cpu time like this or something
            local vdist = math.abs(position[2] - vpos[2])
            local vArmy = v:GetArmy()
            if vdist <= radius and unitArmy ~= vArmy and not IsAlly(unitArmy, vArmy) and EntityCategoryContains(categories or categories.ALLUNITS, v) then
                table.insert(RadEntities, v)
            end
        end
    end

    return RadEntities
end