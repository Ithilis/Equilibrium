local MyUnitIdTable = {
    'erb4206',
}
local oldFileNameFn = GetUnitIconFileNames
 
local function IsMyUnit(blueprint)
    for i, v in MyUnitIdTable do
        if v == blueprint.Display.IconName then
            return true
        end
    end
    return false
end
  
function GetUnitIconFileNames(blueprint)
    if IsMyUnit(blueprint) then
        local iconName = "/mods/Equilibrium_balance_mod/icons/units/" .. blueprint.Display.IconName .. "_icon.dds"
        local upIconName = "/mods/Equilibrium_balance_mod/icons/units/" .. blueprint.Display.IconName .. "_build_btn_up.dds"
        local downIconName = "/mods/Equilibrium_balance_mod/icons/units/" .. blueprint.Display.IconName .. "_build_btn_down.dds"
        local overIconName = "/mods/Equilibrium_balance_mod/icons/units/" .. blueprint.Display.IconName .. "_build_btn_over.dds"

        if DiskGetFileInfo(iconName) == false then
            WARN('Blueprint icon for unit '.. blueprint.Display.IconName ..' could not be found, check your file path and icon names!')
            iconName = '/textures/ui/common/icons/units/default_icon.dds'
        end

        if DiskGetFileInfo(upIconName) == false then
            upIconName = iconName
        end

        if DiskGetFileInfo(downIconName) == false then
            downIconName = iconName
        end

        if DiskGetFileInfo(overIconName) == false then
            overIconName = iconName
        end

        return iconName, upIconName, downIconName, overIconName
    else
        return oldFileNameFn(blueprint)
    end
end