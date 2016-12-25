    -----------------------------------------------------------
    -- Cloak visual effects, made by OrangeKnight, Lt_Hawkeye, and Exavier Macbeth, taken from the BlackOps mod
    -----------------------------------------------------------

do
    function ExtractCloakMeshBlueprint(bp)
        local meshid = bp.Display.MeshBlueprint
        if not meshid then return end

        local meshbp = original_blueprints.Mesh[meshid]
        if not meshbp then return end

        local shadernameE = 'ShieldCybran'
        local shadernameA = 'ShieldAeon'
        local shadernameC = 'ShieldCybran'
        local shadernameS = 'ShieldAeon'

        local cloakmeshbp = table.deepcopy(meshbp)
        if cloakmeshbp.LODs then
            for i,cat in bp.Categories do
            if cat == 'UEF' then
                for i,lod in cloakmeshbp.LODs do
                    lod.ShaderName = shadernameE
                end
            elseif cat == 'AEON' then
                for i,lod in cloakmeshbp.LODs do
                    lod.ShaderName = shadernameA
                end
            elseif cat == 'CYBRAN' then
                for i,lod in cloakmeshbp.LODs do
                    lod.ShaderName = shadernameC
                end
            elseif cat == 'SERAPHIM' then
                for i,lod in cloakmeshbp.LODs do
                    lod.ShaderName = shadernameS
                end
            end
            end
        end
        cloakmeshbp.BlueprintId = meshid .. '_cloak'
        bp.Display.CloakMeshBlueprint = cloakmeshbp.BlueprintId
        MeshBlueprint(cloakmeshbp)
    end
    
--------------------------------------------------------------------------------
-- Define splashy above water weapons as normalabovewater                                                                                
-- Modded By: Balthazar
--------------------------------------------------------------------------------
    
function WaterGuard(bp)
        if table.find(bp.Categories, 'SELECTABLE') and bp.Weapon then
            for i, weap in bp.Weapon do
                if weap.AboveWaterTargetsOnly and weap.DamageRadius and weap.DamageRadius > 1 and weap.DamageType == 'Normal' then
                    weap.DamageType = 'NormalAboveWater'
                end 
            end 
        end
end
    
    local OldModBlueprints = ModBlueprints
    function ModBlueprints(all_blueprints)
        OldModBlueprints(all_blueprints)
        for id,bp in all_blueprints.Unit do
            ExtractCloakMeshBlueprint(bp)
            WaterGuard(bp)
            if table.find(bp.Categories, 'SUBCOMMANDER') then
                table.insert(bp.Categories, 'ANTITELEPORT')
            end
            if bp.Weapon then
                for ik, wep in bp.Weapon do
                    if wep.RangeCategory == 'UWRC_AntiAir' then
                        if not wep.AntiSat == true then
                            wep.TargetRestrictDisallow = wep.TargetRestrictDisallow .. ', SATELLITE'
                        end
                    end
                end
            end
        end
    end
    
end