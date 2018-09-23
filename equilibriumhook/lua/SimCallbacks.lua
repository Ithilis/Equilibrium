--tells a unit to toggle its autorefuel
Callbacks.AutoRefuel = function(data, units)
    for _, u in units or {} do
        if IsEntity(u) and OkayToMessWithArmy(u:GetArmy()) and u.SetAutoRefuel then
            u:SetAutoRefuel(data.auto == true)
        end
    end
end

--tells a unit to toggle its pointer
Callbacks.FlagShield = function(data, units)
    units = SecureUnits(units)
    local target = GetEntityById(data.target)
    if units and target then
        for k, u in units do
            if IsEntity(u) and u.PointerEnabled == true then
                u.PointerEnabled = false --turn the pointer flag off
                u:DisablePointer() --turn the pointer off
            end
        end
    end
end

--improved priorities parser
Callbacks.WeaponPriorities = import('/lua/WeaponPriorities.lua').SetWeaponPriorities