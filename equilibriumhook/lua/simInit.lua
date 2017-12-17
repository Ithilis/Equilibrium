-- ==========================================================================================
-- * File       : lua/simInit.lua
-- * Authors    : Gas Powered Games, FAF Community, HUSSAR
-- * Summary    : This is the sim-specific top-level lua initialization file. It is run at initialization time to set up all lua state for the sim.
-- * Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ==========================================================================================

-- BeginSession will be called by the engine after the armies are created (but without
-- any units yet) and we're ready to start the game. It's responsible for setting up
-- the initial units and any other gameplay state we need.
-- EQ:this really should be hooked but havent got to it yet.
function BeginSession()
    LOG('BeginSession...')
    ForkThread(GameTimeLogger)
    local focusarmy = GetFocusArmy()
    if focusarmy>=0 and ArmyBrains[focusarmy] then
        LocGlobals.PlayerName = ArmyBrains[focusarmy].Nickname
    end

    -- Pass ScenarioInfo into OnPopulate() and OnStart() for backwards compatibility
    ScenarioInfo.Env.OnPopulate(ScenarioInfo)
    ScenarioInfo.Env.OnStart(ScenarioInfo)

    -- Look for teams
    local teams = {}
    for name,army in ScenarioInfo.ArmySetup do
        if army.Team > 1 then
            if not teams[army.Team] then
                teams[army.Team] = {}
            end
            table.insert(teams[army.Team],army.ArmyIndex)
        end
    end

    if ScenarioInfo.Options.TeamLock == 'locked' then
        -- Specify that the teams are locked.  Parts of the diplomacy dialog will
        -- be disabled.
        ScenarioInfo.TeamGame = true
        Sync.LockTeams = true
    end

    -- Set up the teams we found
    for team,armyIndices in teams do
        for k,index in armyIndices do
            for k2,index2 in armyIndices do
                SetAlliance(index,index2,"Ally")
            end
            ArmyBrains[index].RequestingAlliedVictory = true
        end
    end

    -- Create any effect markers on map
    local markers = import('/lua/sim/ScenarioUtilities.lua').GetMarkers()
    local Entity = import('/lua/sim/Entity.lua').Entity
    local EffectTemplate = import ('/lua/EffectTemplates.lua')
    if markers then
        for k, v in markers do
            if v.type == 'Effect' then
                local EffectMarkerEntity = Entity()
                Warp(EffectMarkerEntity, v.position)
                EffectMarkerEntity:SetOrientation(OrientFromDir(v.orientation), true)
                for k, v in EffectTemplate [v.EffectTemplate] do
                    CreateEmitterAtBone(EffectMarkerEntity,-2,-1,v):ScaleEmitter(v.scale or 1):OffsetEmitter(v.offset.x or 0, v.offset.y or 0, v.offset.z or 0)
                end
            end
        end
    end

    Sync.EnhanceRestrict = import('/lua/enhancementcommon.lua').GetRestricted()

    Sync.Restrictions = import('/lua/game.lua').GetRestrictions()

    --for off-map prevention
    OnStartOffMapPreventionThread()
	--EQ:start global seabed reveal
    OnStartSeabedRevealThread()

    if syncStartPositions then
        Sync.StartPositions = syncStartPositions
    end
end

-- EQ: forks a thread that resets unit vision after seabed units revealed themselves
function OnStartSeabedRevealThread()
    SeabedResetThread = ForkThread(import('/lua/ScenarioFramework.lua').WaterVisionResetThread)
    ScenarioInfo.SeabedRevealThreadAllowed = true
    WARN('success')
end
