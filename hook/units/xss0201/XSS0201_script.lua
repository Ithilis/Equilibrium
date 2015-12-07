--Seraphim Destroyer Script

local oldXSS0201 = XSS0201
XSS0201 = Class(oldXSS0201) {

    Weapons = {
        FrontTurret = Class(SDFUltraChromaticBeamGenerator) {},
        BackTurret = Class(SDFUltraChromaticBeamGenerator) {},
        Torpedo1 = Class(SANAnaitTorpedo) {},
        AntiTorpedo = Class(SDFAjelluAntiTorpedoDefense) {},
        Torpedo2 = Class(SANAnaitTorpedo) {},
    },

    OnMotionVertEventChange = function( self, new, old )
        SSubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetWeaponEnabledByLabel('FrontTurret', true)
            self:SetWeaponEnabledByLabel('BackTurret', true)
            self:SetMaintenanceConsumptionInactive()
        elseif new == 'Down' then
            self:SetWeaponEnabledByLabel('FrontTurret', false)
            self:SetWeaponEnabledByLabel('BackTurret', false)
            self:SetMaintenanceConsumptionActive()
        end
    end,
}
TypeClass = XSS0201