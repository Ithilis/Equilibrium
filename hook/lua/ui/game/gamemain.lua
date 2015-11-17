local modpath = "/mods/equilibrium_balance_mod"

local originalCreateUI = CreateUI
function CreateUI(isReplay) 
    originalCreateUI(isReplay)
    import('/mods/equilibrium_balance_mod/modules/helpUi.lua').init()
end