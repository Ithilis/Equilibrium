local modPath = '/mods/EM/'
local Select = import('/mods/common/select.lua')
local Units = import('/mods/common/units.lua')

local CanUnpause = import(modPath .. 'modules/pause.lua').CanUnpause



---------------- In EQ we change the adjacency bonus so EM get tripped up by this when calculating the  bonus so we hook these two functions so its better.

function getMexes()
	local all_mexes = Units.Get(categories.MASSEXTRACTION * categories.STRUCTURE)
	local mexes = {all={}, upgrading={}, idle={}, assisted={}}

	mexes['all'] = all_mexes
	for _, mex in all_mexes do
		if not mex:IsDead() then
			data = Units.Data(mex)
            
			if data['is_idle'] then -- Idling mex, should be upgraded / paused
				for _, category in {categories.TECH1, categories.TECH2} do
					if EntityCategoryContains(category, mex) then
						if category == categories.TECH1 or data['bonus'] >= 1.16 then -- upgrade T1 and T2 with MS
							--table.insert(mexes['idle'][category], mex)
							table.insert(mexes['idle'], mex)
						end
					end
				end
			elseif mex:GetFocus() then
				table.insert(mexes['upgrading'], mex)

				if data['assisting'] > 0 and GetIsPaused({mex}) and CanUnpause(mex, 'mexes') then
					table.insert(mexes['assisted'], mex)
				end
			end
		end
	end

	return mexes
end

function UpdateMexOverlay(mex)
	local id = mex:GetEntityId()
	local data = Units.Data(mex)
	local tech = 0
	local color = 'green'

	if isMexBeingBuilt(mex) then
		return false
	end

	if not overlays[id] then
		overlays[id] = CreateMexOverlay(mex)
	end

	local overlay = overlays[id]

	if EntityCategoryContains(categories.TECH1, mex) then
		tech = 1
	elseif EntityCategoryContains(categories.TECH2, mex) then
		tech = 2
	else
		tech = 3
	end

	if data['is_idle'] or (mex:GetWorkProgress() < 0.02) then
    
		if(tech >= 2 and data['bonus'] < 1.16) then
			color = 'red'
		elseif(tech == 3) then
			color = 'white'
		else
			color = 'green'
		end
	else
		color = 'yellow'
	end

	overlay.text:SetColor(color)
	overlay.text:SetText(tech)
end
