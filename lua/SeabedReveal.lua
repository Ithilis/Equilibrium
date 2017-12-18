--****************************************************************************
--**
--**  File     :  /lua/SeabedReveal.lua
--**  Author(s):  Exotic_Retard, written for Equilibrium Balance mod
--**
--**  Summary  :  A method of revealing a unit when they fire their weapon from the seabed layer.
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

--how to set this up:
--apply SeabedReveal to the unit weapon class inside the unit script, can do multiple if you want
--apply SeabedRevealUnit to the unit class inside its script
--how this works:
--1. units on the seabed fire their weapon, and flag all units around them
--2. these units get watervision equal to their normal vision so they can see what fired on them
--3. they also get a timestamp each and are stored into a table containing all changed units
--4. a global thread checks the table every second and removes the effect for expired timestamps.
--5. profit?


local SeabedRevealingUnits = import('/lua/scenarioFramework.lua').SeabedRevealingUnits --import our table for storing units

--apply to weapon
function SeabedReveal(SuperClass)
    return Class(SuperClass) {
    
        OnCreate = function(self)
            SuperClass.OnCreate(self)
            local bp = self:GetBlueprint()
            self.RevealRadius = bp.MaxRadius
            --ShouldRevealSeabed is for permanent toggles, revealseabed is for the timer thread
            --we set revealseabed here for the initial toggle
            if self.unit:GetCurrentLayer() == 'Seabed' then
                self.unit.ShouldRevealSeabed = true
                self.RevealSeabed = true
            else
                self.unit.ShouldRevealSeabed = false
                self.RevealSeabed = false
            end
        end,
        
        CreateProjectileAtMuzzle = function(self, muzzle)
            SuperClass.CreateProjectileAtMuzzle(self, muzzle)
            self:FlagReveal()
        end,
        
        FlagReveal = function(self) --this reveals ourselves to surrounding units and flags them for a global thread to deactivate later.
            if self.unit.ShouldRevealSeabed == true then
                if self.RevealSeabed == true then
                    --WARN('flagging reveal')
                    --here we find all the units in range of ours, that could be affected, and give them watervision radius equal to their visionradius for a time.
                    local aiBrain = self.unit:GetAIBrain()
                    local units = aiBrain:GetUnitsAroundPoint(categories.STRUCTURE + categories.MOBILE, self.unit:GetPosition(), self.RevealRadius, 'Enemy')
                    local tick = GetGameTick() + 1 --for some reason the timer ends a tick early but w.e.
                    
                    for k, unit in units do
                        unit.WVizEndTick = tick + 80 --we need to have some fancy timers since we want to reset the duration, and for this to transcend any threading
                        
                        --only mess with the units that we havent touched before
                        if not unit.NormalWVision then
                            unit.NormalWVision = unit:GetIntelRadius('watervision') --we store the old value so we can revert it later
                            unit:SetIntelRadius('watervision', unit:GetIntelRadius('vision'))
                            --WARN(unit.NormalWVision)
                            table.insert(SeabedRevealingUnits, unit) --insert our unit into a table to be monitored later
                        end
                    end
                    
                end
                
                --this stops us from spamming the vision changes too much.
                if not self.TimerThread then
                    --WARN('starting cooldownthread')
                    self.TimerThread = self:ForkThread(self.CooldownThread)
                end
            end
        end,
        
        --make sure this isnt done too often
        CooldownThread = function(self)
            self.RevealSeabed = false
            WaitSeconds(2)
            self.RevealSeabed = true
        end,
        
    }    
end

--apply to unit
function SeabedRevealUnit(SuperClass)
    return Class(SuperClass) {
        
        OnLayerChange = function(self, new, old)
            SuperClass.OnLayerChange(self, new, old)
            --WARN('new layer: '..new)
            --we need to only do all that revealing code if we are on the seabed.
            if new == 'Seabed'  then
                self.ShouldRevealSeabed = true
            else
                self.ShouldRevealSeabed = false
            end
        end,

    }    
end
