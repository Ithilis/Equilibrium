-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0401/UEL0401_script.lua
-- Author(s):  John Comes, David Tomandl, Gordon Duclos
-- Summary  :  UEF Mobile Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local TMobileFactoryUnit = import('/lua/terranunits.lua').TMobileFactoryUnit
local WeaponsFile = import('/lua/terranweapons.lua')
local TDFGaussCannonWeapon = WeaponsFile.TDFLandGaussCannonWeapon
local TDFRiotWeapon = WeaponsFile.TDFRiotWeapon
local TAALinkedRailgun = WeaponsFile.TAALinkedRailgun
local TANTorpedoAngler = WeaponsFile.TANTorpedoAngler
local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local CreateUEFBuildSliceBeams = EffectUtil.CreateUEFBuildSliceBeams

UEL0401 = Class(TMobileFactoryUnit) {
    FxDamageScale = 2.5,
    PrepareToBuildAnimRate = 5,
    BuildAttachBone = 'Build_Attachpoint',
    FactoryAttachBone = 'Ramp',
    RollOffBones = { 'Arm_Right03_Build_Emitter', 'Arm_Left03_Build_Emitter',},

    Weapons = {
        RightTurret01 = Class(TDFGaussCannonWeapon) {},
        RightTurret02 = Class(TDFGaussCannonWeapon) {},
        LeftTurret01 = Class(TDFGaussCannonWeapon) {},
        LeftTurret02 = Class(TDFGaussCannonWeapon) {},
        RightRiotgun = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        LeftRiotgun = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        RightAAGun = Class(TAALinkedRailgun) {},
        LeftAAGun = Class(TAALinkedRailgun) {},
        Torpedo = Class(TANTorpedoAngler) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TMobileFactoryUnit.OnStopBeingBuilt(self,builder,layer)
        self.EffectsBag = {}
        self.PrepareToBuildManipulator = CreateAnimator(self)
        self.PrepareToBuildManipulator:PlayAnim(self:GetBlueprint().Display.AnimationBuild, false):SetRate(0)
        self.ReleaseEffectsBag = {}
        self.AttachmentSliderManip = CreateSlider(self, self.BuildAttachBone)
        self:CreateHelperFac()
        ChangeState(self, self.IdleState)
    end,

    CreateHelperFac = function(self)
        -- Create helper factory and attach to attachpoint bone
        local location = self:GetPosition(self.FactoryAttachBone)
        --local orientation = self:GetOrientation()
        local army = self:GetArmy()
        if not self.HelperFactory then
            --its seems that because of nonsense, spawning the module outside the unit then warping to it helps with pathfinding
            self.HelperFactory = CreateUnitHPR('ZXB0301', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
            self.HelperFactory.Parent = self
            self.HelperFactory:SetCreator(self)
            self.Trash:Add(self.HelperFactory)
        end
        if not self.ProxyAttach then
            --yeeeahhhh. attaching a helper fac directly to a carrier hides its strategic icon so we use a proxy ...
            --also for 
            self.ProxyAttach = CreateUnitHPR('ZXB0302', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
            self.ProxyAttach.Parent = self
            self.ProxyAttach:SetCreator(self)
            self.Trash:Add(self.ProxyAttach)
        end
        self:DetachAll(self.FactoryAttachBone)
        self.ProxyAttach:DetachAll(1)
        self.HelperFactory:AttachTo(self.ProxyAttach, 1)
        self.ProxyAttach:AttachTo(self, self.FactoryAttachBone)
        
        self:SetFactoryRestrictions()
    end,
    
    
    OnGiven = function(self, newUnit)
        if self.UnitBeingBuilt then
            self.UnitBeingBuilt:Destroy()
        end --this is to stop us getting 50% finished units and turning them into 100% finished units, but it doesnt work :(
        TMobileFactoryUnit.OnGiven(self)
        
    end,
    
    OnFailedToBuild = function(self)
        TMobileFactoryUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,
    
    -- This unit needs to not be allowed to build while underwater
    -- Additionally, if it goes underwater while building it needs to cancel the current order
    OnLayerChange = function(self, new, old)
        TMobileFactoryUnit.OnLayerChange(self, new, old)
        self:UpdateFactoryRestrictions(new)
    end,
    
    SetFactoryRestrictions = function(self)
        if not self.HelperFactory then return end
        local restrictions = self:GetBlueprint().Economy.BuildableCategoryMobile
        self.HelperFactory:AddBuildRestriction(categories.ALLUNITS)
        for k,category in restrictions do
            local parsedCat = ParseEntityCategory(category)
            self.HelperFactory:RemoveBuildRestriction(parsedCat)
        end
        self.HelperFactory:RequestRefreshUI()
    end,
    
    UpdateFactoryRestrictions = function(self, layer)
        if not self.HelperFactory then return end
        if layer == 'Land' then
            self:SetFactoryRestrictions()
        elseif layer == 'Seabed' then
            self.HelperFactory:AddBuildRestriction(categories.ALLUNITS)
            self.HelperFactory:RemoveBuildRestriction(categories.xel0305)
            self.HelperFactory:RequestRefreshUI()
        end
    end,

    IdleState = State {
        OnStartBuild = function(self, unitBuilding, order)
            --TMobileFactoryUnit.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            self.PrepareToBuildManipulator:SetRate(self.PrepareToBuildAnimRate)
            ChangeState(self, self.BuildingState)
        end,

        Main = function(self)
            self.PrepareToBuildManipulator:SetRate(-self.PrepareToBuildAnimRate)
            self:DetachAll(self.BuildAttachBone)
            --self:SetBusy(false)
        end,
    },

    BuildingState = State {
        Main = function(self)
            self.PrepareToBuildManipulator:SetRate(self.PrepareToBuildAnimRate)
            WaitFor(self.PrepareToBuildManipulator)
            self.UnitBeingBuilt:ShowBone(0,true)
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            ChangeState(self, self.RollingOffState)
        end,
    },

    RollingOffState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            if not unitBuilding:IsDead() then
                unitBuilding:ShowBone(0,true)
            end
            WaitFor(self.PrepareToBuildManipulator)
            WaitFor(self.AttachmentSliderManip)
            
            self:CreateRollOffEffects()
            self.AttachmentSliderManip:SetSpeed(10)
            self.AttachmentSliderManip:SetGoal(0, 0, 17)
            WaitFor(self.AttachmentSliderManip)
            
            self.AttachmentSliderManip:SetGoal(0, -3, 17)
            WaitFor(self.AttachmentSliderManip)
            
            if not unitBuilding:IsDead() then
                unitBuilding:DetachFrom(true)
                self:DetachAll(self.BuildAttachBone)
                local  worldPos = self:CalculateWorldPositionFromRelative({0, 0, -15})
                IssueStop( {unitBuilding} ) --the unit gets engine orders to move to a point not far off the fac
                IssueClearCommands( {unitBuilding} ) --so we need to cancel them since they dont get updated
                IssueMoveOffFactory({unitBuilding}, worldPos)
            end
            
            --reset the slider
            self.AttachmentSliderManip:SetGoal(0, 0, 0)
            self.AttachmentSliderManip:SetSpeed(90)
            WaitSeconds(0.2)
            
            self:DestroyRollOffEffects()
            ChangeState(self, self.IdleState)
            ChangeState(self.HelperFactory, self.HelperFactory.IdleState) --let our factory know we are done.
        end,
    },

    CreateRollOffEffects = function(self, unit)
        local army = self:GetArmy()
        local unitB = self.UnitBeingBuilt
        if unitB:IsDead() then WARN('tried to attach effects to a dead unit') return end
        for k, v in self.RollOffBones do
            local fx = AttachBeamEntityToEntity(self, v, unitB, -1, army, EffectTemplate.TTransportBeam01)
            table.insert( self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
            
            fx = AttachBeamEntityToEntity( unitB, -1, self, v, army, EffectTemplate.TTransportBeam02)
            table.insert( self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
            
            fx = CreateEmitterAtBone( self, v, army, EffectTemplate.TTransportGlow01)
            table.insert( self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
        end
    end,

    DestroyRollOffEffects = function(self)
        for k, v in self.ReleaseEffectsBag do
            v:Destroy()
        end
        self.ReleaseEffectsBag = {}
    end,
}

TypeClass = UEL0401