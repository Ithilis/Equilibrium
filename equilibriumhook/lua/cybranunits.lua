--****************************************************************************
--**
--**  File     :  /lua/cybranunits.lua
--**  Author(s):
--**
--**  Summary  :
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
----------------------------------------------------------------------------
-- CYBRAN DEFAULT UNITS
----------------------------------------------------------------------------
local DefaultUnitsFile = import('defaultunits.lua')
local AirFactoryUnit = DefaultUnitsFile.AirFactoryUnit
local AirStagingPlatformUnit = DefaultUnitsFile.AirStagingPlatformUnit
local AirUnit = DefaultUnitsFile.AirUnit
local ConcreteStructureUnit = DefaultUnitsFile.ConcreteStructureUnit
local ConstructionUnit = DefaultUnitsFile.ConstructionUnit
local EnergyStorageUnit = DefaultUnitsFile.EnergyStorageUnit
local LandFactoryUnit = DefaultUnitsFile.LandFactoryUnit
local SeaFactoryUnit = DefaultUnitsFile.SeaFactoryUnit
local SeaUnit = DefaultUnitsFile.SeaUnit
local ShieldLandUnit = DefaultUnitsFile.ShieldLandUnit
local ShieldStructureUnit = DefaultUnitsFile.ShieldStructureUnit
local StructureUnit = DefaultUnitsFile.StructureUnit
local QuantumGateUnit = DefaultUnitsFile.QuantumGateUnit
local RadarJammerUnit = DefaultUnitsFile.RadarJammerUnit
local CommandUnit = DefaultUnitsFile.CommandUnit

local Util = import('utilities.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('EffectUtilities.lua')
local CreateCybranBuildBeams = EffectUtil.CreateCybranBuildBeams



--we hook these to revert the effect changes to the cybran engies and build bots 
--for hives it makes it lag a lot less and for engies it makes them back to their intended look and more consistent too.
---------------------------------------------------------------
--  CONSTRUCTION UNITS
---------------------------------------------------------------
oldCConstructionUnit = CConstructionUnit

CConstructionUnit = Class(oldCConstructionUnit){

    CreateBuildEffects = function( self, unitBeingBuilt, order )
        local buildbots = EffectUtil.SpawnBuildBots( self, unitBeingBuilt, self.BuildEffectsBag)
        if buildbots then
            EffectUtil.CreateCybranEngineerBuildEffects( self, self:GetBlueprint().General.BuildBones.BuildEffectBones, buildbots, self.BuildEffectsBag )
        else
            EffectUtil.CreateCybranBuildBeams( self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
        end
    end,
}

--TODO: This should be made more general and put in defaultunits.lua in case other factions get similar buildings
----------------------------------------------------------------------------------------------------------------------------
--  CConstructionStructureUnit
----------------------------------------------------------------------------------------------------------------------------
oldCConstructionStructureUnit = CConstructionStructureUnit

CConstructionStructureUnit = Class(oldCConstructionStructureUnit) {

    CreateBuildEffects = function( self, unitBeingBuilt, order )
        local buildbots = EffectUtil.SpawnBuildBots( self, unitBeingBuilt, self.BuildEffectsBag, table.getn(self:GetBlueprint().General.BuildBones.BuildEffectBones) )
        if buildbots then
            EffectUtil.CreateCybranEngineerBuildEffects( self, self:GetBlueprint().General.BuildBones.BuildEffectBones, buildbots, self.BuildEffectsBag )
        else
            EffectUtil.CreateCybranBuildBeams( self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
        end
    end,
    
}
