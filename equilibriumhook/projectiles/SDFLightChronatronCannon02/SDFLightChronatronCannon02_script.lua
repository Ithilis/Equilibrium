--****************************************************************************
--**
--**  File     :  /data/projectiles/SDFLightChronatronCannon02/SDFLightChronatronCannon02_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Light Chronatron Cannon Projectile script, Seraphim sub-commander overcharge, XSL0301
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SLightChronatronCannonOverCharge = import('/lua/seraphimprojectiles.lua').SLightChronatronCannonOverCharge
local OverchargeProjectile = import('/lua/sim/DefaultProjectiles.lua').OverchargeProjectile

local oldSDFLightChronatronCannon02 = SDFLightChronatronCannon02 --use later

SDFLightChronatronCannon02 = Class(SLightChronatronCannonOverCharge, OverchargeProjectile) {
    SmartOverChargeScale = 1000, --the upgrade costs a lot so we make it drain less since you can also build multiple of these.
    MaxOverChargeCharges = 6, -- so you cant oc exps in absurd fashion
    --remove when beta patch is released
    OnImpact = function(self, targetType, targetEntity)
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        SLightChronatronCannonOverCharge.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = SDFLightChronatronCannon02