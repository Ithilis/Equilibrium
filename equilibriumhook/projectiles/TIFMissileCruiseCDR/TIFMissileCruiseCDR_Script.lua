-- UEF ACU TML

local TMissileCruiseProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseProjectile02
local Explosion = import('/lua/defaultexplosions.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

OldTIFMissileCruiseCDR = TIFMissileCruiseCDR

TIFMissileCruiseCDR = Class(OldTIFMissileCruiseCDR) {
    
    OnCreate = function(self)
        OldTIFMissileCruiseCDR.OnCreate(self)
        --we grab some data from our launcher so we can create a vision blip. better do it here so no need for messy unit script.
        local bp = self:GetLauncher():GetBlueprint()
            self.Data = {
                Radius = bp.Weapon[4].CameraVisionRadius or 6,
                Lifetime = bp.Weapon[4].CameraLifetime or 6,
            }
    end,
    
    OnImpact = function(self, targetType, targetEntity)
        local army = self:GetArmy()
        TMissileCruiseProjectile.OnImpact(self, targetType, targetEntity)
        
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
TypeClass = TIFMissileCruiseCDR

