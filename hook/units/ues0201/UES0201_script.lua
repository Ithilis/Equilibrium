--UEF Destroyer

local oldUES0201 = UES0201
UES0201 = Class(oldUES0201) {

    Weapons = {
        FrontTurret01 = Class(TDFGaussCannonWeapon) {},
        BackTurret01 = Class(TDFGaussCannonWeapon) {},
        FrontTurret02 = Class(TAALinkedRailgun) {},
        Torpedo01 = Class(TANTorpedoAngler) {},
        AntiTorpedo = Class(TIFSmartCharge) {},
        Torpedo02 = Class(TANTorpedoAngler) {},
    },

}

TypeClass = UES0201