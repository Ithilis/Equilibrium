
do
    
--------------------------------------------------------------------------------
-- Define splashy above water weapons as NormalAboveWater                                                                                
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
            WaterGuard(bp)
            
            -- skip units without categories
            if not bp.Categories then
                continue
            end
            
            --enable stealth for all transportables, and add a special flag so we know about this
            if bp.CategoriesHash.LAND and bp.CategoriesHash.MOBILE and not bp.CategoriesHash.EXPERIMENTAL then
                if bp.Intel.RadarStealth then continue end --skip everything that already has stealth of various kinds
                if not bp.Intel then bp.Intel = {} end
                bp.Intel.RadarStealth = true
                bp.Intel.RadarStealthTransFlag = true
            end
            
        end
    end
    
end