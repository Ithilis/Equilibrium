local CollisionBeam = import('/lua/sim/CollisionBeam.lua').CollisionBeam
local EffectTemplate = import('/lua/EffectTemplates.lua')

EmptyCollisionBeam = Class(CollisionBeam) {
    FxImpactUnit = {},
    FxImpactLand = {},#EffectTemplate.DefaultProjectileLandImpact,
    FxImpactWater = EffectTemplate.DefaultProjectileWaterImpact,
    FxImpactUnderWater = EffectTemplate.DefaultProjectileUnderWaterImpact,
    FxImpactAirUnit = {},
    FxImpactProp = {},
    FxImpactShield = {},    
    FxImpactNone = {},
}

DummyCollisionBeam = Class(EmptyCollisionBeam) {
    FxBeam = {
		'/mods/Equilibrium/effects/emitters/dummybeam01.bp' --this emitter is actually invisible, so this beam is also completely invisible, unless you add stuff to it later on.
	}, --remember when moving this code anywhere to update this url, or it will break everything.
} -- todo: when moving this to release version replace Equilibrium with Equilibrium_Balance_Mod