--****************************************************************************
--**
--**  File     :  /data/projectiles/SDFChronatronCannon02/SDFChronatronCannon02_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  ChronatronCannon Projectile script, Seraphim commander overcharge, XSL0001
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SmartOverCharge = import('/lua/SmartOverCharge.lua').SmartOverCharge --import our OC code

local oldSDFChronatronCannon02 = SDFChronatronCannon02
oldSDFChronatronCannon02 = SmartOverCharge( oldSDFChronatronCannon02 )--inject our OC code here, so it damages dynamically

SDFChronatronCannon02 = Class(oldSDFChronatronCannon02) {
}
TypeClass = SDFChronatronCannon02