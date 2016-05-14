#****************************************************************************
#**
#**  File     :  /cdimage/units/URL0306/URL0306_script.lua
#**  Author(s):  Jessica St. Croix
#**
#**  Summary  :  Cybran Mobile Radar Jammer Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CLandUnit = import('/lua/cybranunits.lua').CLandUnit
local EffectUtil = import('/lua/EffectUtilities.lua')

URL0306 = Class(CLandUnit) {
    OnStopBeingBuilt = function(self,builder,layer)
        CLandUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,
    
    IntelEffects = {
		{
			Bones = {
				'AttachPoint',
			},
			Offset = {
				0,
				0.3,
				0,
			},
			Scale = 0.2,
			Type = 'Jammer01',
		},
    },
    
    OnIntelEnabled = function(self)
        CLandUnit.OnIntelEnabled(self)
        if self.IntelEffects then
			self.IntelEffectsBag = {}
			self.CreateTerrainTypeEffects( self, self.IntelEffects, 'FXIdle',  self:GetCurrentLayer(), nil, self.IntelEffectsBag )
		end
    end,

    OnIntelDisabled = function(self)
        CLandUnit.OnIntelDisabled(self)
        EffectUtil.CleanupEffectBag(self,'IntelEffectsBag')
    end,    
    
    RetardedTurnOffStealth = function(self)
        WARN('turning off stealth')
        self:DisableIntel('RadarStealthField') -- for some absurd reason toggling scriptbit for stealth doesnt work here, but does work OnStopBeingBuilt. crazy. so i just did it manually.
        self:DisableIntel('RadarStealth') -- the added benefit of not showing the disabled strategic icon as well. so thats cool i guess.
        self:SetMaintenanceConsumptionInactive()
        EffectUtil.CleanupEffectBag(self,'IntelEffectsBag')
    end,
    
    RetardedTurnOnStealth = function(self)
        WARN('turning on stealth')
        self:EnableIntel('RadarStealthField')
        self:EnableIntel('RadarStealth') 
        self:SetMaintenanceConsumptionActive()
        if self.IntelEffects then
			self.IntelEffectsBag = {}
            WARN('creating stealth effects')
			self.CreateTerrainTypeEffects( self, self.IntelEffects, 'FXIdle',  self:GetCurrentLayer(), nil, self.IntelEffectsBag )
		end
        -- because fuck you thats why
        self:SetScriptBit('RULEUTC_StealthToggle', false)
    end,
    
    
    OnAttachedToTransport = function(self, transport, bone)
        self:MarkWeaponsOnTransport(true)
        WARN('attatching')
        self:RetardedTurnOffStealth() -- stealth off
        if self:ShieldIsOn() then
            self:DisableShield()
            self:DisableDefaultToggleCaps()
        end
        self:DoUnitCallbacks( 'OnAttachedToTransport', transport, bone)
    end,

    OnDetachedFromTransport = function(self, transport, bone)
        self:MarkWeaponsOnTransport(false)
        WARN('detatching')
        self:RetardedTurnOnStealth() -- stealth on
        self:EnableShield()
        self:EnableDefaultToggleCaps()
        self:TransportAnimation(-1)
        self:DoUnitCallbacks( 'OnDetachedFromTransport', transport, bone)
    end,
}

TypeClass = URL0306