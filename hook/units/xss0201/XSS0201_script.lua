--Seraphim Destroyer Script

local oldXSS0201 = XSS0201
XSS0201 = Class(oldXSS0201) {

    Weapons = {
        FrontTurret = Class(SDFUltraChromaticBeamGenerator) {},
        BackTurret = Class(SDFUltraChromaticBeamGenerator) {},
        Torpedo1 = Class(SANAnaitTorpedo) {},
        AntiTorpedo = Class(SDFAjelluAntiTorpedoDefense) {},
        Torpedo2 = Class(SANAnaitTorpedo) {},
    },

}
TypeClass = XSS0201