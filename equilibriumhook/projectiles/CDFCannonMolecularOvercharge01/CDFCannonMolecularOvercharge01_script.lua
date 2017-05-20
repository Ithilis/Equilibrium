--
-- Cybran Molecular Cannon
--
local SmartOverCharge = import('/lua/SmartOverCharge.lua').SmartOverCharge --import our OC code

local oldCDFCannonMolecular01 = CDFCannonMolecular01
oldCDFCannonMolecular01 = SmartOverCharge( oldCDFCannonMolecular01 )--inject our OC code here, so it damages dynamically


CDFCannonMolecular01 = Class(oldCDFCannonMolecular01) {
}
TypeClass = CDFCannonMolecular01

