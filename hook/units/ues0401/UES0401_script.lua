--UEF Experimental Submersible Aircraft Carrier Script

local oldUES0401 = UES0401
UES0401 = Class(oldUES0401) {

    OnMotionVertEventChange = function( self, new, old )
        TSeaUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Down' then
            self:PlayAllOpenAnims(false)
            self:SetMaintenanceConsumptionActive()
        elseif new == 'Top' then
            self:PlayAllOpenAnims(true)
            self:SetMaintenanceConsumptionInactive()
        end
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        TSeaUnit.OnStopBeingBuilt(self,builder,layer)
        ChangeState(self, self.IdleState)
        self:SetMaintenanceConsumptionInactive()
    end,

}

TypeClass = UES0401
