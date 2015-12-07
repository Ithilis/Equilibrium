--UEF Amphibious Tank Script

local oldUEL0203 = UEL0203
UEL0203 = Class(oldUEL0203) {

    OnLayerChange = function(self, new, old)
        THoverLandUnit.OnLayerChange(self, new, old)
        if( old != 'None' ) then
            if( new == 'Land' ) then
              self:SetSpeedMult(1)
            elseif( new == 'Water' ) then
                self:SetSpeedMult(.85)
            end
        end
    end,
}

TypeClass = UEL0203