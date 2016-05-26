--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0104/URL0104_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Anti-Air Tank Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CLandUnit = import('/lua/cybranunits.lua').CLandUnit
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon
--local TargetingLaser = import('/mods/Equilibrium/lua/EQweapons.lua').DummyLaser --custom dummy weapon; completely invisible
local TargetingLaser = import('/lua/kirvesweapons.lua').TargetingLaser --cool looking targeting laser


URL0104 = Class(CLandUnit) {
    Weapons = {
		AAGun = Class(CAANanoDartWeapon) {},    
		Lazor = Class(TargetingLaser) {
            FxMuzzleFlash = {}, --turn off any default muzzle flash from defaultweapon, ect.
            
            -- Unit in range. Cease ground fire and turn on AA
            OnWeaponFired = function(self)
                if not self.AA then
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false)
                    self.unit:SetWeaponEnabledByLabel('AAGun', true)
                    self.unit:GetWeaponManipulatorByLabel('AAGun'):SetHeadingPitch(self.unit:GetWeaponManipulatorByLabel('GroundGun'):GetHeadingPitch())
                    self.AA = true
                end
                TargetingLaser.OnWeaponFired(self)
            end,
            
            IdleState = State(TargetingLaser.IdleState) {
                -- Start with the AA gun off to reduce twitching of ground fire
                Main = function(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', true)
                    self.unit:SetWeaponEnabledByLabel('AAGun', false)
                    self.unit:GetWeaponManipulatorByLabel('GroundGun'):SetHeadingPitch(self.unit:GetWeaponManipulatorByLabel('AAGun'):GetHeadingPitch())
                    self.AA = false
                    TargetingLaser.IdleState.Main(self)
                end,
            },
            
        },
        GroundGun = Class(CAANanoDartWeapon) {},
    },
    
}
TypeClass = URL0104

