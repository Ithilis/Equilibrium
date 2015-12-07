local modpath = '/mods/equilibrium_balance_mod/'

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Button = import('/lua/maui/button.lua').Button
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap


local elements = {
    mainFrame = nil,
    helpPanel = nil,
}

local settings = {
    -- helpbutton settings
    posX = 210,
    posY = 80,
    height = 65,
    width = 65,

    -- helpPanel settings
    panel_posX = 2,
    panel_posY = 150,
    panel_height = 270,
    panel_width = 610,

    -- text in helpPanel
    headLine = "Survival manual",
    textLines = {
        "- This mod aims to improve balance while keeping the same feel of the game. Just play normally.",
        "- However here are some things which you might want to take into account while playing:",
        "",
        "1. Mercies deal damage over time! Moving targets receive only a fraction of the damage.",
        "2. Mass storages are cheaper, provide less mass, and explode on death! Consider safety and use adjacency.",
        "3. RAS energy income has been nerfed, don't reclaim your pgens afterwards!",        
        "4. T4 units take much longer to build. Get t2/3 engineers, they are more efficient in this mod.",
        "5. Veterancy doesn't instant-heal units anymore. Units share experience from kill.",
    }
}

--GetFrame(0).Width()/2

function init()
    ForkThread(function()
        WaitSeconds(1)

        local clickFunction = function()
            createHelpPanel(GetFrame(0), settings.panel_posX, settings.panel_posY, settings.panel_height, settings.panel_width, settings.headLine, settings.textLines)
        end
        createUi(GetFrame(0), settings.posX, settings.posY, settings.height, settings.width, clickFunction)

        WaitSeconds(180)
        elements.mainFrame:Hide()

        WaitSeconds(5)
        if elements.helpPanel then
            elements.helpPanel:Hide()
        end

        WaitSeconds(10)
        elements.mainFrame:Destroy()
        if elements.helpPanel then
            elements.helpPanel:Destroy()
        end
    end)

end


function createUi(parent, posX, posY, height, width, clickFunction)    
    elements.mainFrame = Bitmap(parent)
    elements.mainFrame.Depth:Set(99)
    LayoutHelpers.AtLeftTopIn(elements.mainFrame, parent, posX, posY)
    elements.mainFrame.Height:Set(height)
    elements.mainFrame.Width:Set(width)
    elements.mainFrame:SetTexture(modpath..'/textures/transparent.png')
    elements.mainFrame:Show()

    local helpButton = Button(elements.mainFrame, modpath..'textures/helpButton_up.png', modpath..'textures/helpButton_down.png', modpath..'textures/helpButton_over.png', modpath..'textures/helpButton_up.png')
    helpButton.Height:Set(height)
    helpButton.Width:Set(width)
    LayoutHelpers.AtLeftTopIn(helpButton, parent, posX, posY)

    helpButton:EnableHitTest(true)
    helpButton.OnClick = function(self, event)
         clickFunction()
    end
end


function createHelpPanel(parent, posX, posY, height, width, headline, textlines)
    if elements.helpPanel then
        elements.helpPanel:Destroy()
        elements.helpPanel = nil
        return
    end

    elements.helpPanel = Bitmap(parent)
    elements.helpPanel.Depth:Set(10000)
    LayoutHelpers.AtLeftTopIn(elements.helpPanel, parent, posX, posY)
    elements.helpPanel.Height:Set(height)
    elements.helpPanel.Width:Set(width)
    elements.helpPanel:SetTexture(modpath..'textures/panel_background.png')
    elements.helpPanel:Show()

    --close button
    local closeButton = Button(elements.helpPanel, modpath..'textures/closeButton_up.png', modpath..'textures/closeButton_up.png', modpath..'textures/closeButton_over.png', modpath..'textures/closeButton_up.png')
    closeButton.Height:Set(30)
    closeButton.Width:Set(30)
    LayoutHelpers.AtLeftTopIn(closeButton, elements.helpPanel, width-35, 5)

    closeButton:EnableHitTest(true)
    closeButton.OnClick = function(self, event)
         elements.helpPanel:Destroy()
         elements.helpPanel = nil
    end

    --text!
    LayoutHelpers.CenteredAbove(UIUtil.CreateText(elements.helpPanel, headline, 28, UIUtil.bodyFont), elements.helpPanel, -40)

    local curY = 50
    for _, line in textlines do
        LayoutHelpers.AtLeftTopIn(UIUtil.CreateText(elements.helpPanel, line, 12, UIUtil.bodyFont), elements.helpPanel, 10, curY)
        curY = curY + 22
    end
end