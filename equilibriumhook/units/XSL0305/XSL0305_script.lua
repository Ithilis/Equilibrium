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
        
        --we store our weapon ranges here so we dont have to access bp every time we swap. less laggy that way.
        local bp = self:GetBlueprint().Weapon
        self.SniperRange = bp[1].MaxRadius
        self.CloseRange = bp[2].MaxRadius
    end,

    OnScriptBitSet = function(self, bit)
        SLandUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            self:SetWeaponEnabledByLabel('SniperGun', true)
            self:SetWeaponEnabledByLabel('MainGun', false)
            self:GetWeaponManipulatorByLabel('SniperGun'):SetHeadingPitch( self:GetWeaponManipulatorByLabel('MainGun'):GetHeadingPitch() )
		
            --here we adjust the range of our dummy weapon to our active one so you cant give an attack order outside the snipers range and have it not go there
            local wep = self:GetWeaponByLabel('TargetTracker')
            wep:ChangeMaxRadius(self.SniperRange or 75)
            
            ---This is to add a visual que that the sniper is in sniper mode
            self.ShieldEffectsBag = {}
            table.insert( self.ShieldEffectsBag, CreateAttachedEmitter( self, 'XSL0305', self:GetArmy(), '/effects/emitters/seraphim_being_built_ambient_01_emit.bp' ) )
        
        end
    end,

    OnScriptBitClear = function(self, bit)
        SLandUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            self:SetWeaponEnabledByLabel('SniperGun', false)
            self:SetWeaponEnabledByLabel('MainGun', true)
            self:GetWeaponManipulatorByLabel('MainGun'):SetHeadingPitch( self:GetWeaponManipulatorByLabel('SniperGun'):GetHeadingPitch() )
		
            --here we adjust the range of our dummy weapon to our active one so you cant give an attack order outside the snipers range and have it not go there
            local wep = self:GetWeaponByLabel('TargetTracker')
            wep:ChangeMaxRadius(self.CloseRange or 38)
        
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
