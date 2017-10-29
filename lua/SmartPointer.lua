--****************************************************************************
--**
--**  File     :  /lua/SmartPointer.lua
--**  Author(s):  Exotic_Retard for Equilibrium Balance mod
--**
--**  Summary  :  File that disables pointers on assist, so units dont get stuck trying to attack from a certain range.
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

function SmartPointer(SuperClass)
    return Class(SuperClass) {
        
        OnStopBeingBuilt = function(self,builder,layer)
            SuperClass.OnStopBeingBuilt(self,builder,layer)
            self.ShieldEffectsBag = {}
            
            self.TargetPointer = self:GetWeapon(1) --save the pointer weapon for later - this is extra clever since the pointer weapon has to be first!
            self.TargetLayerCaps = self:GetBlueprint().Weapon[1].FireTargetLayerCapsTable --we save this to the unit table so dont have to call every time.
            self.PointerEnabled = true --a flag to let our thread know whether we should turn on our pointer.
        end,
        
        DisablePointer = function(self)
            self.TargetPointer:SetFireTargetLayerCaps('None') --this disables the stop feature - note that its reset on layer change!
            self.PointerRestartThread = self:ForkThread( self.PointerRestart )
        end,
        
        PointerRestart = function(self)
        --sadly i couldnt find some way of doing this without a thread. dont know where to check if its still assisting other than this.
            while self.PointerEnabled == false do
                WaitSeconds(1)
                if not self:GetGuardedUnit() then
                    self.PointerEnabled = true
                    self.TargetPointer:SetFireTargetLayerCaps(self.TargetLayerCaps[self:GetCurrentLayer()]) --this resets the stop feature - note that its reset on layer change!
                end
            end
        end,
        
        OnLayerChange = function(self, new, old)
            SuperClass.OnLayerChange(self, new, old)
            
            if self.PointerEnabled == false then
                self.TargetPointer:SetFireTargetLayerCaps('None') --since its reset on layer change we need to do this. unfortunate.
            end
        end,
    }
end