
#
# Modified by Rienzilla 02/05/2013
# Modified again by Exotic_Retard 16/01/2016
#
# Modified to calculate the cost of an upgrade. The third argument is the economy section of 
# the unit that is currently upgrading into the new unit. We substract that cost from the cost 
# of the unit that is being built
#
# In order to keep backwards compatibility, there is a new option in the blueprint economy section.
# if DifferentialUpgradeCostCalculation is set to true, the base upgrade cost will be substracted

function GetConstructEconomyModel(builder, targetData, upgradeBaseData)

   local builder_bp = builder:GetBlueprint()
   
   # 'rate' here is how fast we build relative to a unit with build rate of 1
   local rate = builder:GetBuildRate()
   
   local buildtime = targetData.BuildTime or 0.1
   local mass = targetData.BuildCostMass or 0
   local energy = targetData.BuildCostEnergy or 0
   
   if upgradeBaseData and targetData.DifferentialUpgradeCostCalculation then

      --LOG("Doing differential upgrade cost calculation")
      --LOG(time, " ", mass, " ", energy)

      # We cant make a differential on buildtime. Not sure why but if we do it yields incorrect results. So just mass and energy
      # For some reason this worked when i tried it :/
      mass = mass - upgradeBaseData.BuildCostMass
      energy = energy - upgradeBaseData.BuildCostEnergy
      buildtime = buildtime - upgradeBaseData.BuildTime
      
      if mass < 0 then mass = 0 end
      if energy < 0 then energy = 0 end
      if buildtime < 0 then buildtime = 0 end

      --LOG(time, " ", mass, " ", energy)
   end

   # apply penalties/bonuses to effective buildtime
   local time_mod = builder.BuildTimeModifier or 0
   buildtime = buildtime * (100 + time_mod)*.01
   if buildtime<.1 then buildtime = .1 end
   
   # apply penalties/bonuses to effective energy cost
   local energy_mod = builder.EnergyModifier or 0
   energy = energy * (100 + energy_mod)*.01
   if energy<0 then energy = 0 end
   
   # apply penalties/bonuses to effective mass cost
   local mass_mod = builder.MassModifier or 0
   mass = mass * (100 + mass_mod)*.01
   if mass<0 then mass = 0 end
   
   return buildtime/rate, energy, mass
end


