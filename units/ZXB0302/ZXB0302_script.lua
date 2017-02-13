#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB0301/UEB0301_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Helper factory for enabling mobile factories to build while moving
#**
#**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TMobileFactoryUnit = import('/lua/terranunits.lua').TMobileFactoryUnit

ZXB0301 = Class(TMobileFactoryUnit) {

    OnCreate = function(self)
        TMobileFactoryUnit.OnCreate(self)
        --make our factory invisible
        self:HideBone(0, true)
        self.DisallowCollisions = true
        --make it unkillable
        self:SetCanTakeDamage(false)
        self:SetCanBeKilled(false)
        
        self:SetCollisionShape('None')
    end,
    
    OnDestroy = function(self)
        --incase we delete our factory, since the unit being built isnt attached to it it doesnt always work.
        if self.AttachedFac then
            self.AttachedFac:Destroy()
        end
        TMobileFactoryUnit.OnDestroy(self)
    end,
}

TypeClass = ZXB0301
