#****************************************************************************
#**
#**  File     :  /lua/aeonunits.lua
#**  Author(s): John Comes, Gordon Duclos
#**
#**  Summary  :
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
#--------------------------------------------------------------------------
# AEON DEFAULT UNITS
#--------------------------------------------------------------------------
local DefaultUnitsFile = import('defaultunits.lua')
local RadarJammerUnit = DefaultUnitsFile.RadarJammerUnit

local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local CreateAeonFactoryBuildingEffects = EffectUtil.CreateAeonFactoryBuildingEffects

#-------------------------------------------------------------
#  RADAR JAMMER UNITS
#-------------------------------------------------------------
ARadarJammerUnit = Class(RadarJammerUnit) {

}