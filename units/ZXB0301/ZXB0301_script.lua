#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB0301/UEB0301_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Helper factory for enabling mobile factories to build while moving
#**
#**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TMobileFactoryUnit = import('/lua/terranunits.lua').TMobileFactoryUnit

ZXB0301 = Class(TMobileFactoryUnit) {

    OnCreate = function(self)
        TMobileFactoryUnit.OnCreate(self)
        --make our factory invisible
        self:HideBone(0, true)
        self.DisallowCollisions = true
        --make it unkillable
        self:SetCanTakeDamage(false)
        self:SetCanBeKilled(false)
        
        --self:SetCollisionShape('None')
        --define the bone which we will attach our unit being built to
        ChangeState(self, self.IdleState)
    end,
    
    OnDestroy = function(self)
        --incase we delete our factory, since the unit being built isnt attached to it it doesnt always work.
        if self.UnitBeingBuilt and self.UnitBeingBuilt:GetFractionComplete() ~= 1 then
            self.UnitBeingBuilt:Destroy()
        end
        TMobileFactoryUnit.OnDestroy(self)
    end,
    --this factory unit needs to attach to its parent bone, and needs a parent bone on which to attach the unit.
    --the parent unit can have roll off effects inside CreateRollOffEffects() with delays or w.e. that need to switch this units state to idle when its done.
    
    IdleState = State {
        OnStartBuild = function(self, unitBuilding, order)
        
            self.UnitBeingBuilt = unitBuilding
            self.FacBone = self.Parent.BuildAttachBone
            self.Parent:DetachAll(self.FacBone) --the factory bone we want to attach to
            self:DetachAll('Attachpoint') -- our bone which the unit is attached to by engine
            
            if not self.UnitBeingBuilt:IsDead() then
                unitBuilding:AttachBoneTo( -2, self.Parent, self.FacBone )
                local unitHeight = unitBuilding:GetBlueprint().SizeY
                unitBuilding:HideBone(0,true) --we hide our unit bone, its up to our parent to show it.
            end
            
            --notify the parent. it should then do any code it needs like effects and anims and unhiding the unit, ect.
            self.Parent.OnStartBuild(self.Parent, unitBuilding, order)
            ChangeState(self, self.BuildingState)
            self.UnitDoneBeingBuilt = false
            
            TMobileFactoryUnit.OnStartBuild(self, unitBuilding, order)
        end,

        Main = function(self)
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
        end,
    },

    BuildingState = State {
        Main = function(self)
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            TMobileFactoryUnit.OnStopBuild(self, unitBeingBuilt)
            ChangeState(self.Parent, self.Parent.RollingOffState)
            ChangeState(self, self.RollingOffState)
        end,
    },

    RollingOffState = State {
        Main = function(self)
            self:SetBusy(true)
            self:SetBlockCommandQueue(true)
            --we then switch to the idle state from here
        end,
    },

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

    -- IdleState = State {
        -- OnStartBuild = function(self, unitBuilding, order)
            -- TMobileFactoryUnit.OnStartBuild(self, unitBuilding, order)
            -- self.UnitBeingBuilt = unitBuilding
            -- self.Parent.PrepareToBuildManipulator:SetRate(self.Parent.PrepareToBuildAnimRate)
            -- ChangeState(self, self.BuildingState)
        -- end,

        -- Main = function(self)
            -- self.Parent.PrepareToBuildManipulator:SetRate(-self.Parent.PrepareToBuildAnimRate)
            -- self.Parent:DetachAll(self.Parent.BuildAttachBone)
            -- self:SetBusy(false)
        -- end,
    -- },

    -- BuildingState = State {
        -- Main = function(self)
            -- local unitBuilding = self.UnitBeingBuilt
            -- self.Parent.PrepareToBuildManipulator:SetRate(self.Parent.PrepareToBuildAnimRate)
            -- local bone = self.Parent.BuildAttachBone
            -- self.Parent:DetachAll(bone)
            -- self:DetachAll('Attachpoint')
            -- if not self.UnitBeingBuilt:IsDead() then
                -- unitBuilding:AttachBoneTo( -2, self.Parent, bone )
                -- local unitHeight = unitBuilding:GetBlueprint().SizeY
                -- self.Parent.AttachmentSliderManip:SetGoal(0, unitHeight, 0 )
                -- self.Parent.AttachmentSliderManip:SetSpeed(-1)
                -- unitBuilding:HideBone(0,true)
            -- end
            -- WaitSeconds(3)
            -- unitBuilding:ShowBone(0,true)
            -- WaitFor( self.Parent.PrepareToBuildManipulator )
            -- local unitBuilding = self.UnitBeingBuilt
            -- self.UnitDoneBeingBuilt = false
        -- end,

        -- OnStopBuild = function(self, unitBeingBuilt)
            -- TMobileFactoryUnit.OnStopBuild(self, unitBeingBuilt)

            -- ChangeState(self, self.RollingOffState)
        -- end,
    -- },

    -- RollingOffState = State {
        -- Main = function(self)
            -- local unitBuilding = self.UnitBeingBuilt
            -- if not unitBuilding:IsDead() then
                -- unitBuilding:ShowBone(0,true)
            -- end
            -- WaitFor(self.Parent.PrepareToBuildManipulator)
            -- WaitFor(self.Parent.AttachmentSliderManip)
            
            -- self.Parent:CreateRollOffEffects(self.UnitBeingBuilt)
            -- self.Parent.AttachmentSliderManip:SetSpeed(10)
            -- self.Parent.AttachmentSliderManip:SetGoal(0, 0, 17)
            -- WaitFor(self.Parent.AttachmentSliderManip)
            
            -- self.Parent.AttachmentSliderManip:SetGoal(0, -3, 17)
            -- WaitFor(self.Parent.AttachmentSliderManip)
            
            -- if not unitBuilding:IsDead() then
                -- unitBuilding:DetachFrom(true)
                -- self.Parent:DetachAll(self.Parent.BuildAttachBone)
                -- local  worldPos = self:CalculateWorldPositionFromRelative({0, 0, -15})
                -- IssueMoveOffFactory({unitBuilding}, worldPos)
            -- end
            
            -- self:DestroyRollOffEffects()
            -- ChangeState(self, self.IdleState)
        -- end,
    -- },

    -- CreateRollOffEffects = function(self)
        -- local army = self:GetArmy()
        -- local unitB = self.UnitBeingBuilt
        -- for k, v in self.Parent.RollOffBones do
            -- local fx = AttachBeamEntityToEntity(self.Parent, v, unitB, -1, army, EffectTemplate.TTransportBeam01)
            -- table.insert( self.Parent.ReleaseEffectsBag, fx)
            -- self.Parent.Trash:Add(fx)
            
            -- fx = AttachBeamEntityToEntity( unitB, -1, self.Parent, v, army, EffectTemplate.TTransportBeam02)
            -- table.insert( self.Parent.ReleaseEffectsBag, fx)
            -- self.Parent.Trash:Add(fx)
            
            -- fx = CreateEmitterAtBone( self.Parent, v, army, EffectTemplate.TTransportGlow01)
            -- table.insert( self.Parent.ReleaseEffectsBag, fx)
            -- self.Parent.Trash:Add(fx)
        -- end
    -- end,

    -- DestroyRollOffEffects = function(self)
        -- for k, v in self.Parent.ReleaseEffectsBag do
            -- v:Destroy()
        -- end
        -- self.Parent.ReleaseEffectsBag = {}
    -- end,
}

TypeClass = ZXB0301
