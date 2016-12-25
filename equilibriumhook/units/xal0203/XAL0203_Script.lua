--Aeon Assault Tank Script

local oldXAL0203 = XAL0203
XAL0203 = Class(oldXAL0203) {

    OnLayerChange = function(self, new, old)
        AHoverLandUnit.OnLayerChange(self, new, old)
        if( old != 'None' ) then
            if( new == 'Land' ) then
              self:SetSpeedMult(1)
            elseif( new == 'Water' ) then
                self:SetSpeedMult(.85)
            end
        end
    end,
}
TypeClass = XAL0203