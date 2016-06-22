--****************************************************************************
--**
--**  File     :  /cdimage/units/URS0202/URS0202_script.lua
--**  Author(s):  David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Cruiser Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CSeaUnit = import('/lua/cybranunits.lua').CSeaUnit
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CDFProtonCannonWeapon = CybranWeaponsFile.CDFProtonCannonWeapon
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon
local CAMZapperWeapon02 = CybranWeaponsFile.CAMZapperWeapon02
--local TargetingLaser = import('/mods/Equilibrium/lua/EQweapons.lua').DummyLaser --custom dummy weapon; completely invisible
local TargetingLaser = import('/lua/kirvesweapons.lua').TargetingLaser --cool looking targeting laser

URS0202 = Class(CSeaUnit) {
    Weapons = {
        ParticleGun = Class(CDFProtonCannonWeapon) {},
        AAGun = Class(CAANanoDartWeapon) {},
        GroundGun = Class(CAANanoDartWeapon) {},
        Zapper = Class(CAMZapperWeapon02) {},
		Lazor = Class(TargetingLaser) { -- we use this to toggle the aa weapons.
            FxMuzzleFlash = {},
            
            OnCreate = function(self)
               TargetingLaser.OnCreate(self)
               self.BeamType.FxBeam = {'/mods/Equilibrium/effects/emitters/dummybeam01.bp',}
            end,
            
            -- Unit in range. Cease ground fire and turn on AA
            OnWeaponFired = function(self)
                if not self.AA then
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false) --ensure all these labels are correct
                    self.unit:SetWeaponEnabledByLabel('AAGun', true)--ensure all these labels are correct
                    self.unit:GetWeaponManipulatorByLabel('AAGun'):SetHeadingPitch(self.unit:GetWeaponManipulatorByLabel('GroundGun'):GetHeadingPitch())
                    self.AA = true
                end
                TargetingLaser.OnWeaponFired(self)
            end,
            
            IdleState = State(TargetingLaser.IdleState) {
                -- Start with the AA gun off to reduce twitching of ground fire
                Main = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', true)--ensure all these labels are correct
                    self.unit:SetWeaponEnabledByLabel('AAGun', false)--ensure all these labels are correct
                    self.unit:GetWeaponManipulatorByLabel('GroundGun'):SetHeadingPitch(self.unit:GetWeaponManipulatorByLabel('AAGun'):GetHeadingPitch())
                    self.AA = false
                    TargetingLaser.IdleState.Main(self)
                end,
            },
            
        },
    },
    
}

TypeClass = URS0202