-----------------------------------------------------------------
-- File     :  /cdimage/units/XSB2401/XSB2401_script.lua
-- Author(s):  John Comes, David Tomandl, Matt Vainio
-- Summary  :  Seraphim Tactical Missile Launcher Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit
local SIFExperimentalStrategicMissile = import('/lua/seraphimweapons.lua').SIFExperimentalStrategicMissile
local EffectTemplate = import('/lua/EffectTemplates.lua')

XSB2401 = Class(SStructureUnit) {
    Weapons = {
        ExperimentalNuke = Class(SIFExperimentalStrategicMissile) {
            OnWeaponFired = function(self)
                self.unit:ForkThread(self.unit.HideMissile)
            end,

            PlayFxWeaponUnpackSequence = function(self)
                self.unit:ForkThread(self.unit.ChargeNukeSound)
                SIFExperimentalStrategicMissile.PlayFxWeaponUnpackSequence(self)
            end,
        },
    },

    OnStopBeingBuilt = function(self, builder, layer)
        SStructureUnit.OnStopBeingBuilt(self, builder, layer)

        local bp = self:GetBlueprint()
        --set up missile effects
        self.MissileEffectsBag = TrashBag()
        self.BuildEffectBones = bp.General.BuildBones.BuildEffectBones
        --set up missile slider
        self.missileBone = bp.Display.MissileBone
        if self.missileBone then
            if not self.MissileSlider then
                self.MissileSlider = CreateSlider(self, self.missileBone)
                self.Trash:Add(self.MissileSlider)
            end
        end
    end,

    OnSiloBuildStart = function(self, weapon)
        self.MissileBuilt = false
        self:PlayBuildEffects()
        self:ForkThread(self.MissileBuildSequence)
        SStructureUnit.OnSiloBuildStart(self, weapon)
    end,

    --when the missile is finished not when cancelled
    OnSiloBuildEnd = function(self, weapon)
        self.MissileBuilt = true
        self:StopBuildEffects()
        SStructureUnit.OnSiloBuildEnd(self,weapon)
    end,

    PlayBuildEffects = function(self)
        self.MissileEffectsBag:Destroy() --clear any effects
        self:AddEffects(EffectTemplate.SJammerCrystalAmbient, self.BuildEffectBones, self.MissileEffectsBag)
        self:PlayUnitSound('Construct')
        self:PlayUnitAmbientSound('ConstructLoop')
    end,

    StopBuildEffects = function(self)
        self.MissileEffectsBag:Destroy() --clear any effects
        self:StopUnitAmbientSound('ConstructLoop')
        self:PlayUnitSound('ConstructStop')
    end,
    
    --check out this custom effect stuffer function, its fantastic!
    AddEffects = function (self, effects, bones, bag)
        local army, emit = self:GetArmy()
        for _, effect in effects do
            for _, bone in bones do
                emit = CreateAttachedEmitter(self, bone, army, effect)
                bag:Add(emit)
                self.Trash:Add(emit)
            end
        end
    end,

    HideMissile = function(self)
        if self.missileBone then
            self:HideBone(self.missileBone, true)
            if self.MissileSlider then
                self.MissileSlider:SetSpeed(400)
                self.MissileSlider:SetGoal(0,0,0)
            end
        end
    end,

    MissileBuildSequence = function(self)
        WaitSeconds(0.5)
        self:ShowBone(self.missileBone, true)
        self.MissileSlider:SetSpeed(6)
        local fractionComplete = 0

        --watch the build time to check for cancellation
        while true do
            if self:IsUnitState('SiloBuildingAmmo') then
                --update missile slider position, so it scales with reload time.
                fractionComplete = self:GetWorkProgress()
                self.MissileSlider:SetGoal(0, 0, 115*fractionComplete)
            elseif not self.MissileBuilt then
                self:HideMissile()
                self:StopBuildEffects()
                return
            end
            WaitTicks(1)
        end
    end,

    ChargeNukeSound = function(self)
        WaitSeconds(1.5)
        self:PlayUnitAmbientSound('NukeCharge')
        WaitSeconds(9.5)
        self:StopUnitAmbientSound('NukeCharge')
    end,
}

TypeClass = XSB2401
