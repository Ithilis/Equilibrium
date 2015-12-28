local modpath = "/mods/abus[e]/"
local units = import('/mods/common/units.lua')


function init()
end


function getData()
	return {
		sleepTimer = 5,
	}
end


function perform()
	local jammingUnits = units.Get(categories.xel0209 + categories.ues0103 + categories.uea0305 + categories.uel0301 + categories.uel0301_IntelJammer)
	if table.getn(jammingUnits) > 0 then
		local currentBit = GetScriptBit(jammingUnits, 2)

		ToggleScriptBit(jammingUnits, 2, currentBit)
		WaitSeconds(0.2)
		currentBit = GetScriptBit(jammingUnits, 2)
		ToggleScriptBit(jammingUnits, 2, currentBit)
	end
end