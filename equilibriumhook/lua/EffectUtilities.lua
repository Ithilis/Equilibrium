--****************************************************************************
--**
--**  File     :  /lua/EffectUtilities.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Effect Utility functions for scripts.
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

--we hook these to revert the effect changes to the cybran engies and build bots 
--for hives it makes it lag a lot less and for engies it makes them back to their intended look and more consistent too.
function SpawnBuildBots( builder, unitBeingBuilt, BuildEffectsBag, numBotOverride)
    -- Buildbots are scaled: ~ 1 pr 15 units of BP
    -- clamped to a max of 10 to avoid insane FPS drop
    -- with mods that modify BP
    
    local techToNumber = {
        EXPERIMENTAL = 5,
        SUBCOMMANDER = 5, 
        COMMAND = 3, 
        TECH1 = 1, 
        TECH2 = 2, 
        TECH3 = 3,
    }
    
    local numBots = numBotOverride or techToNumber[builder.techLevel] or 2 --EQ: we reset the number of bots to be according to tech level and not nonsense.

    if not builder.buildBots then
        builder.buildBots = {}
    end
	local builderArmy = builder:GetArmy()
    local unitBeingBuiltArmy = unitBeingBuilt:GetArmy()

    --if is new, won't spawn build bots if they might accidentally capture the unit
	if builderArmy == unitBeingBuiltArmy or IsHumanUnit(unitBeingBuilt) then
        for k, b in builder.buildBots do
            if b:BeenDestroyed() then
                builder.buildBots[k] = nil
            end
        end

        local numUnits = numBots - table.getsize(builder.buildBots)
        if numUnits > 0 then
            local x, y, z = unpack(builder:GetPosition())
            local qx, qy, qz, qw = unpack(builder:GetOrientation())
            local angleInitial = 180
            local VecMul = 0.5
            local xVec = 0
            local yVec = builder:GetBlueprint().SizeY * 0.5
            local zVec = 0

            local angle = (2*math.pi) / numUnits

            -- Launch projectiles at semi-random angles away from the sphere, with enough
            -- initial velocity to escape sphere core
            for i = 0, (numUnits - 1) do
                xVec = math.sin(angleInitial + (i*angle)) * VecMul
                zVec = math.cos(angleInitial + (i*angle)) * VecMul
                local bot = CreateUnit('ura0001', builderArmy, x + xVec, y + yVec, z + zVec, qx, qy, qz, qw, 'Air' )

                -- Make build bots unkillable
                bot:SetCanTakeDamage(false)
                bot:SetCanBeKilled(false)
                bot.spawnedBy = builder

                table.insert(builder.buildBots, bot)
            end
        end

        for _, bot in builder.buildBots do
            ChangeState(bot, bot.BuildState)
        end

        return builder.buildBots
	end
end