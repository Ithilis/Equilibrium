-----------------------------------------------------------------
-- File     :  /cdimage/units/UES0401/UES0401_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  UEF Experimental Submersible Aircraft Carrier Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TSeaUnit = import('/lua/terranunits.lua').TSeaUnit
local TANTorpedoAngler = import('/lua/terranweapons.lua').TANTorpedoAngler
local TSAMLauncher = import('/lua/terranweapons.lua').TSAMLauncher
local EffectUtil = import('/lua/EffectUtilities.lua')
local CreateBuildCubeThread = EffectUtil.CreateBuildCubeThread

UES0401 = Class(TSeaUnit) {
    BuildAttachBone = 'Attachpoint06',
    FactoryAttachBone = 'UES0401',

    Weapons = {
        Torpedo01 = Class(TANTorpedoAngler) {},
        Torpedo02 = Class(TANTorpedoAngler) {},
        Torpedo03 = Class(TANTorpedoAngler) {},
        Torpedo04 = Class(TANTorpedoAngler) {},
        MissileRack01 = Class(TSAMLauncher) {},
        MissileRack02 = Class(TSAMLauncher) {},
        MissileRack03 = Class(TSAMLauncher) {},
        MissileRack04 = Class(TSAMLauncher) {},
    },

    OnKilled = function(self, instigator, type, overkillRatio)
        self:DestroyFacs()
        TSeaUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnCreate = function(self)
        TSeaUnit.OnCreate(self)
        self.OpenAnimManips = {}
        self.OpenAnimManips[1] = CreateAnimator(self):PlayAnim('/units/ues0401/ues0401_aopen.sca'):SetRate(-1)
        for i = 2, 6 do
            self.OpenAnimManips[i] = CreateAnimator(self):PlayAnim('/units/ues0401/ues0401_aopen0' .. i .. '.sca'):SetRate(-1)
        end

        for k, v in self.OpenAnimManips do
            self.Trash:Add(v)
        end

        if self:GetCurrentLayer() == 'Water' then
            self:PlayAllOpenAnims(true)
        end
    end,

    StartBeingBuiltEffects = function(self, builder, layer)
        self:SetMesh(self:GetBlueprint().Display.BuildMeshBlueprint, true)
        if self:GetBlueprint().General.UpgradesFrom ~= builder:GetUnitId() then
            self:HideBone(0, true)        
            self.OnBeingBuiltEffectsBag:Add(self:ForkThread(CreateBuildCubeThread, builder, self.OnBeingBuiltEffectsBag))
        end
    end,

    PlayAllOpenAnims = function(self, open)
        for k, v in self.OpenAnimManips do
            if open then
                v:SetRate(1)
            else
                v:SetRate(-1)
            end
        end
    end,

    OnMotionVertEventChange = function( self, new, old )
        TSeaUnit.OnMotionVertEventChange(self, new, old)
        --we want to be able to build underwater but only when our atlantis has enough space for it.
        if new == 'Down' then
            self:PlayAllOpenAnims(false)
        elseif new == 'Top' then
            self:PlayAllOpenAnims(true)
        end

        if new == 'Up' and old == 'Bottom' then -- When starting to surface
            self.WatchDepth = false
        end

        if new == 'Bottom' and old == 'Down' then -- When finished diving
            self.WatchDepth = true
            if not self.DiverThread then
                self.DiverThread = self:ForkThread(self.DiveDepthThread)
            end
        end
    end,

    DiveDepthThread = function(self)
        -- Takes the given location, adjusts the Y value to the surface height on that location, with an offset
        local Yoffset = 1.2 -- The default (built in) offset appears to be 0.25 - if the place where thats set is found, that would be epic.
        -- 1.2 is for tempest to clear the torpedo tubes from most cases of ground clipping, keeping overall height minimal.
        while self.WatchDepth == true do
            local pos = self:GetPosition()
            local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3]) -- Target depth, in this case the seabed
            local difference = math.max(((seafloor + Yoffset) - pos[2]), -0.5) -- Doesnt sink too much, just maneuveres the bed better.
            self.SinkSlider:SetSpeed(1)
            
            self.SinkSlider:SetGoal(0, difference, 0)
            WaitSeconds(1)
        end

        self.SinkSlider:SetGoal(0, 0, 0) -- Reset the slider while we are not watching depth
        WaitFor(self.SinkSlider)-- We have to wait for it to finish before killing the thread or it stops

        KillThread(self.DiverThread)
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        TSeaUnit.OnStopBeingBuilt(self,builder,layer)
        self:CreateHelperFac()
        ChangeState(self, self.IdleState)

        if not self.SinkSlider then -- Setup the slider and get blueprint values
            self.SinkSlider = CreateSlider(self, 0, 0, 0, 0, 5, true) -- Create sink controller to overlay ontop of original collision detection
            self.Trash:Add(self.SinkSlider)
        end

        self.WatchDepth = false
    end,

    OnFailedToBuild = function(self)
        TSeaUnit.OnFailedToBuild(self)
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
        self.ProxyAttach:DetachAll(2)
        self.HelperFactory:AttachTo(self.ProxyAttach, 2)
        self.ProxyAttach:AttachTo(self, self.FactoryAttachBone)
        
        self:SetFactoryRestrictions()
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
    
    OnTransportDetach = function(self, attachBone, unit)
        if unit == self.ProxyAttach or self.HelperFactory then return end
        TSeaUnit.OnTransportDetach(self, attachBone, unit)
    end,
    
    DestroyFacs = function(self)
        --destroy our helper facs, they arent needed anymore, and this prevents the carrier from trying to detach them.
        self:DetachAll(self.FactoryAttachBone)
        if self.HelperFactory then
            self.HelperFactory:Destroy()
        end
        if self.ProxyAttach then
            self.ProxyAttach:DetachAll(2)
            self.ProxyAttach:Destroy()
        end
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
        end,

        OnStartBuild = function(self, unitBuilding, order)
            --TSeaUnit.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
        end,
    },

    BuildingState = State {
        Main = function(self)
            self:SetBusy(true)
            self.UnitBeingBuilt:HideBone(0, true)
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            ChangeState(self, self.RollingOffState)
        end,
    },

    RollingOffState = State {
        Main = function(self)
            self:SetBusy(true)
            self:DetachAll(self.BuildAttachBone)
            if self.UnitBeingBuilt then
                if self:TransportHasAvailableStorage() then
                    self:AddUnitToStorage(self.UnitBeingBuilt)
                else
                    local worldPos = self:CalculateWorldPositionFromRelative({0, 0, -20})
                    IssueMoveOffFactory({self.UnitBeingBuilt}, worldPos)
                    self.UnitBeingBuilt:ShowBone(0,true)
                end
            end
            
            self:SetBusy(false)
            self:RequestRefreshUI()
            ChangeState(self, self.IdleState)
            ChangeState(self.HelperFactory, self.HelperFactory.IdleState) --let our factory know we are done.
        end,
    },
}

TypeClass = UES0401
