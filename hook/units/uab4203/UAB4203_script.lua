#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB4203/UAB4203_script.lua
#**  Author(s):  David Tomandl, Jessica St. Croix, John Comes, Gordon Duclos
#**
#**  Summary  :  Aeon Radar Jammer Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ARadarJammerUnit = import('/lua/aeonunits.lua').ARadarJammerUnit

UAB4203 = Class(ARadarJammerUnit) {
    IntelEffects = {
		{
			Bones = {
				'UAB4203',
			},
			Offset = {
				0,
				3.5,
				0,
			},
			Type = 'Jammer01',
		},
    },
    
    
    RotateSpeed = 60,
    Armour = false,
    
    OnStopBeingBuilt = function(self, builder, layer)
        ARadarJammerUnit.OnStopBeingBuilt(self, builder, layer)
        local bp = self:GetBlueprint()
        local bpAnim = bp.Display.AnimationOpen
        if not bpAnim then return end
        if not self.OpenAnim then
            self.OpenAnim = CreateAnimator(self)
            self.OpenAnim:PlayAnim(bpAnim)
            self.Trash:Add(self.OpenAnim)
        end
        if not self.Rotator then
            self.Rotator = CreateRotator(self, 'B02', 'z', nil, 0, 50, 0)
            self.Trash:Add(self.Rotator)
        end
        
    end,
    
    OnIntelEnabled = function(self)
        ARadarJammerUnit.OnIntelEnabled(self)
        if self.OpenAnim then
            self.OpenAnim:SetRate(1)
        end
        if not self.Rotator then
            self.Rotator = CreateRotator(self, 'B02', 'z', nil, 0, 50, 0)
            self.Trash:Add(self.Rotator)
        end
        self.Rotator:SetSpinDown(false)
        self.Rotator:SetTargetSpeed(self.RotateSpeed)
        
        
        if self.Armour == true then
            self:SetHealth(self,(self:GetHealth()/10 ))
            self:SetMaxHealth(self:GetMaxHealth()/10)
            self:SetRegenRate(0)
            self.Armour = false
        end
    end,

    OnIntelDisabled = function(self)
        ARadarJammerUnit.OnIntelDisabled(self)
        if self.OpenAnim then
            self.OpenAnim:SetRate(-1)
        end
        if self.Rotator then            
            self.Rotator:SetTargetSpeed(0)
        end
        
        if self.Armour == false then
            SetMaxHP = self:GetMaxHealth()*10
            SetHP = self:GetHealth()*10
            self.ArmourThread = self:ForkThread(self.EnableArmourThread)
            
        end


    end,    
    
    EnableArmourThread = function(self) 
        WaitFor( self.OpenAnim )
        self:SetMaxHealth(SetMaxHP)
        self:SetHealth(self,(SetHP))
        self:SetRegenRate(5)
        self.Armour = true
        KillThread(self.ArmourThread)    
    end,
   
}

TypeClass = UAB4203