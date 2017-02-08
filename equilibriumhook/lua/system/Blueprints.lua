
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
        end
    end
    
end