#****************************************************************************
#**
#**  File     :  /cdimage/units/UAL0106/UAL0106_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Light Assault Bot Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AWalkingLandUnit = import('/lua/aeonunits.lua').AWalkingLandUnit
local ADFSonicPulsarWeapon = import('/lua/aeonweapons.lua').ADFSonicPulsarWeapon
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

UAL0106 = Class(AWalkingLandUnit) {
    Weapons = {
        ArmLaserTurret = Class(ADFSonicPulsarWeapon) {}
    },
	
	OnKilled = function(self, instigator, type, overkillRatio)
        AWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
        local pos = self:GetPosition()
        local spec = {
            X = pos[1],
            Z = pos[3],
            Radius = self:GetBlueprint().Intel.VisionRadiusOnDeath,
            LifeTime = self:GetBlueprint().Intel.IntelDurationOnDeath,
            Army = self:GetArmy(),
            Omni = false,
            WaterVision = false,
        }
        local vizEntity = VizMarker(spec)
  	end,

}

TypeClass = UAL0106
