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
        --tell it that it can build, and give it the right build rate as well.
        self.BuildingEnabled = true
        self:ForkThread( self.BuildrateThread )
        --self:SetCollisionShape('None')
        --define the bone which we will attach our unit being built to
        ChangeState(self, self.IdleState)
    end,
    
    BuildrateThread = function(self)
        WaitSeconds(0.1)
        if not self.Parent then WARN('EQ: could not find parent for mobile factory! something is wrong!') return end
        self:SetBuildRate(self.Parent:GetBuildRate())
        self.Parent:AddBuildRestriction(categories.ALLUNITS) --in eq we hook the units so here we just disable the parent from building. easy.
        --we need a small delay from oncreate to set the buildrate since the parent isnt set immediately.
    end,
    
    OnDestroy = function(self)
        --incase we delete our factory, since the unit being built isnt attached to it it doesnt always work.
        if self.UnitBeingBuilt and not self.UnitBeingBuilt:IsDead() then
            if self.UnitBeingBuilt:GetFractionComplete() ~= 1 then
                self.UnitBeingBuilt:Destroy()
            end
        end
        TMobileFactoryUnit.OnDestroy(self)
    end,
    --this factory unit needs to attach to its parent bone, and needs a parent bone on which to attach the unit.
    --the parent unit can have roll off effects inside CreateRollOffEffects() with delays or w.e. that need to switch this units state to idle when its done.
    
    IdleState = State {
        OnStartBuild = function(self, unitBuilding, order)
        
            self.UnitBeingBuilt = unitBuilding
            self.FacBone = self.Parent.BuildAttachBone
            self.Parent:DetachAll(self.FacBone) --the factory bone we want to attach our unit being built to
            self:DetachAll('Attachpoint') -- our bone which the unit is attached to by engine
            
            if not self.UnitBeingBuilt:IsDead() then
                unitBuilding:AttachBoneTo( -2, self.Parent, self.FacBone )
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
    
    --switches building on and off, to be called from the parent unit, also cancels current unit.
    --currently broken, can cause total crash if you use IssueClearCommands({self}) or something.
    DisableBuild = function(self)
        if self.BuildingEnabled then    
            WARN('changing state to rolloff')
            if self.UnitBeingBuilt and self.UnitBeingBuilt:GetFractionComplete() ~= 1 then
                --self.Parent:DetachAll(self.FacBone) --the factory bone we want to attach to
                WARN('cancelling order')
                --IssueStop({self})
                --IssueClearCommands({self})
            end
            ChangeState(self, self.RollingOffState)
            WARN('changing to rolloff state in disablebuild')
            self.BuildingEnabled = false
        end
    end,
    
    --should be called after disablebuild
    EnableBuild = function(self)
        if not self.BuildingEnabled then
            WARN('changing state to idle')
            ChangeState(self, self.IdleState)
            self.BuildingEnabled = true
        end
    end,
    
}

TypeClass = ZXB0301
