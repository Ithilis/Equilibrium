-- UEF t3 nuke sub tml

local TMissileCruiseSubProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseSubProjectile
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

OldTIFMissileCruise02 = TIFMissileCruise02

TIFMissileCruise02 = Class(OldTIFMissileCruise02) {
 
     OnCreate = function(self)
        OldTIFMissileCruise02.OnCreate(self)
        --we grab some data from our launcher so we can create a vision blip. better do it here so no need for messy unit script.
        local bp = self:GetLauncher():GetBlueprint()
            self.Data = {
                Radius = bp.Weapon[1].CameraVisionRadius or 6,
                Lifetime = bp.Weapon[1].CameraLifetime or 6,
            }
    end,
    
    OnImpact = function(self, targetType, targetEntity)
        local army = self:GetArmy()
        OldTIFMissileCruise02.OnImpact(self, targetType, targetEntity)
        
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

TypeClass = TIFMissileCruise02

