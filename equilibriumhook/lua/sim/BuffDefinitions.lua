-- Hook in for mod

-- Table of multipliers used by the mass-driven veterancy system
MultsTable = {
    VETERANCYREGEN = {
        TECH1 = 1,
        TECH2 = 2.5,
        TECH3 = 5,
        SUBCOMMANDER = 10,
        EXPERIMENTAL = 20,
        COMMAND = 5,
    },
    VETERANCYMAXHEALTH = {
        TECH1 = 1.15,
        TECH2 = 1.15,
        TECH3 = 1.15,
        EXPERIMENTAL = 1.15,
        COMMAND = 1.15,
        SUBCOMMANDER = 1.15, 
    },
}


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
