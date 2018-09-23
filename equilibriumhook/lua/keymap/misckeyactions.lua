-- This file contains key bindable actions that don't fit elsewhere

--EQ: add weapon priorities that are better performing.
function SetWeaponPriorities(prioritiesString, name, exclusive)
    local priotable
    if type(prioritiesString) == 'string' then
        priotable = prioritiesString
    end
    local units = GetSelectedUnits()
    if units then
        local unitIds = {}
    
        for _, unit in units do
            table.insert(unitIds, unit:GetEntityId())
        end

        SimCallback({Func = 'WeaponPriorities', Args = {SelectedUnits = unitIds, prioritiesTable = priotable, name = name, exclusive = exclusive or false }})
    end
end