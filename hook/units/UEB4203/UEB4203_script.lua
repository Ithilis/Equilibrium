--UEF Stealth/Jammed generator

local oldUEB4203 = UEB4203
UEB4203 = Class(oldUEB4203) {
    
    OnCreate = function(self)
        TRadarJammerUnit.OnCreate(self)
        self:DisableUnitIntel('Jammer')
    end,
    
}
TypeClass = UEB4203