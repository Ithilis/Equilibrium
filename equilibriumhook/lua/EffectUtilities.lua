--****************************************************************************
--**
--**  File     :  /lua/EffectUtilities.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Effect Utility functions for scripts.
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local util = import('utilities.lua')
local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat


function PlayTeleportChargingEffects( unit, TeleportDestination, EffectsBag )
    -- plays teleport effects for the given unit
    if not unit then
        return
    end

    local army = unit:GetArmy()
    local bp = unit:GetBlueprint()
    local faction = bp.General.FactionName
    local Yoffset = TeleportGetUnitYOffset(unit)

    TeleportDestination = TeleportLocationToSurface( TeleportDestination )

    if bp.Display.TeleportEffects.PlayChargeFxAtUnit ~= false then                            -- FX AT UNIT

        unit:PlayUnitAmbientSound('TeleportChargingAtUnit')

        if faction == 'UEF' then                                                              -------- UEF --------

            -- unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, unit.TeleportChargeFxAtUnitOverride or EffectTemplate.UEFTeleportCharge02, EffectsBag)
            
            -- Equilibrium - we recycle the teleport in effects since they are way more epic, and add a modified steam effect as well.
            unit.TeleportChargeBag = {}
            local templ = unit.TeleportChargeFxAtDestOverride or EffectTemplate.UEFTeleportCharge02
            for k, v in templ do
                local fx = CreateEmitterAtEntity(unit, army,v):OffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.75)
                fx:SetEmitterCurveParam('Y_POSITION_CURVE', 0, Yoffset * 2)  -- to make effects cover entire height of unit
                fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', 1, 0)  -- small initial rotation, will be faster as charging
                table.insert( unit.TeleportChargeBag, fx)
                EffectsBag:Add(fx)
            end
            
            local totalBones = unit:GetBoneCount() - 1
            for k, v in EffectTemplate.UnitTeleportSteam01 do
                for bone = 1, totalBones do
                    local emitter = CreateAttachedEmitter(unit,bone,army, v):SetEmitterParam( 'Lifetime', 9999 )
                    -- Equilibrium - adjust the lifetime so we always teleport before its done
                    
                    table.insert( unit.TeleportChargeBag, emitter) --add our fx to trash so they disappear when we stop teleport
                    EffectsBag:Add(emitter)
                end
            end
            
            

        elseif faction == 'Cybran' then                                                       -------- CYBRAN --------

            -- Creating teleport fx at unit location
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, unit.TeleportChargeFxAtUnitOverride or EffectTemplate.CybranTeleportCharge01, EffectsBag)

        elseif faction == 'Seraphim' then                                                     -------- SERAPHIM --------

            -- Creating teleport fx at unit location
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, unit.TeleportChargeFxAtUnitOverride or EffectTemplate.SeraphimTeleportCharge01, EffectsBag)

        else  -- Aeon or other factions                                                        -------- AEON --------

            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, unit.TeleportChargeFxAtUnitOverride or EffectTemplate.GenericTeleportCharge01, EffectsBag)

        end
    end

    if bp.Display.TeleportEffects.PlayChargeFxAtDestination ~= false then                     -- FX AT DESTINATION
        -- customized version of PlayUnitAmbientSound() from unit.lua to play sound at target destination
        local sound = 'TeleportChargingAtDestination'
        local sndEnt = false
        unit.TeleportSoundChargeBag = {}
        if sound and bp.Audio[sound] then
            if not unit.AmbientSounds then
                unit.AmbientSounds = {}
            end
            if not unit.AmbientSounds[sound] then
                
                sndEnt = Entity {}
                unit.AmbientSounds[sound] = sndEnt
                unit.Trash:Add(sndEnt)
                Warp( sndEnt, TeleportDestination )  -- warping sound entity to destination so ambient sound plays there (and not at unit)
                table.insert( unit.TeleportSoundChargeBag, sndEnt) -- Equilibrium - adding sound to trash so it actually goes away if we cancel/teleport
            end
            unit.AmbientSounds[sound]:SetAmbientSound( bp.Audio[sound], nil )
        end

        if faction == 'UEF' then
            -- using a barebone entity to position effects, it is destroyed afterwards
            local TeleportDestFxEntity = Entity()
            Warp(TeleportDestFxEntity, TeleportDestination)

            unit.TeleportDestChargeBag = {}
            local templ = unit.TeleportChargeFxAtDestOverride or EffectTemplate.UEFTeleportCharge02
            for k, v in templ do
                local fx = CreateEmitterAtEntity(TeleportDestFxEntity, army,v):OffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.75)
                fx:SetEmitterCurveParam('Y_POSITION_CURVE', 0, Yoffset * 2)  -- to make effects cover entire height of unit
                fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', 1, 0)  -- small initial rotation, will be faster as charging
                table.insert( unit.TeleportDestChargeBag, fx)
                EffectsBag:Add(fx)
            end

        elseif faction == 'Cybran' then                                                       -------- CYBRAN --------

            local pos = table.copy( TeleportDestination )
            pos[2] = pos[2] + Yoffset   -- make sure sphere isn't half in the ground
            local sphere = TeleportCreateCybranSphere(unit, pos, 0.01)

            unit.TeleportDestChargeBag = {}
            local templ = unit.TeleportChargeFxAtDestOverride or EffectTemplate.CybranTeleportCharge02
            for k, v in templ do
                local fx = CreateEmitterAtEntity( sphere, army, v )
                fx:ScaleEmitter(0.01 * unit.TeleportCybranSphereScale)
                table.insert( unit.TeleportDestChargeBag, fx)
                EffectsBag:Add(fx)
            end

        elseif faction == 'Seraphim' then                                                     -------- SERAPHIM --------

            -- using a barebone entity to position effects, it is destroyed afterwards
            local TeleportDestFxEntity = Entity()
            Warp( TeleportDestFxEntity, TeleportDestination )

            unit.TeleportDestChargeBag = {}
            local templ = unit.TeleportChargeFxAtDestOverride or EffectTemplate.SeraphimTeleportCharge02
            for k, v in templ do
                local fx = CreateEmitterAtEntity( TeleportDestFxEntity, army, v ):OffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.01)
                table.insert( unit.TeleportDestChargeBag, fx)
                EffectsBag:Add(fx)
            end

            TeleportDestFxEntity:Destroy()

        else  -- Aeon or other factions                                                        -------- AEON --------

            -- using a barebone entity to position effects, it is destroyed afterwards
            local TeleportDestFxEntity = Entity()
            Warp( TeleportDestFxEntity, TeleportDestination )

            unit.TeleportDestChargeBag = {}
            local templ = unit.TeleportChargeFxAtDestOverride or EffectTemplate.GenericTeleportCharge02
            for k, v in templ do
                local fx = CreateEmitterAtEntity( TeleportDestFxEntity, army, v ):OffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.01)
                table.insert( unit.TeleportDestChargeBag, fx)
                EffectsBag:Add(fx)
            end

            TeleportDestFxEntity:Destroy()

        end
    end
