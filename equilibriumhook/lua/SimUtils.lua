-- what is doing this is, when you lose storage you lose also portion of mass inside
-- its from there https://github.com/FAForever/fa/pull/581/files

function TransferUnitsOwnership(units, ToArmyIndex)
    local toBrain = GetArmyBrain(ToArmyIndex)
    if not toBrain or toBrain:IsDefeated() or not units or table.getn(units) < 1 then
        return
    end

    table.sort(units, function (a, b) return a:GetBlueprint().Economy.BuildCostMass > b:GetBlueprint().Economy.BuildCostMass end)

    local newUnits = {}
    for k, v in units do
        local owner = v:GetArmy()
        -- Only allow units not attached to be given. This is because units will give all of it's children over
        -- aswell, so we only want the top level units to be given.
        -- Units currently being captured is also denied
        local disallowTransfer = owner == ToArmyIndex or
                                 v:GetParent() ~= v or (v.Parent and v.Parent ~= v) or
                                 v.CaptureProgress > 0

        if disallowTransfer then
            continue
        end

        local unit = v
        local bp = unit:GetBlueprint()
        local unitId = unit:GetUnitId()

        -- B E F O R E
        local numNukes = unit:GetNukeSiloAmmoCount()  -- looks like one of these 2 works for SMDs also
        local numTacMsl = unit:GetTacticalSiloAmmoCount()
        local xp = unit.xp
        local massKilled = unit.Sync.totalMassKilled
        local unitHealth = unit:GetHealth()
        local shieldIsOn = false
        local ShieldHealth = 0
        local hasFuel = false
        local fuelRatio = 0
        local enh = {} -- enhancements
        local oldowner = unit.oldowner

        if unit.MyShield then
            shieldIsOn = unit:ShieldIsOn()
            ShieldHealth = unit.MyShield:GetHealth()
        end
        if bp.Physics.FuelUseTime and bp.Physics.FuelUseTime > 0 then   -- going through the BP to check for fuel
            fuelRatio = unit:GetFuelRatio()                             -- usage is more reliable then unit.HasFuel
            hasFuel = true                                              -- cause some buildings say they use fuel
        end
        local posblEnh = bp.Enhancements
        if posblEnh then
            for k,v in posblEnh do
                if unit:HasEnhancement( k ) then
                   table.insert( enh, k )
                end
            end
        end

        -- changing owner
        --unit:RefreshIntel() -- this caused an error since this function doesnt exist (or sth) so commented it out.
        unit = ChangeUnitArmy(unit,ToArmyIndex)
        if not unit then
            continue
        end

        table.insert(newUnits, unit)

        unit.oldowner = oldowner
        unit.IsBeingTransferred = true

        if IsAlly(owner, ToArmyIndex) then
            if not unit.oldowner then
                unit.oldowner = owner
            end

            if not sharedUnits[unit.oldowner] then
                sharedUnits[unit.oldowner] = {}
            end
            table.insert(sharedUnits[unit.oldowner], unit)
        end

        -- A F T E R
        if xp and xp > 0 then
            unit:AddXP(xp)
        end
        if massKilled and massKilled > 0 then
            unit:CalculateVeterancyLevel(massKilled)
        end
        if enh and table.getn(enh) > 0 then
            for k, v in enh do
                unit:CreateEnhancement( v )
            end
        end
        if unitHealth > unit:GetMaxHealth() then
            unitHealth = unit:GetMaxHealth()
        end
        unit:SetHealth(unit,unitHealth)
        if hasFuel then
            unit:SetFuelRatio(fuelRatio)
        end
        if numNukes and numNukes > 0 then
            unit:GiveNukeSiloAmmo( (numNukes - unit:GetNukeSiloAmmoCount()) )
        end
        if numTacMsl and numTacMsl > 0 then
            unit:GiveTacticalSiloAmmo( (numTacMsl - unit:GetTacticalSiloAmmoCount()) )
        end
        if unit.MyShield then
            unit.MyShield:SetHealth( unit, ShieldHealth )
            if shieldIsOn then
                unit:EnableShield()
            else
                unit:DisableShield()
            end
        end
        if EntityCategoryContains(categories.ENGINEERSTATION, unit) then
            unit:SetPaused(true)
        end
        v:HandleStorage(ToArmyIndex)
        unit.IsBeingTransferred = false
    end
    return newUnits
end
