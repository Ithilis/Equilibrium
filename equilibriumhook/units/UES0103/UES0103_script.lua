--****************************************************************************
--**
--**  File     :  /cdimage/units/UES0103/UES0103_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Frigate Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SmartJamming = import('/lua/SmartJamming.lua').SmartJamming --import our jamming code

local oldUES0103 = UES0103
oldUES0103 = SmartJamming( oldUES0103 )--inject our jamming code here, so it refreshes properly

UES0103 = Class(oldUES0103) {
}

TypeClass = UES0103