end

function TeleportChargingProgress(unit, fraction)

    local bp = unit:GetBlueprint()

    if bp.Display.TeleportEffects.PlayChargeFxAtDestination ~= false then

        fraction = math.min(math.max(fraction, 0.01), 1)
        local faction = bp.General.FactionName

        if faction == 'UEF' then
            -- increase rotation of effects as progressing

            if unit.TeleportDestChargeBag then
                local scale = 0.75 + (0.5 * math.max( fraction, 0.01 ))
                for k, fx in unit.TeleportDestChargeBag do
                    fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', -(25 + (100 * fraction)), (30 * fraction) )
                    fx:ScaleEmitter(scale)
                end
                for k, fx in unit.TeleportChargeBag do
                    fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', -(25 + (100 * fraction)), (30 * fraction) )
                    fx:ScaleEmitter(scale)
                end
            end

        elseif faction == 'Cybran' then
            -- increase size of sphere and effects as progressing

            local scale = math.max( fraction, 0.01 ) * (unit.TeleportCybranSphereScale or 5)
            if unit.TeleportCybranSphere then
                unit.TeleportCybranSphere:SetDrawScale(scale)
            end
            if unit.TeleportDestChargeBag then
                for k, fx in unit.TeleportDestChargeBag do
                   fx:ScaleEmitter(scale)
                end
            end

        elseif unit.TeleportDestChargeBag then
            -- increase size of effects as progressing

            local scale = (2 * fraction) - math.pow(fraction, 2)
            for k, fx in unit.TeleportDestChargeBag do
               fx:ScaleEmitter(scale)
            end

        end
    end
end


