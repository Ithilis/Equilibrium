-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/URS0303/URS0303_script.lua
-- **  Author(s):  David Tomandl, Andres Mendez
-- **
-- **  Summary  :  Cybran Aircraft Carrier Script
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local AircraftCarrier = import('/lua/defaultunits.lua').AircraftCarrier
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CAAAutocannon = CybranWeaponsFile.CAAAutocannon
local CAMZapperWeapon = CybranWeaponsFile.CAMZapperWeapon
local loading = false

URS0303 = Class(AircraftCarrier) {

    Weapons = {
    -- Weapons
    --  4 AA Autocannon w/ Guided Rounds
    --  1 "Zapper" Anti-Missile

        AAGun01 = Class(CAAAutocannon) {},
        AAGun02 = Class(CAAAutocannon) {},
        AAGun03 = Class(CAAAutocannon) {},
        AAGun04 = Class(CAAAutocannon) {},

        Zapper = Class(CAMZapperWeapon) {},

    },

    BuildAttachBone = 'Attachpoint',
    FactoryAttachBone = 'Launchpoint',

    OnStopBeingBuilt = function(self,builder,layer)
        AircraftCarrier.OnStopBeingBuilt(self,builder,layer)
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
            self.HelperFactory = CreateUnitHPR('ZXB0303', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
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
    
    OnKilled = function(self, instigator, type, overkillRatio)
        self:DestroyFacs()
        AircraftCarrier.OnKilled(self, instigator, type, overkillRatio)
    end,
    
    OnTransportDetach = function(self, attachBone, unit)
        if unit == self.ProxyAttach or self.HelperFactory then return end
        AircraftCarrier.OnTransportDetach(self, attachBone, unit)
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
    
    OnFailedToBuild = function(self)
        AircraftCarrier.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
        end,

        OnStartBuild = function(self, unitBuilding, order)
            --AircraftCarrier.OnStartBuild(self, unitBuilding, order)
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
            self.UnitBeingBuilt:DetachFrom(true)
            self:DetachAll(self.BuildAttachBone)
            if self:TransportHasAvailableStorage() then
                self:AddUnitToStorage(self.UnitBeingBuilt)
            else
                local worldPos = self:CalculateWorldPositionFromRelative({0, 0, -20})
                IssueMoveOffFactory({self.UnitBeingBuilt}, worldPos)
                self.UnitBeingBuilt:ShowBone(0,true)
            end
            self:SetBusy(false)
            self:RequestRefreshUI()
            ChangeState(self, self.IdleState)
            ChangeState(self.HelperFactory, self.HelperFactory.IdleState) --let our factory know we are done.
        end,
    },

}

TypeClass = URS0303

