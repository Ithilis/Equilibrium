#****************************************************************************
#**
#**  File     :  /data/projectiles/SIFLaanseTacticalMissile01/SIFLaanseTacticalMissile01_script.lua
#**  Author(s):  Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Laanse Tactical Missile Projectile script, XSL0111
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SLaanseTacticalMissile = import('/lua/seraphimprojectiles.lua').SLaanseTacticalMissile

SIFLaanseTacticalMissile01EQ = Class(SLaanseTacticalMissile) {
    
    OnCreate = function(self)
        SLaanseTacticalMissile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2)
        self.MoveThread = self:ForkThread(self.MovementThread)
    end,

    MovementThread = function(self)        
        self.WaitTime = 0.1
        self.Distance = self:GetDistanceToTarget()
        local MissileCheck = self.Distance
        
        
        local DamageMult = 2 -- how much more damage our long range missile deals.
        
        if MissileCheck < 40 then -- check if we want to use the short range missile or not.    
            Target = self:GetTrackingTarget()       -- if the target is a building then we use the "non-homing" missile, actually its homing but buildings cant move so it doesnt matter - and this helps ensure an impact at low ranges.
            
            if EntityCategoryContains(categories.STRUCTURE, Target) == true then 
                self.DamageData.DamageAmount = self.DamageData.DamageAmount * DamageMult
            end
            
            while not self:BeenDestroyed() do
                self:SetTurnRateByDist()
                WaitSeconds(self.WaitTime)
            end
        end
        
        if MissileCheck > 40 then -- activate the long range missile unless the short range one was activated
            WaitSeconds( 0.1 )
                -- get own values and prepare to create new projectile
            local vx, vy, vz = self:GetVelocity()
            local ChildProjectileBP = '/Mods/Equilibrium/projectiles/SIFLaanseTacticalMissile02EQ/SIFLaanseTacticalMissile02EQ_proj.bp'   -- this is the tml one i think - needs changing to its own custom one! as soon as i get that to work :(
            
            self.DamageData.DamageAmount = (self.DamageData.DamageAmount * DamageMult) --increase the damage since we are going into long range mode
            
            local proj = self:CreateChildProjectile(ChildProjectileBP)
            proj:SetVelocity( vx, vy, vz )
            proj:PassDamageData(self.DamageData)
            self:Destroy()
        end
        
        if MissileCheck < 10 then -- if we havent switched then start launch procedures
            self:SetTurnRate(50) -- high turn rate cos target is really close!
            else 
            self:SetTurnRate(8) -- making the missile go up a bit before activating tracking/long range mode
        end
        
        WaitSeconds(0.8)    
        
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > self.Distance then
        	self:SetTurnRate(75)
        	WaitSeconds(3)
        	self:SetTurnRate(50)
        	self.Distance = self:GetDistanceToTarget()
        end
        if dist > 50 then        
            --Freeze the turn rate as to prevent steep angles at long distance targets
            self:SetTurnRate(10)
            WaitSeconds(2)
        elseif dist > 30 and dist <= 50 then
						self:SetTurnRate(12)
						WaitSeconds(1.5)
            self:SetTurnRate(12)
        elseif dist > 10 and dist <= 25 then
            WaitSeconds(0.3)
            self:SetTurnRate(50)
				elseif dist > 0 and dist <= 10 then           
            self:SetTurnRate(60)
            KillThread(self.MoveThread)         
        end
    end,        

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
    

}
TypeClass = SIFLaanseTacticalMissile01EQ

