--Deciever - mobile stealth generator

local oldURL0306 = URL0306
URL0306 = Class(oldURL0306) {
        
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