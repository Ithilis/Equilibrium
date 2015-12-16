-- Sera Spy Plane Script

local oldXSA0302 = XSA0302
XSA0302 = Class(oldXSA0302) {

    OnStopBeingBuilt = function(self, builder, layer)
        SAirUnit.OnStopBeingBuilt(self, builder, layer)
        self:DisableUnitIntel('RadarStealth')
        self:DisableUnitIntel('Cloak')
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
            self:EnableUnitIntel('Cloak')
            self.Cloaked = true
        end,
        
        OnMotionHorzEventChange = function(self, new, old)
            if new != 'Stopped' then
                ChangeState( self, self.VisibleState )
            end
            SAirUnit.OnMotionHorzEventChange(self, new, old)
        end,
    },
    
    VisibleState = State() {
        Main = function(self)
            if self.Cloaked then
                self:DisableUnitIntel('RadarStealth')
                self:DisableUnitIntel('Cloak')
            end
        end,
        
        OnMotionHorzEventChange = function(self, new, old)
            if new == 'Stopped' then
                ChangeState( self, self.InvisState )
            end
            SAirUnit.OnMotionHorzEventChange(self, new, old)
        end,
    },

}
TypeClass = XSA0302