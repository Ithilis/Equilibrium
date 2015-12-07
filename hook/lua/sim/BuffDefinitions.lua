-- Hook in for mod

-- Table of multipliers used by the mass-driven veterancy system
-- Subsection key:
--      1 = COMBAT
--      2 = RAIDER
--      3 = SHIP
--      4 = SUB
--      5 = SCU and EXPERIMENTAL
--      6 = ACU
MultsTable = {
    VETERANCYREGEN = {
        TECH1 = {
            {0.5, 1.5, 3, 5, 7.5},
            1,
            {1, 3, 6, 10, 15},
            2,
        },
        TECH2 = {
            {1, 3, 6, 10, 15},
            2,
            {2, 6, 12, 20, 30},
            3,
        },
        TECH3 = {
            {1.5, 4.5, 9, 15, 22.5},
            3,
            {6, 18, 36, 60, 90},
            6,
        },
        EXPERIMENTAL = {5, 15, 30, 50, 75},
        COMMAND = 5,
        SUBCOMMANDER = {2, 6, 12, 20, 30},
    },
    VETERANCYMAXHEALTH = {
        TECH1 = 1.2,
        TECH2 = 1.2,
        TECH3 = 1.15,            --> big risk to be too dangerous, promote use T2 units
        EXPERIMENTAL = 1.1,        --> because mass mult for vet lvl is 50% own mass
        COMMAND = 1.2,
        SUBCOMMANDER = 1.15,
    },
}

