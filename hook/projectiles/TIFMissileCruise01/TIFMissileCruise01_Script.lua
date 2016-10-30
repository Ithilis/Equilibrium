-- UEF stationary TML

local TMissileCruiseProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseProjectile02
local Explosion = import('/lua/defaultexplosions.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

OldTIFMissileCruise01 = TIFMissileCruise01

TIFMissileCruise01 = Class(OldTIFMissileCruise01) {

    OnCreate = function(self)
        OldTIFMissileCruise01.OnCreate(self)
        --we grab some data from our launcher so we can create a vision blip. better do it here so no need for messy unit script.
        local owner = self:GetLauncher()
        local bp = owner:GetBlueprint()
        
            self.Data = {
                Radius = bp.Weapon[1].CameraVisionRadius or 6,
                Lifetime = bp.Weapon[1].CameraLifetime or 6,
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
TypeClass = TIFMissileCruise01

