local parsedPriorities
local ParseEntityCategoryProperly = import('/lua/sim/CategoryUtils.lua').ParseEntityCategoryProperly

--we are loading an arbitrary string that a user can send to us on the sim side.
--in order to not break things, we sanitize the input first before doing anything with it.
function HandleInputString(inputString)
    local inputTable = false
    --we check that its a table by its first character
    --we also check that it doesnt contain any functions that would have been run, by looking for "("
    if string.sub(inputString, 1, 1) == "{" and not string.find(inputString,"%(") then
        --this checks for syntax errors in the string so we can continue onwards.
        --for some reason the compiling also works out if the categories even exist? well whatever that just makes this work better i guess.
        if pcall(loadstring("return "..inputString)) then
                --WARN('would have totally run this string just now: '..inputString)
                inputTable = loadstring("return "..inputString)()
        else
            WARN('Syntax error in target priorities string, was discarded: '..inputString)
        end
    else
        WARN('Target priorities string contained improper content, so was discarded: '..inputString)
    end
    return inputTable
end

function SetWeaponPriorities(data)

    local selectedUnits = data.SelectedUnits
    local prioritiesTable
    local editedPriorities = {categories.ALLUNITS}
    local default
    local name

    -- parse and save all default priorities (we do it only once)
    if not parsedPriorities then
        parsedPriorities = parseDefaultPriorities()
    end

    if not selectedUnits then return end

    if data.prioritiesTable then
        prioritiesTable = HandleInputString(data.prioritiesTable)
    end

    if not prioritiesTable then
        default = true
    elseif prioritiesTable[1] then
        --we need to make sure that any table is appended properly, so you never have a situation where a unit cant fire.
        local mergedPriorities = prioritiesTable
        for k,v in editedPriorities do
            table.insert(mergedPriorities, v)
        end
        editedPriorities = mergedPriorities
    else return end

    --work out what message to send to the player for changing their priority list
    if default then
        name = "Default"
    elseif type(data.name) == "string" then
        if string.len(data.name) > 6 then
            name = string.sub(data.name, 1, 6)
        else
            name = data.name
        end    
    end 

    if GetEntityById(selectedUnits[1]):GetArmy() == GetFocusArmy() then
        --send the message to the owner of the army
        print('Target Priority:', name)
    end
    
    local units = {}

    -- prevent tampering
    for _, unitId in selectedUnits do
        local unit = GetEntityById(unitId)
        
        if unit and OkayToMessWithArmy(unit:GetArmy()) then 
            table.insert(units, unit)
        end
    end   

    --for performance reasons we keep track of any priorities we have already set, and just use the table instead of working out what they should be for each unit
    local cachedPriorityTables = {}
    
    for _, unit in units do
        local blueprintId = unit:GetBlueprint().BlueprintId
        if not cachedPriorityTables[blueprintId] then 
            cachedPriorityTables[blueprintId] = {} 
        end
        local weaponCount = unit:GetWeaponCount()
        --saves the priorities for next button press
        if weaponCount > 0 and unit.Sync.WepPriority ~= name then
            unit.Sync.WepPriority = name or "?????" 
            
            for i = 1, weaponCount do
                if not cachedPriorityTables[blueprintId][i] then
                    if data.exclusive and (not default) then
                        cachedPriorityTables[blueprintId][i] = editedPriorities
                    else
                        local defaultPriorities = parsedPriorities[blueprintId][i]
                        if default then
                            cachedPriorityTables[blueprintId][i] = defaultPriorities
                        else
                            local mergedPriorities = prioritiesTable or {}
                            for k,v in pairs(defaultPriorities) do
                                table.insert(mergedPriorities, v)
                            end
                            cachedPriorityTables[blueprintId][i] = mergedPriorities
                        end
                    end
                end
                local weapon = unit:GetWeapon(i)
                weapon:SetTargetingPriorities(cachedPriorityTables[blueprintId][i])
                weapon:ResetTarget()
            end
        end
    end
end

-- Parse and caching all TargetPriorities tables for every unit
function parseDefaultPriorities()
    local idlist = EntityCategoryGetUnitList(categories.ALLUNITS)
    local finalPriorities = {}

    local parsedTemp = {}


    for _, id in idlist do
        
        local weapons = GetUnitBlueprintByName(id).Weapon
        
        if weapons[1] then
            local priorities = {}
            
            for weaponNum, weapon in weapons do
                if weapon.TargetPriorities then
                    priorities[weaponNum] = weapon.TargetPriorities
                else
                    priorities[weaponNum] = {}
                end
                
            end
            
            for weaponNum, tbl in priorities do
                if not finalPriorities[id] then finalPriorities[id] = {} end 
                if not finalPriorities[id][weaponNum] then finalPriorities[id][weaponNum] = {} end
                
                if tbl[1] then
                    local prioTbl = tbl
                    
                    for line, categories in prioTbl do
                        if parsedTemp[categories] then
                            
                            finalPriorities[id][weaponNum][line] = parsedTemp[categories]
                            
                        elseif string.find(categories, '%(') then
                            local parsed = ParseEntityCategoryProperly(categories)
                            
                            finalPriorities[id][weaponNum][line] = parsed
                            parsedTemp[categories] = parsed
                            
                        else
                            local parsed = ParseEntityCategory(categories)
                            
                            finalPriorities[id][weaponNum][line] = parsed
                            parsedTemp[categories] = parsed
                        end    
                    end
                end    
            end
        end
    end
    return finalPriorities
end