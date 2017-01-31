Callbacks.AutoRefuel = function(data, units)
    for _, u in units or {} do
        if IsEntity(u) and OkayToMessWithArmy(u:GetArmy()) and u.SetAutoRefuel then
            u:SetAutoRefuel(data.auto == true)
        end
    end
end
