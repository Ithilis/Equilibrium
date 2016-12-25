--UEF mml missiles

local TMissileCruiseProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local SingleBeamProjectile = import('/lua/sim/defaultprojectiles.lua').SingleBeamProjectile
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

OldTIFMissileCruise03 = TIFMissileCruise03

TIFMissileCruise03 = Class(OldTIFMissileCruise03) {
    
    OnCreate = function(self)
        OldTIFMissileCruise03.OnCreate(self)
        --we grab some data from our launcher so we can create a vision blip. better do it here so no need for messy unit script.
        local bp = self:GetLauncher():GetBlueprint()
            self.Data = {
                Radius = bp.Weapon[1].CameraVisionRadius or 6,
                Lifetime = bp.Weapon[1].CameraLifetime or 6,
            }
    end,
    
    OnImpact = function(self, targetType, targetEntity)
        local army = self:GetArmy()
        SingleBeamProjectile.OnImpact(self, targetType, targetEntity)
        
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
TypeClass = TIFMissileCruise03

