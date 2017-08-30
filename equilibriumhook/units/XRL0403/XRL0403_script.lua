-- ****************************************************************************
-- **
-- **  File     :  /units/XRL0403/XRL0403_script.lua
-- **
-- **  Summary  :  Megalith script
-- **
-- **  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************



local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CDFHvyProtonCannonWeapon = CybranWeaponsFile.CDFHvyProtonCannonWeapon
local CANNaniteTorpedoWeapon = CybranWeaponsFile.CANNaniteTorpedoWeapon
local CIFSmartCharge = CybranWeaponsFile.CIFSmartCharge
local CAABurstCloudFlakArtilleryWeapon = CybranWeaponsFile.CAABurstCloudFlakArtilleryWeapon
local CDFBrackmanCrabHackPegLauncherWeapon = CybranWeaponsFile.CDFBrackmanCrabHackPegLauncherWeapon
local SeabedRevealFile = import('/lua/SeabedReveal.lua') --import our intel relay entity code
local SeabedReveal = SeabedRevealFile.SeabedReveal --this part applies to the weapon
local SeabedRevealUnit = SeabedRevealFile.SeabedRevealUnit --this part applies to the unit

local oldXRL0403 = XRL0403

CDFHvyProtonCannonWeapon = SeabedReveal(CDFHvyProtonCannonWeapon) --inject our revealing code in here
oldXRL0403 = SeabedRevealUnit(oldXRL0403)

XRL0403 = Class(oldXRL0403) {
    WalkingAnimRate = 1.2,

    Weapons = {
        ParticleGunRight = Class(CDFHvyProtonCannonWeapon) {},
        ParticleGunLeft = Class(CDFHvyProtonCannonWeapon) {},
        Torpedo01 = Class(CANNaniteTorpedoWeapon) {},
        Torpedo02 = Class(CANNaniteTorpedoWeapon) {},
        Torpedo03 = Class(CANNaniteTorpedoWeapon) {},
        Torpedo04 = Class(CANNaniteTorpedoWeapon) {},
        AntiTorpedo = Class(CIFSmartCharge) {},
        AAGun = Class(CAABurstCloudFlakArtilleryWeapon) {},
        HackPegLauncher= Class(CDFBrackmanCrabHackPegLauncherWeapon){},
    },

}

TypeClass = XRL0403
