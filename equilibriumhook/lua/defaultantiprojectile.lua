--****************************************************************************
--**
--**  File     :  /lua/defaultantimissile.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Default definitions collision beams
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local Entity = import('/lua/sim/Entity.lua').Entity

MissileRedirect = Class(Entity) {

    RedirectBeams = {--'/effects/emitters/particle_cannon_beam_01_emit.bp',
                   '/effects/emitters/particle_cannon_beam_02_emit.bp'},
    EndPointEffects = {'/effects/emitters/particle_cannon_end_01_emit.bp',},

    OnCreate = function(self, spec)
        Entity.OnCreate(self, spec)
        self.Owner = spec.Owner
        self.Weapon = spec.Weapon --EQ:Add a weapon to create the projectile from
        self.Radius = spec.Radius
        self.RedirectRateOfFire = spec.RedirectRateOfFire or 1
        self:SetCollisionShape('Sphere', 0, 0, 0, self.Radius)
        self:SetDrawScale(self.Radius)
        self.AttachBone = spec.AttachBone
        self:AttachTo(spec.Owner, spec.AttachBone)
        ChangeState(self, self.WaitingState)
    end,

    OnDestroy = function(self)
        Entity.OnDestroy(self)
        ChangeState(self, self.DeadState)
    end,
        
    RedirectProjectile = function(self, enemyData, projectile)
        --calculate the reverse orientation
        local ReverseOrientation = OrientFromDir(Vector(-enemyData.Velocity[1], (-enemyData.Velocity[2])+2, -enemyData.Velocity[3]))
        
        --assign data
        projectile:SetVelocity(-enemyData.Velocity[1], (-enemyData.Velocity[2])+2, -enemyData.Velocity[3])
        projectile:SetOrientation(ReverseOrientation, true)
        projectile:SetPosition(Vector(enemyData.Position[1], enemyData.Position[2], enemyData.Position[3]),true)
        projectile.BlueprintId = enemyData.BlueprintId
        projectile.Weapon = enemyData.Weapon
        
        if not projectile.DamageData then
            --in rare cases when many loyalists try to redirect at once the new projectile gets destroyed. no idea why.
            WARN('EQ:Loyalist Redirect new projectile missing DamageData table! Creating one. Its most likely just disappeared though.')
        else
            projectile:PassDamageData(enemyData.DamageData)
        end
        
        --set target
        if self.Enemy then
            --if our target is alive, return to sender
            projectile:SetNewTargetGround(self.Enemy:GetPosition())
            projectile:TrackTarget(true)
        else
            --otherwise just be annoying
            --projectile:SetNewTargetGround(self.Enemy:GetPosition())
            projectile:SetLifetime(3)
            --could have set to target the nearest enemy structure you know!
        end
        projectile:SetTurnRate(2)
        
    end,

    DeadState = State {
        Main = function(self)
        end,
    },

    -- Return true to process this collision, false to ignore it.

    WaitingState = State{
        OnCollisionCheck = function(self, other)
            if EntityCategoryContains(categories.MISSILE, other) and not EntityCategoryContains(categories.STRATEGIC, other) 
                        and other != self.EnemyProj and IsEnemy( self:GetArmy(), other:GetArmy() ) then
                self.Enemy = other:GetLauncher()
                self.EnemyProj = other
                
                if not other.Redirected then
                    --EQ: we create our own projectile because switching armies on projectiles isnt possible apparently
                    --We also have to create it like this because nothing else ive tried worked. Well whatever.
                    if other.BlueprintId then
                        self.Weapon:ChangeProjectileBlueprint(other.BlueprintId)
                    else
                        WARN('EQ: Couldnt find stored blueprint ID! Weapon in question overrides CreateProjectileForWeapon!')
                        --just put something in here at least
                        self.Weapon:ChangeProjectileBlueprint('/projectiles/SIFLaanseTacticalMissile01/SIFLaanseTacticalMissile01_proj.bp')
                    end
                    
                    other.Redirected = true --prevent multiple beams hitting it in the same tick
                    
                    self.NewProjectile = self.Weapon:CreateProjectile(self.AttachBone)
                    
                    
                    --We need a lot of info to pass to our new projectile so we pack it into a table
                    local enemyProjData = {}
                    local x,y,z = other:GetVelocity()
                    
                    enemyProjData.Velocity = {x,y,z}
                    enemyProjData.DamageData = other.DamageData
                    enemyProjData.StartingVel = other.StartingVel
                    enemyProjData.Orientation = other:GetOrientation()
                    enemyProjData.Position = other:GetPosition()
                    enemyProjData.BlueprintId = other.BlueprintId
                    enemyProjData.Weapon = other.Weapon
                    
                    
                    if self.NewProjectile.DamageData then
                        self:RedirectProjectile(enemyProjData, self.NewProjectile)
                    else
                        --in rare cases when many loyalists try to redirect at once the new projectile gets destroyed. no idea why.
                        WARN('EQ: Loyalist redirected projectile destroyed. Trying to recreate it.')
                        self.Retry = true
                        self.RetryData = enemyProjData
                    end
                    
                    other:Destroy()--remove the old projectile so it looks like our new one replaced it.
                    ChangeState(self, self.RedirectingState)
                end
            end
            return false
        end,
    },

    RedirectingState = State{

        Main = function(self)
            if not self or self:BeenDestroyed()
            or not self.Owner or self.Owner:IsDead() then
                return
            end
            
            if self.Retry == true then
                local secondProjectile = self.Weapon:CreateProjectile(self.AttachBone)
                self:RedirectProjectile(self.RetryData, secondProjectile)
                self.Retry = false
                self.RetryData = nil
                self.NewProjectile = secondProjectile
            end
            
            --add effects
            local beams = {}
            
            if self.NewProjectile then
                for k, v in self.RedirectBeams do               
                    table.insert(beams, AttachBeamEntityToEntity(self.NewProjectile, -1, self.Owner, self.AttachBone, self:GetArmy(), v))
                end
                for k, v in beams do --in case the loyalist dies mid beam
                    self.Owner.Trash:Add(v)
                end
            else
                WARN('EQ: New projectile didnt appear! Something is quite wrong!')
            end
            
            WaitSeconds(1/self.RedirectRateOfFire) --this is the reload time - state is changed at the end of this.
            
            for k, v in beams do
                v:Destroy()
            end
            ChangeState(self, self.WaitingState)
        end,

        OnCollisionCheck = function(self, other)
            return false
        end,
    },

}
