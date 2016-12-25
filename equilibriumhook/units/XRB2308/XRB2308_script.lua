--****************************************************************************
--**
--**  File     :  /cdimage/units/XRB2205/XRB2205_script.lua
--**  Author(s):  Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Cybran Heavy Torpedo Launcher Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CKrilTorpedoLauncherWeapon = import('/lua/cybranweapons.lua').CKrilTorpedoLauncherWeapon

XRB2308 = Class(CStructureUnit) {
    Weapons = {
        Turret01 = Class(CKrilTorpedoLauncherWeapon) {},
    },
    
    OnStopBeingBuilt = function(self,builder,layer)
        CStructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:StartSinking()
        
        local army = self:GetArmy() --add inital sinking effects
        self.Trash:Add(CreateAttachedEmitter(self,'xrb2308', army, '/effects/emitters/tt_water02_footfall01_01_emit.bp'):ScaleEmitter(1.4)) --one-off
        self.Trash:Add(CreateAttachedEmitter(self,'xrb2308', army, '/effects/emitters/tt_snowy01_landing01_01_emit.bp'):ScaleEmitter(1.5)) --one-off

        ChangeState(self, self.IdleState)
    end,
    
    StartSinking = function(self)
        local bone = 0
        
        local army = self:GetArmy() --add sinking effect for the duration of the sinking
        self.Trash:Add(CreateAttachedEmitter(self,'xrb2308', army, '/effects/emitters/tt_water_submerge02_01_emit.bp'):ScaleEmitter(1.5)) --continuous
        --Create sinker projectile
        local proj = self:CreateProjectileAtBone('/projectiles/Sinker/Sinker_proj.bp', bone)
        self.sinkProjectile = proj
        -- Start the sinking after a delay of the given number of seconds, attaching to a given bone
        -- and entity.
        proj:SetVelocityAlign(false)
        proj:SetLocalAngularVelocity(0, 0, 0) -- change this to make it rotate some while sinking
        proj:Start(0, self, bone, self.CheckDepth)
        proj:SetBallisticAcceleration(-0.75)
        self.Trash:Add(proj)
        self.Depthwatcher = self:ForkThread(self.SinkDepthThread)
    end,
    
    CheckDepth = function(self)
    return
    end,
    
    SinkDepthThread = function(self)
        --self:SeabedWatcher()-- Waits for wreck to hit bottom or end of animation
        WaitSeconds(5.2) --use this to set the depth - basic maths required (:
        
        if not self:IsDead() and self.sinkProjectile then
            self.sinkProjectile:Destroy()
            self.sinkProjectile = nil
            self:SetPosition(self:GetPosition(), true)
            self:FinalAnimation()
        end
    end,
    
    FinalAnimation = function(self)
        if self.sinkProjectile then --clearing the sink projectile in case we need to reuse it.
            self.sinkProjectile:Destroy()
            self.sinkProjectile = nil
        elseif self:IsDead() then return end
        
        --setting the deploy animation to the end of its sinking and not the start.
        local bp = self:GetBlueprint()
        local bpAnim = bp.Display.AnimationDeploy
        if not bpAnim then return end
        if not self.OpenAnim then
            self.OpenAnim = CreateAnimator(self)
            self.OpenAnim:PlayAnim(bpAnim)
            self.Trash:Add(self.OpenAnim)
        end
        
        self:PlaySound(bp.Audio.Deploy)
    end,
    
    --hijacking the original death thread so it doesnt disrupt our sinking.
    DeathThread = function( self, overkillRatio, instigator)
        self:DestroyTopSpeedEffects()
        self:DestroyIdleEffects()
        self:DestroyBeamExhaust()
        self:DestroyAllBuildEffects()
        
        local bp = self:GetBlueprint()
        self:PlaySound(bp.Audio.Destroyed)
        local army = self:GetArmy() --add an initial death explosion
        self.Trash:Add(CreateAttachedEmitter(self,'xrb2308', army, '/effects/emitters/flash_03_emit.bp'):ScaleEmitter(2))
        self.Trash:Add(CreateAttachedEmitter(self,'xrb2308', army, '/effects/emitters/flash_04_emit.bp'):ScaleEmitter(2))
        
        if self.ShowUnitDestructionDebris and overkillRatio then -- Flying bits of metal and whatnot. More bits for more overkill.
            self.CreateUnitDestructionDebris(self, true, true, overkillRatio > 2)
        end
        
        self.DisallowCollisions = true
        self:ForkThread(self.SinkDestructionEffects) -- Bubbles and stuff coming off the sinking wreck.
        self.overkillRatio = overkillRatio -- Avoid slightly ugly need to propagate this through callback hell...
        
        if not self.sinkProjectile then --in the case that we are not on the seabed
            self:StartSinking()
        end
        
        self:SeabedWatcher()-- Waits for wreck to hit bottom or end of animation
        self:DestroyAllDamageEffects()
        
        
        if self.PlayDestructionEffects then --moved to the end to make sure its sunk before exploding
            self:CreateDestructionEffects(overkillRatio)
        end
        
        self:PlayUnitSound('Destroyed')
        self:CreateWreckage(overkillRatio, instigator)
        self:Destroy()
    end,
    
}
TypeClass = XRB2308
