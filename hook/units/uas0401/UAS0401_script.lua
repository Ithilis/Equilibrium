--Aeon Experimental Submarine

local oldUAS0401 = UAS0401
UAS0401 = Class(oldUAS0401) {

    OnStopBeingBuilt = function(self,builder,layer)
        self:SetWeaponEnabledByLabel('MainGun', true)
        ASeaUnit.OnStopBeingBuilt(self,builder,layer)
        if layer == 'Water' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
            self:SetMaintenanceConsumptionInactive()
        else
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
        end
        ChangeState(self, self.IdleState)
    end,

    OnMotionVertEventChange = function( self, new, old )
        ASeaUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
            self:SetWeaponEnabledByLabel('MainGun', true)
            self:PlayUnitSound('Open')
            self:SetMaintenanceConsumptionInactive()
        elseif new == 'Down' then
            self:SetWeaponEnabledByLabel('MainGun', false)
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
            self:PlayUnitSound('Close')
            self:SetMaintenanceConsumptionActive()
        end
    end,
    
}

TypeClass = UAS0401