#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB1102/UAB1102_script.lua
#**  Author(s):  Jessica St. Croix, John Comes
#**
#**  Summary  :  Aeon Hydrocarbon Power Plant Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AEnergyCreationUnit = import('/lua/aeonunits.lua').AEnergyCreationUnit
UAB1102 = Class(AEnergyCreationUnit) {

    AirEffects = {'/effects/emitters/hydrocarbon_smoke_01_emit.bp',},
    AirEffectsBones = {'Extension02'},
    WaterEffects = {'/effects/emitters/underwater_idle_bubbles_01_emit.bp',},
    WaterEffectsBones = {'Extension02'},

    OnStopBeingBuilt = function(self,builder,layer)
        AEnergyCreationUnit.OnStopBeingBuilt(self,builder,layer)
        
        self.AnimManip = CreateAnimator(self) --create the animator
        self.Trash:Add(self.AnimManip)
        self.Animation = self:GetBlueprint().Display.AnimationOpen
        
        self.HydroEffectsBag = {}
        
        --choosing effects appropriate to our layer
        self.effects = {}
        self.bones = {}
        self.scale = 0.75
        if self:GetCurrentLayer() == 'Land' then
            self.effects = self.AirEffects
            self.bones = self.AirEffectsBones
        elseif self:GetCurrentLayer() == 'Seabed' then
            self.effects = self.WaterEffects
            self.bones = self.WaterEffectsBones
            self.scale = 3
        end
        
        --we will use two states to swap between, where we will activate and deactivate all the hydro things.
        ChangeState(self, self.OpenState)
    end,
    
    OpenState = State {
        Main = function(self)
            --opening the hydro
            if not self.Open then
                self.Open = true
                self.AnimManip:PlayAnim(self.Animation):SetRate(1)
                WaitFor(self.AnimManip)
            end
            
            self:CreateEffects()
        end,

        OnProductionPaused = function(self)
            AEnergyCreationUnit.OnProductionPaused(self)
            ChangeState(self, self.InActiveState)
        end,
    },

    InActiveState = State {
        Main = function(self)
            self:DestroyEffects()
            --closing the hydro
            if self.Open then
                self.AnimManip:SetRate(-1)
                self.Open = false
                WaitFor(self.AnimManip)
            end
        end,

        OnProductionUnpaused = function(self)
            AEnergyCreationUnit.OnProductionUnpaused(self)
            ChangeState(self, self.OpenState)
        end,
    },
    
    CreateEffects = function(self)
        --we move this from OnStopBeingBuilt so we can turn these on/off many times, for glorious viewing experiences
        if self.HydroEffectsBag then
            for k, v in self.HydroEffectsBag do
                v:Destroy()
            end
		    self.HydroEffectsBag = {}
		end
        
        for keys, values in self.effects do --creating effects from our pre-selected effects table
            for keysbones, valuesbones in self.bones do
                table.insert( self.HydroEffectsBag, CreateAttachedEmitter(self, valuesbones, self:GetArmy(), values):ScaleEmitter(self.scale):OffsetEmitter(0,-0.2,1) )
            end
        end
    end,
    
    DestroyEffects = function(self)
        if self.HydroEffectsBag then
            for k, v in self.HydroEffectsBag do
                v:Destroy()
            end
		    self.HydroEffectsBag = {}
		end
    end,
    
}

TypeClass = UAB1102