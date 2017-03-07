--****************************************************************************
--**
--**  File     :  /data/units/XSL0305/XSL0305_script.lua
--**
--**  Summary  :  Seraphim Sniper Bot Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SLandUnit = import('/lua/seraphimunits.lua').SLandUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')  --added for effects

local SDFSihEnergyRifleNormalMode = SeraphimWeapons.SDFSniperShotNormalMode
local SDFSihEnergyRifleSniperMode = SeraphimWeapons.SDFSniperShotSniperMode


XSL0305 = Class(SLandUnit) {

    Weapons = {
        MainGun = Class(SDFSihEnergyRifleNormalMode) {},
        SniperGun = Class(SDFSihEnergyRifleSniperMode) {}, --no longer reset the weapon on transport.
    },

    OnCreate = function(self)
        SLandUnit.OnCreate(self)
        self:SetWeaponEnabledByLabel('MainGun', false)
        self:SetScriptBit('RULEUTC_WeaponToggle', true) --Make sniper mode on by default
    end,

    OnScriptBitSet = function(self, bit)
        SLandUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            self:SetWeaponEnabledByLabel('SniperGun', true)
            self:SetWeaponEnabledByLabel('MainGun', false)
            self:GetWeaponManipulatorByLabel('SniperGun'):SetHeadingPitch( self:GetWeaponManipulatorByLabel('MainGun'):GetHeadingPitch() )
        end
		
		---This is to add a visual que that the sniper is in sniper mode
        self.ShieldEffectsBag = {}
		table.insert( self.ShieldEffectsBag, CreateAttachedEmitter( self, 'XSL0305', self:GetArmy(), '/effects/emitters/seraphim_being_built_ambient_01_emit.bp' ) )
    end,

    OnScriptBitClear = function(self, bit)
        SLandUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            self:SetWeaponEnabledByLabel('SniperGun', false)
            self:SetWeaponEnabledByLabel('MainGun', true)
            self:GetWeaponManipulatorByLabel('MainGun'):SetHeadingPitch( self:GetWeaponManipulatorByLabel('SniperGun'):GetHeadingPitch() )
			--this is to remove the effect generated in sniper mode
			if self.ShieldEffectsBag then
                for k, v in self.ShieldEffectsBag do
                    v:Destroy()
                end
		        self.ShieldEffectsBag = {}
		    end
			self.ShieldEffectsBag = nil
        end
    end,
}

TypeClass = XSL0305
