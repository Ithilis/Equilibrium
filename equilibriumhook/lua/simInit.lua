-- ==========================================================================================
-- * File       : lua/simInit.lua
-- * Authors    : Gas Powered Games, FAF Community, HUSSAR
-- * Summary    : This is the sim-specific top-level lua initialization file. It is run at initialization time to set up all lua state for the sim.
-- * Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ==========================================================================================

-- BeginSession will be called by the engine after the armies are created (but without
-- any units yet) and we're ready to start the game. It's responsible for setting up
-- the initial units and any other gameplay state we need.
-- EQ: forks a thread that resets unit vision after seabed units revealed themselves
local oldBeginSession = BeginSession

function BeginSession()
    oldBeginSession()
    SeabedResetThread = ForkThread(import('/lua/ScenarioFramework.lua').WaterVisionResetThread)
end
