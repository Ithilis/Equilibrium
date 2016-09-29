#
# Terran Sub-Launched Cruise Missile
#
local TMissileCruiseSubProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseSubProjectile
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

OldTIFMissileCruise02 = TIFMissileCruise02

TIFMissileCruise02 = Class(OldTIFMissileCruise02) {
 
    OnImpact = function(self, targetType, targetEntity)
        local army = self:GetArmy()
        OldTIFMissileCruise02.OnImpact(self, targetType, targetEntity)
        
        local pos = self:GetPosition() --create a vision bubble at impact location
        local spec = {
            X = pos[1],
            Z = pos[3],
            Radius = self.Data.Radius,
            LifeTime = self.Data.Lifetime,
            Army = self.Data.Army,
            Omni = false,
            WaterVision = false,
        }
        local vizEntity = VizMarker(spec)
    end,
}

TypeClass = TIFMissileCruise02

