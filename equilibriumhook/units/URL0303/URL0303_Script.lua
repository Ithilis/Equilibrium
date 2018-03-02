-----------------------------------------------------------------
-- File     :  /cdimage/units/URL0303/URL0303_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Siege Assault Bot Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local Weapon = import('/lua/sim/Weapon.lua').Weapon
local cWeapons = import('/lua/cybranweapons.lua')
local BareBonesWeapon = import('/lua/sim/DefaultWeapons.lua').BareBonesWeapon
local CDFLaserDisintegratorWeapon = cWeapons.CDFLaserDisintegratorWeapon01
local CDFElectronBolterWeapon = cWeapons.CDFElectronBolterWeapon

local MissileRedirect = import('/lua/defaultantiprojectile.lua').MissileRedirect

local EMPDeathWeapon = Class(Weapon) {
    OnCreate = function(self)
        Weapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,

    Fire = function(self)
        local blueprint = self:GetBlueprint()
        DamageArea(self.unit, self.unit:GetPosition(), blueprint.DamageRadius,
                   blueprint.Damage, blueprint.DamageType, blueprint.DamageFriendly)
    end,
}

local OldURL0303 = URL0303

URL0303 = Class(OldURL0303) {

    Weapons = {
        Disintigrator = Class(CDFLaserDisintegratorWeapon) {},
        HeavyBolter = Class(CDFElectronBolterWeapon) {},
        DeathWeapon = Class(EMPDeathWeapon) {},
        MRedirect = Class(BareBonesWeapon) {
            OnFire = function(self)--EQ:Disable the weapon completely pretty much. Not like it ever worked.
            end,
        },
    },

    --dont hook this so it doesnt create the redirection entity twice
    OnStopBeingBuilt = function(self,builder,layer)
        CWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)
        local bp = self:GetBlueprint().Defense.AntiMissile
        local antiMissile = MissileRedirect {
            Owner = self,
            Radius = bp.Radius,
            AttachBone = bp.AttachBone,
            RedirectRateOfFire = bp.RedirectRateOfFire,
            Weapon = self:GetWeaponByLabel('MRedirect'),
        }
        self.Trash:Add(antiMissile)
    end,
}

TypeClass = URL0303