function PlayTeleportInEffects(unit, EffectsBag)
    -- Fired when the unit is being teleported, just after the unit is taken from its original location

    local bp = unit:GetBlueprint()
    local faction = bp.General.FactionName
    local army = unit:GetArmy()
    local Yoffset = TeleportGetUnitYOffset(unit)

    DoTeleportInDamage(unit)  -- fire teleport weapon

    if bp.Display.TeleportEffects.PlayTeleportInFx ~= false then

        unit:PlayUnitSound('TeleportIn')

        if faction == 'UEF' then

            local templ = unit.TeleportInFxOverride or EffectTemplate.UEFTeleportIn01
            for k, v in templ do
                CreateEmitterAtEntity(unit,army,v):OffsetEmitter(0, Yoffset, 0)
            end

            local decalOrient = RandomFloat(0,2*math.pi)
            CreateDecal(unit:GetPosition(), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, army)

            local fn = function(unit)
                local bp = unit:GetBlueprint()
                local MeshExtentsY = (bp.Physics.MeshExtentsY or 1)

                CreateLightParticle( unit, -1, army, 4, 10, 'glow_03', 'ramp_yellow_01' )
                DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                WaitSeconds(0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                local totalBones = unit:GetBoneCount() - 1
                for k, v in EffectTemplate.UnitTeleportSteam01 do
                    for bone = 1, totalBones do
                        CreateAttachedEmitter(unit,bone,army, v)
                    end
                end
            end

            local thread = unit:ForkThread(fn)
            -- Don't add this thread to the effects bag or the unit might be manipulated into becoming invisible: thread is deleted before it
            -- can make the unit visible again.
            --EffectsBag:Add(thread)

        elseif faction == 'Cybran' then

            if not unit.TeleportCybranSphere then
                local pos = TeleportLocationToSurface( table.copy(unit:GetPosition()) )
                pos[2] = pos[2] + Yoffset
                unit.TeleportCybranSphere = TeleportCreateCybranSphere(unit, pos)
            end

            local templ = unit.TeleportInFxOverride or EffectTemplate.CybranTeleportIn01
            local scale = unit.TeleportCybranSphereScale or 5
            for k, v in templ do
                CreateEmitterAtEntity(unit.TeleportCybranSphere,army,v):ScaleEmitter(scale)
            end

            CreateLightParticle( unit.TeleportCybranSphere, -1, army, 4, 10, 'glow_02', 'ramp_white_01' )
            DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

            local decalOrient = RandomFloat(0,2*math.pi)
            CreateDecal(unit:GetPosition(), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, army)

            local fn = function(unit)

                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                WaitSeconds(0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                WaitSeconds(0.8)

                if unit.TeleportCybranSphere then
                    unit.TeleportCybranSphere:Destroy()
                    unit.TeleportCybranSphere = false
                end

                local totalBones = unit:GetBoneCount() - 1
                for k, v in EffectTemplate.UnitTeleportSteam01 do
                    for bone = 1, totalBones do
                        CreateAttachedEmitter(unit,bone,army, v)
                    end
                end
            end

            local thread = unit:ForkThread(fn)
            -- Don't add this thread to the effects bag or the unit might be manipulated into becoming invisible: thread is deleted before it
            -- can make the unit visible again.
            --EffectsBag:Add(thread)

        elseif faction == 'Seraphim' then

            local fn = function(unit)

                local bp = unit:GetBlueprint()
                local Yoffset = TeleportGetUnitYOffset(unit)

                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                local templ = unit.TeleportInFxOverride or EffectTemplate.SeraphimTeleportIn01
                for k, v in templ do
                    CreateEmitterAtEntity(unit, army, v):OffsetEmitter(0, Yoffset, 0)
                end

                CreateLightParticle( unit, -1, army, 4, 15, 'glow_05', 'ramp_jammer_01' )
                DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

                local decalOrient = RandomFloat(0,2*math.pi)
                CreateDecal(unit:GetPosition(), decalOrient, 'crater01_albedo', '', 'Albedo', 4, 4, 200, 300, army)
                CreateDecal(unit:GetPosition(), decalOrient, 'crater01_normals', '', 'Normals', 4, 4, 200, 300, army)

                WaitSeconds (0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                WaitSeconds (0.25)

                for k, v in EffectTemplate.SeraphimTeleportIn02 do
                    CreateEmitterAtEntity(unit, army, v):OffsetEmitter(0, Yoffset, 0)
                end
                
                local totalBones = unit:GetBoneCount() - 1 --the steam effect is so epic everyone deserves it
                for k, v in EffectTemplate.UnitTeleportSteam01 do
                    for bone = 1, totalBones do
                        CreateAttachedEmitter(unit,bone,army, v)
                    end
                end
            end
            

            local thread = unit:ForkThread(fn)
            -- Don't add this thread to the effects bag or the unit might be manipulated into becoming invisible: thread is deleted before it
            -- can make the unit visible again.
            --EffectsBag:Add(thread)

        else  -- Aeon or other factions

            local templ = unit.TeleportInFxOverride or EffectTemplate.GenericTeleportIn01
            for k, v in templ do
                CreateEmitterAtEntity(unit,army,v):OffsetEmitter(0, Yoffset, 0)
            end

            DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

            local decalOrient = RandomFloat(0,2*math.pi)
            CreateDecal(unit:GetPosition(), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, army)
            
            local totalBones = unit:GetBoneCount() - 1 --the steam effect is so epic everyone deserves it
            for k, v in EffectTemplate.UnitTeleportSteam01 do
                for bone = 1, totalBones do
                    CreateAttachedEmitter(unit,bone,army, v)
                end
            end
        end
    end
end

function DestroyTeleportChargingEffects(unit, EffectsBag)
    -- called when charging up is done (because succesfull or cancelled)
    if unit.TeleportChargeBag then
        for keys,values in unit.TeleportChargeBag do
            values:Destroy()
        end
        unit.TeleportChargeBag = {}
    end
    if unit.TeleportDestChargeBag then
        for keys,values in unit.TeleportDestChargeBag do
            values:Destroy()
        end
        unit.TeleportDestChargeBag = {}
    end
    if unit.TeleportSoundChargeBag then -- Equilibrium - emptying the sounds so they stop.
        for keys,values in unit.TeleportSoundChargeBag do
            values:Destroy()
        end
        if unit.AmbientSounds then
            unit.AmbientSounds = {} --for some reason we couldnt simply add this to trash so empyting it like this
        end
        unit.TeleportSoundChargeBag = {}
    end
    
    
    EffectsBag:Destroy()

    unit:StopUnitAmbientSound('TeleportChargingAtUnit')
    unit:StopUnitAmbientSound('TeleportChargingAtDestination')
end
