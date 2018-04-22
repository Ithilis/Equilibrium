------------------------------------------------------------------
--  File     :  /lua/shield.lua
--  Author(s):  John Comes, Gordon Duclos
--  Summary  : Shield lua module
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local Entity = import('/lua/sim/Entity.lua').Entity
local Overspill = import('/lua/overspill.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local Util = import('utilities.lua')

-- Default values for a shield specification table (to be passed to native code)
local DEFAULT_OPTIONS = {
    Mesh = '',
    MeshZ = '',
    ImpactMesh = '',
    ImpactEffects = '',
    Size = 10,
    ShieldMaxHealth = 250,
    ShieldRechargeTime = 10,
    ShieldEnergyDrainRechargeTime = 10,
    ShieldVerticalOffset = -1,
    ShieldRegenRate = 1,
    ShieldRegenStartTime = 5,
    PassOverkillDamage = false,
}

local oldShield = Shield

Shield = Class(oldShield) {
    ApplyDamage = function(self, instigator, amount, vector, dmgType, doOverspill)
    --EQ:remove OC changes, the static shield thing didnt make any sense, they just fucked up armour types? whatever, works in EQ.
        if self.Owner ~= instigator then
            local absorbed = self:OnGetDamageAbsorption(instigator, amount, dmgType)

            self:AdjustHealth(instigator, -absorbed)
            self:UpdateShieldRatio(-1)
            ForkThread(self.CreateImpactEffect, self, vector)
            if self.RegenThread then
                KillThread(self.RegenThread)
                self.RegenThread = nil
            end
            if self:GetHealth() <= 0 then
                ChangeState(self, self.DamageRechargeState)
            elseif self.OffHealth < 0 then
                if self.RegenRate > 0 then
                    self.RegenThread = ForkThread(self.RegenStartThread, self)
                    self.Owner.Trash:Add(self.RegenThread)
                end
            else
                self:UpdateShieldRatio(0)
            end
        end
        -- Only do overspill on events where we have an instigator.
        -- "Force" damage events from stratbombs are one example
        -- where we don't.
        if doOverspill and IsEntity(instigator) then
            Overspill.DoOverspill(self, instigator, amount, dmgType, self.SpillOverDmgMod)
        end
    end,
}

