-- Hook in for mod

-- This substitutes for the fact we don't have a blueprint filler. Yes, I know it's a mess.
HideTable = {
-- Here we define all units that need their vet removed, cos vet makes no sense for them
-- Units with no weapons get caught elsewhere, this is for exceptions like TMD
-- tracking in ShouldUseVetSystem

    --tmd
    uab4201 = true,
    ueb4201 = true,
    urb4201 = true,
    xsb4201 = true,
    
    --smd
    uab4302 = true,
    ueb4302 = true,
    urb4302 = true,
    xsb4302 = true,
    
    daa0206 = true,         --mercy

    xsl0402 = true,         -- Ion storm
    xea0002 = true,
    xsc9010 = true,         -- Novax jamming blips (jamming crystal units)
    xsc9011 = true,         -- Novax jamming blips (sera jamming crystal units)
    
    xrl0302 = true,         -- fire beetle
    xab1401 = true,         -- Paragon
    
}
