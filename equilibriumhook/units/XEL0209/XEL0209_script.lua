--Sparky - T2 field engineer

local oldXEL0209 = XEL0209
XEL0209 = Class(oldXEL0209) {

    RetardedTurnOffJamming = function(self)
        self:DisableIntel('Jammer') -- for some absurd reason toggling scriptbit for stealth doesnt work here, but does work OnStopBeingBuilt. crazy. so i just did it manually.
        -- the added benefit of not showing the disabled strategic icon as well. so thats cool i guess.
        self:SetMaintenanceConsumptionInactive()
        EffectUtil.CleanupEffectBag(self,'IntelEffectsBag')
    end,
    
    RetardedTurnOnJamming = function(self) 
        -- because fuck you thats why
        self:EnableIntel('Jammer')
        self:SetMaintenanceConsumptionActive()
        
        if self.IntelEffects then
			self.IntelEffectsBag = {}
			self.CreateTerrainTypeEffects( self, self.IntelEffects, 'FXIdle',  self:GetCurrentLayer(), nil, self.IntelEffectsBag )
		end
        
        --self:SetScriptBit('RULEUTC_StealthToggle', false)
    end,

    OnAttachedToTransport = function(self, transport, bone)
        self:RetardedTurnOffJamming()
        oldXEL0209.OnAttachedToTransport(self, transport, bone)
    end,

    OnDetachedFromTransport = function(self, transport, bone)
        self:RetardedTurnOnJamming()
        oldXEL0209.OnDetachedFromTransport(self, transport, bone)
    end,
}

TypeClass = XEL0209
