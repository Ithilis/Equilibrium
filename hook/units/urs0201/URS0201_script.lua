--Cybran Destroyer Script

local oldURS0201 = URS0201
URS0201 = Class(oldURS0201) {

    Weapons = {
        ParticleGun = Class(CDFProtonCannonWeapon) {},
        AAGun = Class(CAAAutocannon) {},
        TorpedoR = Class(CANNaniteTorpedoWeapon) {},
        TorpedoL = Class(CANNaniteTorpedoWeapon) {},
        AntiTorpedoF = Class(CIFSmartCharge) {},
        AntiTorpedoB = Class(CIFSmartCharge) {},
        TorpedoR = Class(CANNaniteTorpedoWeapon) {},
        TorpedoL = Class(CANNaniteTorpedoWeapon) {},
    },

}

TypeClass = URS0201
