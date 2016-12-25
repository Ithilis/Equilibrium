-- UEF ACU NUKE TML

local TIFMissileNuke = import('/lua/terranprojectiles.lua').TIFMissileNuke
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

OldTIFMissileNukeCDR = TIFMissileNukeCDR

TIFMissileNukeCDR = Class(OldTIFMissileNukeCDR) {
    
    OnCreate = function(self)
        OldTIFMissileNukeCDR.OnCreate(self)
        --we grab some data from our launcher so we can create a vision blip. better do it here so no need for messy unit script.
        local bp = self:GetLauncher():GetBlueprint()
            self.Data = {
                Radius = bp.Weapon[5].CameraVisionRadius or 6,
                Lifetime = bp.Weapon[5].CameraLifetime or 6,
            }
    end,
    
    OnImpact = function(self, targetType, targetEntity)
        local army = self:GetArmy()
        TIFMissileNuke.OnImpact(self, targetType, targetEntity)
        
        local pos = self:GetPosition() --create a vision bubble at impact location
        local spec = {
            X = pos[1],
            Z = pos[3],
            Radius = self.Data.Radius,
            LifeTime = self.Data.Lifetime,
            Army = army,
            Omni = false,
            WaterVision = false,
        }
        local vizEntity = VizMarker(spec)
        
    end,
}
TypeClass = TIFMissileNukeCDR