-- This substitutes for the fact we don't have a blueprint filler. Yes, I know it's a mess.
TypeTable = {
-- This first section, the unit's don't have a type, but are here to register they need veterancy
-- tracking in OnStopBeingBuilt
    ual0001 = 6,
    uel0001 = 6,
    url0001 = 6,
    xsl0001 = 6,
    
    ual0301 = 5,
    uel0301 = 5,
    url0301 = 5,
    xsl0301 = 5,
    
    ual0301_Engineer = 5,
    ual0301_NanoCombat = 5,
    ual0301_RAS = 5,
    ual0301_Rambo = 5,
    ual0301_ShieldCombat = 5,
    ual0301_SimpleCombat = 5,
     
    uel0301_BubbleShield = 5,
    uel0301_Combat = 5,
    uel0301_Engineer = 5,
    uel0301_IntelJammer = 5,
    uel0301_RAS = 5,
    uel0301_Rambo = 5,
     
    url0301_AntiAir = 5,
    url0301_Cloak = 5,
    url0301_Combat = 5,
    url0301_Engineer = 5,
    url0301_RAS = 5,
    url0301_Rambo = 5,
    url0301_Stealth = 5,
     
    xsl0301_AdvancedCombat = 5,
    xsl0301_Combat = 5,
    xsl0301_Engineer = 5,
    xsl0301_Missile = 5,
    xsl0301_NanoCombat = 5,
    xsl0301_Rambo = 5,
    
    xab1401 = 5,
    uaa0310 = 5,
    ual0401 = 5,
    uas0401 = 5,
    ueb2401 = 5,
    uel0401 = 5,
    ues0401 = 5,
    ura0401 = 5,
    url0402 = 5,
    url0401 = 5,
    xrl0403 = 5,
    xsb2401 = 5,
    xsa0402 = 5,
    xsl0401 = 5,
    xsl0402 = 5,        -- Ion storm
    xea0002 = 5,
    
-- Now for the units which do need typing
-- COMBAT
    -- PD
    uab2101 = 1,
    ueb2101 = 1,
    urb2101 = 1,
    xsb2101 = 1,
    uab2301 = 1,
    ueb2301 = 1,
    urb2301 = 1,
    xsb2301 = 1,
    xeb2306 = 1,
    -- AA
    uab2104 = 1,
    ueb2104 = 1,
    urb2104 = 1,
    xsb2104 = 1,
    uab2204 = 1,
    ueb2204 = 1,
    urb2204 = 1,
    xsb2204 = 1,
    uab2304 = 1,
    ueb2304 = 1,
    urb2304 = 1,
    xsb2304 = 1,
    -- Torp
    uab2109 = 1,
    ueb2109 = 1,
    urb2109 = 1,
    xsb2109 = 1,
    uab2205 = 1,
    ueb2205 = 1,
    urb2205 = 1,
    xsb2205 = 1,
    xrb2308 = 1,
    -- T2 Arty
    uab2303 = 1,
    ueb2303 = 1,
    urb2303 = 1,
    xsb2303 = 1,
    -- T3 Arty
    uab2302 = 1,
    ueb2302 = 1,
    urb2302 = 1,
    xsb2302 = 1,
    xab2307 = 1,
    -- Nukes
    uab2305 = 1,
    ueb2305 = 1,
    urb2305 = 1,
    xsb2305 = 1,
    -- TML
    uab2108 = 1,
    ueb2108 = 1,
    urb2108 = 1,
    xsb2108 = 1,
    -- Tanks
    ual0201 = 1,
    uel0201 = 1,
    url0107 = 1,
    xsl0201 = 1,
    ual0202 = 1,
    uel0202 = 1,
    url0202 = 1,
    xsl0202 = 1,
    xrl0302 = 1, -- fire beetle
    ual0303 = 1,
    xel0305 = 1,
    xrl0305 = 1,
    xsl0303 = 1,
    -- Mobile Arty
    ual0103 = 1,
    uel0103 = 1,
    url0103 = 1,
    xsl0103 = 1,
    ual0111 = 1,
    uel0111 = 1,
    url0111 = 1,
    xsl0111 = 1,
    ual0304 = 1,
    uel0304 = 1,
    url0304 = 1,
    xsl0304 = 1,
    xel0306 = 1,
    dal0310 = 1,
    -- MAA
    ual0104 = 1,
    uel0104 = 1,
    url0104 = 1,
    xsl0104 = 1,
    ual0205 = 1,
    uel0205 = 1,
    url0205 = 1,
    xsl0205 = 1,
    drlk001 = 1,
    dslk004 = 1,
    dalk003 = 1,
    delk002 = 1,    
    -- Intie
    uaa0102 = 1,
    uea0102 = 1,
    ura0102 = 1,
    xsa0102 = 1,
    xaa0202 = 1,
    -- ASF
    uaa0303 = 1,
    uea0303 = 1,
    ura0303 = 1,
    xsa0303 = 1,
    -- T2 F/B
    dea0202 = 1,
    dra0202 = 1,
    xsa0202 = 1,
    -- T1 Gunship
    xra0105 = 1,
    -- T2 Gunship
    uaa0203 = 1,
    uea0203 = 1,
    ura0203 = 1,
    xsa0203 = 1,
    -- T3 Gunship
    xaa0305 = 1,
    xra0305 = 1,
    uea0305 = 1,
    
-- RAIDER
    -- Land Scout
    ual0101 = 2,
    uel0101 = 2,
    -- LAB
    ual0106 = 2,
    uel0106 = 2,
    url0106 = 2,
    xsl0101 = 2,
    -- Hovertanks
    xal0203 = 2,
    uel0203 = 2,
    url0203 = 2,
    xsl0203 = 2,
    -- T2 Range Bots
    drl0204 = 2,
    del0204 = 2,
    -- T3 Raid Bots
    url0303 = 2,
    uel0303 = 2,
    -- T3 Sniper bots
    xal0305 = 2,
    xsl0305 = 2,
    -- Bomber
    uaa0103 = 2,
    uea0103 = 2,
    ura0103 = 2,
    xsa0103 = 2,
    -- Strats
    uaa0304 = 2,
    uea0304 = 2,
    ura0304 = 2,
    xsa0304 = 2,
    -- Transports
    uaa0104 = 2,
    uea0104 = 2,
    ura0104 = 2,
    xsa0104 = 2,
    xea0306 = 2,
    -- Torp Bombers
    uaa0204 = 2,
    uea0204 = 2,
    ura0204 = 2,
    xsa0204 = 2,
    xaa0306 = 2,
    
-- SHIP
    uas0102 = 3,
    uas0103 = 3,
    ues0103 = 3,
    urs0103 = 3,
    xss0103 = 3,
    uas0201 = 3,
    ues0201 = 3,
    urs0201 = 3,
    xss0201 = 3,
    uas0202 = 3,
    ues0202 = 3,
    urs0202 = 3,
    xss0202 = 3,
    xes0102 = 3,
    uas0302 = 3,
    ues0302 = 3,
    urs0302 = 3,
    xss0302 = 3,
    uas0303 = 3,
    urs0303 = 3,
    xss0303 = 3,
    xas0306 = 3,
    xes0307 = 3,
-- SUB
    uas0203 = 4,
    ues0203 = 4,
    urs0203 = 4,
    xss0203 = 4,
    xas0204 = 4,
    xrs0204 = 4,
    xss0304 = 4,
    uas0304 = 4,
    ues0304 = 4,
    urs0304 = 4,
    
 -- VOLATILE BUILDINGS (preventing bug where buildings don't leave wreck after death)
    uab1105 = 1,
    ueb1105 = 1,
    urb1105 = 1,
    xsb1105 = 1,
    
    uab1106 = 1,
    ueb1106 = 1,
    urb1106 = 1,
    xsb1106 = 1,
    
    uab1101 = 1,
    ueb1101 = 1,
    urb1101 = 1,
    xsb1101 = 1,
    
    uab1201 = 1,
    ueb1201 = 1,
    urb1201 = 1,
    xsb1201 = 1,
    
    uab1301 = 1,
    ueb1301 = 1,
    urb1301 = 1,
    xsb1301 = 1,
    
    uab1104 = 1,
    ueb1104 = 1,
    urb1104 = 1,
    xsb1104 = 1,
    
    uab1303 = 1,
    ueb1303 = 1,
    urb1303 = 1,
    xsb1303 = 1,
    
    xab1401 = 1,
    
}
