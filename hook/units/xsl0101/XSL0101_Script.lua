#Sera Selen

local oldXSL0101 = XSL0101
XSL0101 = Class(oldXSL0101) {

    InvisState = State() {
        Main = function(self)
            self.Cloaked = false
            local bp = self:GetBlueprint()
            if bp.Intel.StealthWaitTime then
                WaitSeconds( bp.Intel.StealthWaitTime )
            end
			self:EnableUnitIntel('RadarStealth')
			self:EnableUnitIntel('Cloak')
			self:SetWeaponEnabledByLabel('LaserTurret', false)	--add Ithilis
			self.Cloaked = true
        end,
        
        OnMotionHorzEventChange = function(self, new, old)
            if new != 'Stopped' then
                ChangeState( self, self.VisibleState )
            end
            SWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
        end,
    },
    
    VisibleState = State() {
        Main = function(self)
            if self.Cloaked then
                self:DisableUnitIntel('RadarStealth')
			    self:DisableUnitIntel('Cloak')
				self:SetWeaponEnabledByLabel('LaserTurret', true)	--add Ithilis
			end
        end,
        
        OnMotionHorzEventChange = function(self, new, old)
            if new == 'Stopped' then
                ChangeState( self, self.InvisState )
            end
            SWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
        end,
    },
	
}
TypeClass = XSL0101