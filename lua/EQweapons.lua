local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon

local CollisionBeamFile = import('/mods/Equilibrium/lua/EQbeams.lua')
 -- this points to Equilibrium. if you rename the mod folder this will break. moving this code requires this to be updated as well.
 -- todo: when moving this to release version replace Equilibrium with Equilibrium_Balance_Mod

DummyLaser = Class(DefaultBeamWeapon) { -- a completely invisible beam weapon. this uses a new collision beam - be sure to include that
    BeamType = CollisionBeamFile.DummyCollisionBeam,
    FxMuzzleFlash = {},
}

