--****************************************************************************
--**
--**  File     :  /data/projectiles/SDFLightChronatronCannon02/SDFLightChronatronCannon02_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Light Chronatron Cannon Projectile script, Seraphim sub-commander overcharge, XSL0301
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local oldSDFLightChronatronCannon02 = SDFLightChronatronCannon02

SDFLightChronatronCannon02 = Class(oldSDFLightChronatronCannon02) {
    SmartOverChargeScale = 1000, --the upgrade costs a lot so we make it drain less since you can also build multiple of these.
    MaxOverChargeCharges = 6, -- so you cant oc exps in absurd fashion
}
TypeClass = SDFLightChronatronCannon02