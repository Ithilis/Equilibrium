--
-- Aeon Mortar - apparently
--

local SmartOverCharge = import('/lua/SmartOverCharge.lua').SmartOverCharge --import our OC code

local oldTDFOverCharge01 = TDFOverCharge01
oldTDFOverCharge01 = SmartOverCharge( oldTDFOverCharge01 )--inject our OC code here, so it damages dynamically


TDFOverCharge01 = Class(oldTDFOverCharge01) {
}

TypeClass = TDFOverCharge01

