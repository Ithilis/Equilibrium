-- Hook in for mod

-- Table of multipliers used by the mass-driven veterancy system
MultsTable = {
    VETERANCYREGEN = {
        TECH1 = 1,
        TECH2 = 3,
        TECH3 = 6,
        SUBCOMMANDER = 9,
        EXPERIMENTAL = 12,
        COMMAND = 5, -- the acu is important to be like this to preserve gameplay
    },
    VETERANCYMAXHEALTH = {
        TECH1 = 1.1,
        TECH2 = 1.1,
        TECH3 = 1.1,
        EXPERIMENTAL = 1.1,
        COMMAND = 1.15, -- the acu is important to be like this to preserve gameplay
        SUBCOMMANDER = 1.15, --sacu should be different too because its special and not some Lame t3.5 unit
    },
}

--for Ithilis: if you put every single unit which needs to be hidden in here, we get slightly faster code :D

-- This substitutes for the fact we don't have a blueprint filler. Yes, I know it's a mess.
HideTable = {
-- Here we define all units that need their veterancy bars hidden, cos vet makes no sense for them
-- Units with no weapons get caught elsewhere, this is for exceptions like TMD
-- tracking in OnStopBeingBuilt

--need to add: smd
--paragon
    
    --tmd
    uab4201 = true,
    ueb4201 = true,
    urb4201 = true,
    xsb4201 = true,
    
    daa0206 = true,         --mercy

    xsl0402 = true,         -- Ion storm
    xea0002 = true,
    xsc9010 = true,         -- Novax jamming blips (jamming crystal units)
    xsc9011 = true,         -- Novax jamming blips (sera jamming crystal units)
    
    xrl0302 = true,         -- fire beetle
    
}
