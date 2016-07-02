#****************************************************************************
#**
#**  File     :  /data/units/XRS0204/XRS0204_script.lua
#**  Author(s):  Jessica St. Croix
#**
#**  Summary  :  Cybran Sub Killer Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CSubUnit = import('/lua/cybranunits.lua').CSubUnit
local WeaponsFile = import('/lua/cybranweapons.lua')
local CANNaniteTorpedoWeapon = WeaponsFile.CANNaniteTorpedoWeapon
local CIFSmartCharge = WeaponsFile.CIFSmartCharge

XRS0204 = Class(CSubUnit) {
    DeathThreadDestructionWaitTime = 0,

    Weapons = {
        Torpedo01 = Class(CANNaniteTorpedoWeapon) {
			OnWeaponFired = function(self, target)
				CANNaniteTorpedoWeapon.OnWeaponFired(self, target)
				ChangeState( self.unit, self.unit.VisibleState )
			end,
			
			OnLostTarget = function(self)
				CANNaniteTorpedoWeapon.OnLostTarget(self)
				if self.unit:IsIdleState() then
				    ChangeState( self.unit, self.unit.InvisState )
				end
			end,
        },
        AntiTorpedo01 = Class(CIFSmartCharge) {},
        AntiTorpedo02 = Class(CIFSmartCharge) {},
    },
    OnCreate = function(self)
        CSubUnit.OnCreate(self)
        self:SetMaintenanceConsumptionActive()
    end,
    
    OnStopBeingBuilt = function(self, builder, layer)
        CSubUnit.OnStopBeingBuilt(self, builder, layer)
        
        --These start enabled, so before going to InvisState, disabled them.. they'll be reenabled shortly
        self:DisableUnitIntel('RadarStealth')
        self:DisableUnitIntel('SonarStealth')
        self:SetMaintenanceConsumptionInactive()
        self.Stealthed = false
        ChangeState( self, self.InvisState ) -- If spawned in we want the unit to be invis, normally the unit will immediately start moving
    end,
    
    
    InvisState = State() {
        Main = function(self)
            self.Stealthed = false
            
            WaitSeconds(1)
            
			self:EnableUnitIntel('RadarStealth')
            self:EnableUnitIntel('SonarStealth')
            self:SetMaintenanceConsumptionActive()
            self.Stealthed = true
        end,
    },
    
    VisibleState = State() {
        Main = function(self)
            if self.Stealthed then
                self:DisableUnitIntel('RadarStealth')
                self:DisableUnitIntel('SonarStealth')
                self:SetMaintenanceConsumptionInactive()
                self.Stealthed = false
			end
        end,
    },

}

TypeClass = XRS0204