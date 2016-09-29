--
-- Terran CDR Nuke
--
local TIFMissileNuke = import('/lua/terranprojectiles.lua').TIFMissileNuke
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

OldTIFMissileNukeCDR = TIFMissileNukeCDR

TIFMissileNukeCDR = Class(OldTIFMissileNukeCDR) {

    OnImpact = function(self, targetType, targetEntity)
        local army = self:GetArmy()
        TIFMissileNuke.OnImpact(self, targetType, targetEntity)
        
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
TypeClass = TIFMissileNukeCDR
