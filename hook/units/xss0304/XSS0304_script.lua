--Seaphim Submarine Hunter Script

local oldXSS0304 = XSS0304
XSS0304 = Class(oldXSS0304) {

    OnStopBeingBuilt = function(self, builder, layer)
        SSubUnit.OnStopBeingBuilt(self, builder, layer)
        self:DisableUnitIntel('RadarStealth')
        self:DisableUnitIntel('SonarStealth')
        self.Cloaked = false
        ChangeState( self, self.InvisState ) -- If spawned in we want the unit to be invis, normally the unit will immediately start moving
    end,
    
    
    InvisState = State() {
        Main = function(self)
            self.Cloaked = false
            local bp = self:GetBlueprint()
            if bp.Intel.StealthWaitTime then
                WaitSeconds( bp.Intel.StealthWaitTime )
            end
            self:EnableUnitIntel('RadarStealth')
            self:EnableUnitIntel('SonarStealth')
            self.Cloaked = true
        end,
        
        OnMotionHorzEventChange = function(self, new, old)
            if new != 'Stopped' then
                ChangeState( self, self.VisibleState )
            end
            SSubUnit.OnMotionHorzEventChange(self, new, old)
        end,
    },
    
    VisibleState = State() {
        Main = function(self)
            if self.Cloaked then
                self:DisableUnitIntel('RadarStealth')
                self:DisableUnitIntel('SonarStealth')
            end
        end,
        
        OnMotionHorzEventChange = function(self, new, old)
            if new == 'Stopped' then
                ChangeState( self, self.InvisState )
            end
            SSubUnit.OnMotionHorzEventChange(self, new, old)
        end,
    },

}
TypeClass = XSS0304