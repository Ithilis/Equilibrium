local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon

local CollisionBeamFile = import('/mods/Equilibrium_Balance_Mod/lua/EQbeams.lua')
 -- this points to Equilibrium. if you rename the mod folder this will break. moving this code requires this to be updated as well.

DummyLaser = Class(DefaultBeamWeapon) { -- a completely invisible beam weapon. this uses a new collision beam - be sure to include that
    BeamType = CollisionBeamFile.DummyCollisionBeam,
    FxMuzzleFlash = {},
}

