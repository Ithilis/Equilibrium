#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB2108/UEB2108_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Tactical Cruise Missile Launcher Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local TIFCruiseMissileLauncher = import('/lua/terranweapons.lua').TIFCruiseMissileLauncher
local EffectTemplate = import('/lua/EffectTemplates.lua')

UEB2108 = Class(TStructureUnit) {
    Weapons = {
        CruiseMissile = Class(TIFCruiseMissileLauncher) {
            FxMuzzleFlash = EffectTemplate.TIFCruiseMissileLaunchBuilding,
            
            
            
            CreateProjectileAtMuzzle = function(self, muzzle)   --added by Ithilis
                    local proj = TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
                    local data = {
                        Radius = self:GetBlueprint().CameraVisionRadius or 6,
                        Lifetime = self:GetBlueprint().CameraLifetime or 6,
                        Army = self.unit:GetArmy(),
                    }
                    if proj and not proj:BeenDestroyed() then
                        proj:PassData(data)
                    end
                end,
        },

    },
}
TypeClass = UEB2108