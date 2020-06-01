--*****************************************************************************
--* Summary: Lobby and In game quick help for Equilibrium mod. Edited version of PhantomX lobby code, originally by Duck_42
--*
--*
--*
--* Authors: Duck_42 (2014), [e]Exotic_Retard (2018)
--*****************************************************************************
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local Tooltip = import('/lua/ui/game/tooltip.lua')


local settings = {
    -- helpPanel settings
    panel_height = 270,
    panel_width = 632,

    -- text in helpPanel, doesn't wrap :/
    headLine = "Survival manual",
    textLines = {
        "- This mod aims to improve balance while keeping the same feel of the game. Just play normally.",
        "- However here are some things which you might want to take into account while playing:",
        "",
        "1. Veterancy doesn't instant-heal units anymore, but get more max hp. Units share experience from kills.",
        "2. Repairing units cost only half of the resources.",
        "3. Mass storages provide less adjacency and any mass stored in them is lost when they are destroyed.",
        "4. Submarine combat: Subs counter suface ships; Sub Hunters counter subs; Destroyers counter sub hunters.",       
        "5. Mercies deal damage over time! Moving targets receive only a fraction of the damage.",
        "6. Units in transport are not visible on the radar anymore, be ready to be ambushed!",
        "",
        "",
        "However, there is more to this mod than meets the eye, and you might notice lots of small changes,",
        "bug fixes, improvements and more.",
        "If you are interested, you can view the whole changelog online, and feel free to leave feedback in the forum.",
        "",
        "Just remember, that most players don't notice many differences at all, so once again, just play normally!",
    }
}

function ShowEQHelpDialog(inParent)
	local dialogContent = Group(inParent)
    dialogContent.Width:Set(700)
    dialogContent.Height:Set(400)
	
	local popup = Popup(inParent, dialogContent)
	
    --create buttons
	local exitButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Close>")
	LayoutHelpers.AtBottomIn(exitButton, dialogContent, 25)
    LayoutHelpers.AtHorizontalCenterIn(exitButton, dialogContent)
    
	local changelogButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Changelog")
	LayoutHelpers.AtBottomIn(changelogButton, dialogContent, 10.5)
	LayoutHelpers.AtLeftIn(changelogButton, dialogContent, 100)
	
	
    --create the title
	local title = UIUtil.CreateText(dialogContent, settings.headLine, 20)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)
    LayoutHelpers.AtTopIn(title, dialogContent, 12)
	
    LayoutHelpers.AtBottomIn(exitButton, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(exitButton, dialogContent)
	
    --create the text body
	local helpBody = ItemList(dialogContent)
    LayoutHelpers.AtLeftTopIn(helpBody, dialogContent, 19, 50)
    helpBody.Height:Set(settings.panel_height)
    helpBody.Width:Set(settings.panel_width)
	helpBody:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor, "00000000")
    helpBody:SetFont(UIUtil.bodyFont, 12)
    UIUtil.CreateLobbyVertScrollbar(helpBody, -15, 0, 0)
	UIUtil.SurroundWithBorder(helpBody, '/scx_menu/lan-game-lobby/frame/')
    
    local textBoxWidth = helpBody.Width() - 25
    
    
    for i, v in settings.textLines do
        helpBody:AddItem(v)
    end
    
	local function doCancel()
        popup:Close()
    end
    
    --add behaviours
    popup.OnShadowClicked = doCancel
    popup.OnEscapePressed = doCancel
    exitButton.OnClick = doCancel
    
    Tooltip.AddButtonTooltip(changelogButton, "Open_EQ_Changelog")
    changelogButton.OnClick = function(self, modifiers)
        OpenURL('http://faforever.github.io/equilibrium/Changelog/')
    end
end