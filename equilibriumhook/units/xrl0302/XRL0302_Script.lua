----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CMobileKamikazeBombWeapon = import('/lua/cybranweapons.lua').CMobileKamikazeBombWeapon

XRL0302 = Class(CWalkingLandUnit) {

    Weapons = {
        Suicide = Class(CMobileKamikazeBombWeapon) {
            --EQ: the kamikaze weapon is kinda dumb since it doesnt accept damagemods and the like. so we have to rewrite it a little.
            OnFire = function(self)
                --add the effects
                local army = self.unit:GetArmy()
                for k, v in self.FxDeath do
                    CreateEmitterAtBone(self.unit,-2,army,v)
                end
                --do the damage
                local bp = self:GetBlueprint()
                local damage = bp.Damage + (self.DamageMod or 0)
                DamageArea(self.unit, self.unit:GetPosition(), bp.DamageRadius, damage, bp.DamageType or 'Normal', bp.DamageFriendly or false)
                self.unit:PlayUnitSound('Destroyed')
                --self.unit:ApplyStun() --EQ:add stun (left for later incase we decide this is a good idea) yes balance team i know youre reading this. i left it for you.
                self.unit:Destroy()
            end,
            
            OnGotTarget = function(self)
                CMobileKamikazeBombWeapon.OnGotTarget(self)
                self:ForkThread(self.TargetThread)
            end,
            
            --EQ:once we are in range of something tasty we need to look out for better targets, since the weapon doesnt do that by itself before firing
            TargetThread = function(self)
                while self.NumTargets > 0 do
                    WaitSeconds(0.3)
                    if not self.Dead then
                        self:ResetTarget()
                    end
                end
            end,
        },
    },
    
    --Turn the cloak off by default
    OnStopBeingBuilt = function(self,builder,layer)
        CWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionInactive()
        self:SetScriptBit('RULEUTC_CloakToggle', true)
        self:RequestRefreshUI()
    end,
    
    -- Allow the trigger button to blow the weapon, resulting in OnKilled instigator 'nil'
    OnProductionPaused = function(self)
        self:GetWeaponByLabel('Suicide'):FireWeapon()
    end,
    
    --EQ:we reduce the damage of the explosion if it was killed without being triggered by anything (is this needed?)
    OnKilled = function(self, instigator, type, overkillRatio)
        if self:GetCurrentLayer() == 'Land' then --avoid them exploding in transports
            local bp = self:GetBlueprint().Weapon[1] --EQ:this will break if a weapon is added before this one.
            local wep = self:GetWeaponByLabel('Suicide')
            wep:AddDamageMod(bp.DamageMod)
            self:GetWeaponByLabel('Suicide'):FireWeapon()
        end
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
    
    --EQ:we apply the stun manually since the weapon didnt have it defined. well whatever.
    ApplyStun = function(self)
        if self:IsBeingBuilt() then return end --dont want to explode when not finished

        -- Find OnDeath Buffs
        local bp
        for k, v in self:GetBlueprint().Buffs do
            if v.Add.OnDeath then
                bp = v
            end
        end

        -- Apply buffs
        if bp ~= nil then
            self:AddBuff(bp)
        end
    end,
}

TypeClass = XRL0302
