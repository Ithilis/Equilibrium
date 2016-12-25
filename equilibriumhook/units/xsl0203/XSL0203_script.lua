--Seraphim Amphibious Tank Script

local oldXSL0203 = XSL0203
XSL0203 = Class(oldXSL0203) {

    OnLayerChange = function(self, new, old)
        SHoverLandUnit.OnLayerChange(self, new, old)
        if( old != 'None' ) then
            if( new == 'Land' ) then
              self:SetSpeedMult(1)
            elseif( new == 'Water' ) then
                self:SetSpeedMult(.85)
            end
        end
    end,
}
TypeClass = XSL0203