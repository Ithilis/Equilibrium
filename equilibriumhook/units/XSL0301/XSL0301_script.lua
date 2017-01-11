-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/XSL0301/XSL0301_script.lua
-- **  Author(s):  Jessica St. Croix, Gordon Duclos
-- **
-- **  Summary  :  Seraphim Sub Commander Script
-- **
-- **  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local CommandUnit = import('/lua/defaultunits.lua').CommandUnit
local AWeapons = import('/lua/aeonweapons.lua')
local SWeapons = import('/lua/seraphimweapons.lua')
local Buff = import('/lua/sim/Buff.lua')

local SDFLightChronotronCannonWeapon = SWeapons.SDFLightChronotronCannonWeapon
local SDFOverChargeWeapon = SWeapons.SDFLightChronotronCannonOverchargeWeapon
local SIFLaanseTacticalMissileLauncher = SWeapons.SIFLaanseTacticalMissileLauncher
local SCUDeathWeapon = import('/lua/sim/defaultweapons.lua').SCUDeathWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')

OldXSL0301 = XSL0301

XSL0301 = Class(OldXSL0301) {
    
    CreateEnhancement = function(self, enh)
        OldXSL0301.CreateEnhancement(self, enh)
        self:AdjustPriceOnEnh() --EQ: we adjust our sacus price when we get or lose an enhancement
    end,

    AdjustPriceOnEnh = function(self)
        -- change cost of the new unit to match unit base cost + enhancement costs.
        
        local bp = self:GetBlueprint()
        
        -- In the case of presets, use the base bp for prices. and stuff.
        if bp.EnhancementPresetAssigned.BaseBlueprintId then
            bp = GetUnitBlueprintByName(bp.EnhancementPresetAssigned.BaseBlueprintId)
        end
        
        local e, m, t = 0, 0, 0
        
        local enhCommon = import('/lua/enhancementcommon.lua') --get our unit enhs
        local unitEnhancements = enhCommon.GetEnhancements(self:GetEntityId())
        
        if unitEnhancements then --If we have no enh this is a nil value, so we bail
            for k, enh in unitEnhancements do
                -- replaced continue by reversing if statement
                if bp.Enhancements[enh] then
                    e = e + (bp.Enhancements[enh].BuildCostEnergy or 0)
                    m = m + (bp.Enhancements[enh].BuildCostMass or 0)
                    t = t + (bp.Enhancements[enh].BuildTime or 0)
                    -- HUSSAR added name of the enhancement so that preset units cannot be built
                end
            end
        end
        
        --add our enh costs onto our base costs.
        self.BuildCostM = bp.Economy.BuildCostMass + m
        self.BuildCostE = bp.Economy.BuildCostEnergy + e
        self.BuildT = bp.Economy.BuildTime + t
        
        --WARN('enhancement mass/energy/time: ' .. m .. ', ' .. e .. ', ' .. t)
        --WARN('total mass/energy/time: ' .. self.BuildCostM .. ', ' .. self.BuildCostE .. ', ' .. self.BuildT)
    end,
}

TypeClass = XSL0301
