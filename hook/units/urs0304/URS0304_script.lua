local CSubUnit = import('/lua/cybranunits.lua').CSubUnit
local CybranWeapons = import('/lua/cybranweapons.lua')

local CIFMissileLoaWeapon = CybranWeapons.CIFMissileLoaWeapon
local CIFMissileStrategicWeapon = CybranWeapons.CIFMissileStrategicWeapon
local CANTorpedoLauncherWeapon = CybranWeapons.CANTorpedoLauncherWeapon

URS0304 = Class(CSubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        NukeMissile = Class(CIFMissileStrategicWeapon){},
        CruiseMissile = Class(CIFMissileLoaWeapon){},
        Torpedo01 = Class(CANTorpedoLauncherWeapon){
			OnWeaponFired = function(self, target)
				CANTorpedoLauncherWeapon.OnWeaponFired(self, target)
				ChangeState( self.unit, self.unit.VisibleState )
			end,
			
			OnLostTarget = function(self)
				CANTorpedoLauncherWeapon.OnLostTarget(self)
				if self.unit:IsIdleState() then
				    ChangeState( self.unit, self.unit.InvisState )
				end
			end,
        },
        Torpedo02= Class(CANTorpedoLauncherWeapon){
			OnWeaponFired = function(self, target)
				CANTorpedoLauncherWeapon.OnWeaponFired(self, target)
				ChangeState( self.unit, self.unit.VisibleState )
			end,
			
			OnLostTarget = function(self)
				CANTorpedoLauncherWeapon.OnLostTarget(self)
				if self.unit:IsIdleState() then
				    ChangeState( self.unit, self.unit.InvisState )
				end
			end,
        },
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

TypeClass = URS0304
