

--Help UI Changes
local oldCreateUI = CreateUI

function CreateUI(maxPlayers)
	oldCreateUI(maxPlayers)
	AddEQChanges()
end

function AddEQChanges()
	--This function handles creation of Phantom-X lobby UI elements (buttons, tooltips, etc)
	
    GUI.showEQHelp = UIUtil.CreateButtonWithDropshadow(GUI.panel, '/BUTTON/medium/', 'Mod Info')
	LayoutHelpers.AtLeftIn(GUI.showEQHelp, GUI.chatPanel, 190)
    LayoutHelpers.AtVerticalCenterIn(GUI.showEQHelp, GUI.launchGameButton, -6)
	
	GUI.showEQHelp.OnClick = function(self, modifiers)
		import('/modules/helpUiLobby.lua').ShowEQHelpDialog(GUI.panel)
	end
end