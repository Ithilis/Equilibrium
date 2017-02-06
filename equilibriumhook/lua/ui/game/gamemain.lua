local oldCreateUI = CreateUI
function CreateUI(isReplay) 
    oldCreateUI(isReplay)
    import('/modules/helpUi.lua').init()
end