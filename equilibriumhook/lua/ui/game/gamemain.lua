local modpath = "/"

local originalCreateUI = CreateUI
function CreateUI(isReplay) 
    originalCreateUI(isReplay)
    import('/modules/helpUi.lua').init()
end