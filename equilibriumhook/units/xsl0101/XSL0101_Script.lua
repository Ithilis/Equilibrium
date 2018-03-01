-----------------------------------------------------------------
-- File     :  /cdimage/units/XSL0101/XSL0101_script.lua
-- Summary  :  Seraphim Land Scout Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SWalkingLandUnit = import('/lua/seraphimunits.lua').SWalkingLandUnit
local SDFPhasicAutoGunWeapon = import('/lua/seraphimweapons.lua').SDFPhasicAutoGunWeapon

XSL0101 = Class(SWalkingLandUnit) {
    Weapons = {
		LaserTurret = Class(SDFPhasicAutoGunWeapon) {
            OnWeaponFired = function(self) --if we fire our weapon, we must reveal ourselves.
                self.unit:RevealUnit()
                --we begin the hide sequence, which is cleared if we fire again.
                self.unit.CloakThread = self.unit:ForkThread(self.unit.CloakingThread)
                
                SDFPhasicAutoGunWeapon.OnWeaponFired(self)
            end,
        },
    },

    -- Toggle disabled
    OnScriptBitSet = function(self, bit)
        if bit == 8 then
            self.Sync.LowPriority = false
            self:SetWeaponEnabledByLabel('LaserTurret', true)
        else
            SWalkingLandUnit.OnScriptBitSet(self, bit)
        end
    end,

    -- Toggle enabled
    OnScriptBitClear = function(self, bit)
        if bit == 8 then
            self.Sync.LowPriority = true
            if not self:IsMoving() then --for the case when we toggle stationary
                self:SetWeaponEnabledByLabel('LaserTurret', false)
            end
        else
            SWalkingLandUnit.OnScriptBitClear(self, bit)
        end
    end,

    RevealUnit = function(self)
        if self.CloakThread then
            KillThread(self.CloakThread)
            self.CloakThread = nil
        end

        self:SetWeaponEnabledByLabel('LaserTurret', true)
        self:DisableUnitIntel('ToggleBit5', 'RadarStealth')
        self:DisableUnitIntel('ToggleBit8', 'Cloak')
    end,
    
    HideUnit = function(self) --this is its own function so we can call it without any delay if we want.
        if not self.Dead and not self:IsMoving() then --never cloak while dead or moving
            self:EnableUnitIntel('ToggleBit5', 'RadarStealth')
            self:EnableUnitIntel('ToggleBit8', 'Cloak')
            self.CloakThread = nil
            --if your toggle is on then we activate low priority mode and deselect and hold fire selen as well.
            if self.Sync.LowPriority then
                self:SetWeaponEnabledByLabel('LaserTurret', false)
            end
        end
    end,

    -- Turn off the cloak to begin with
    OnStopBeingBuilt = function(self, builder, layer)
        SWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetScriptBit('RULEUTC_CloakToggle', true)
        self:HideUnit() --if we are spawned in we want to hide our unit.
    end,

    OnMotionHorzEventChange = function(self, new, old)
        -- If we stopped moving, hide
        if new == 'Stopped' then
            -- We need to fork in order to use WaitSeconds
            if self.CloakThread then
                KillThread(self.CloakThread)
                self.CloakThread = nil
            end
            self.CloakThread = self:ForkThread(self.CloakingThread)
        end
        -- If we begin moving, reveal ourselves
        if old == 'Stopped' then
            self:RevealUnit()
        end
        SWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
    end,
    
    CloakingThread = function(self)
        WaitSeconds(self:GetBlueprint().Intel.StealthWaitTime)
        --we wait for specified seconds then hide our unit
        self:HideUnit()
    end,
    
}

TypeClass = XSL0101
