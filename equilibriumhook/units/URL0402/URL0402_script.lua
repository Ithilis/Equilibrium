--------------------------------------------------------------------------
-- File     :  /cdimage/units/URL0402/URL0402_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Spider Bot Script
-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit

oldURL0402 = URL0402


--EQ: just a visual change, making the smoke effects only appear when the unit is complete
URL0402 = Class(oldURL0402) {
    OnStopBeingBuilt = function(self, builder, layer)
        oldURL0402.OnStopBeingBuilt(self, builder, layer)
        self:CreateUnitAmbientEffect(layer)--layer
    end,

    OnLayerChange = function(self, new, old)--this gets called when the unit is created as well
        CWalkingLandUnit.OnLayerChange(self, new, old)
        if self:GetFractionComplete() == 1 then
            self:CreateUnitAmbientEffect(new)
        end
        if new == 'Seabed' then
            self:EnableUnitIntel('Layer', 'Sonar')
        else
            self:DisableUnitIntel('Layer', 'Sonar')
        end
    end,
}

TypeClass = URL0402
