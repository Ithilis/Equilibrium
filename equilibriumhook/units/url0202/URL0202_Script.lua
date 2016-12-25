#****************************************************************************
#**
#**  File     :  /cdimage/units/URL0202/URL0202_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran Heavy Tank Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CLandUnit = import('/lua/cybranunits.lua').CLandUnit
local CDFParticleCannonWeapon = import('/lua/cybranweapons.lua').CDFParticleCannonWeapon

URL0202 = Class(CLandUnit) {
    Weapons = {
        MainGun = Class(CDFParticleCannonWeapon) {
            CreateProjectileAtMuzzle = function(self, muzzle)
                local enabled = false
                for k, v in self.Beams do
                    if v.Muzzle == muzzle and v.Beam:IsEnabled() then
                        enabled = true
                    end
                end
                if not enabled then
                    self:PlayFxBeamStart(muzzle)
                end

                local bp = self:GetBlueprint()
                if self.unit:GetCurrentLayer() == 'Water' and bp.Audio.FireUnderWater then
                    self:PlaySound(bp.Audio.FireUnderWater)
                elseif bp.Audio.Fire then
                    if not self.FireNum or self.FireNum == 10 then
                        self.FireNum = 0
                        self:PlaySound(bp.Audio.Fire)
                    end
                    self.FireNum = self.FireNum + 1
                end
            end,
        },
    },
}

TypeClass = URL0202
