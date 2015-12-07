
    ADFTractorClaw = Class(DefaultBeamWeapon) {
    BeamType = TractorClawCollisionBeam,
    FxMuzzleFlash = {},
   
    PlayFxBeamStart = function(self, muzzle)
        local target = self:GetCurrentTarget()
        
        -- Make absolutely certain that non-targetable units don't get caught
        if not target or
            EntityCategoryContains(categories.STRUCTURE, target) or
            EntityCategoryContains(categories.COMMAND, target) or
            EntityCategoryContains(categories.EXPERIMENTAL, target) or
            EntityCategoryContains(categories.NAVAL, target) or
            EntityCategoryContains(categories.SUBCOMMANDER, target) or
            not EntityCategoryContains(categories.ALLUNITS, target) then
            return
        end

        -- Ensure recon blips can't be the target
        target = self:GetRealTarget(target)
        
        -- Ensure that targets already targeted can't be hit twice
        if self:IsTargetAlreadyUsed(target) then 
            return 
        end
        
        -- Create visual effects for the target being sucked off the ground
        for k, v in EffectTemplate.ACollossusTractorBeamVacuum01 do
            CreateEmitterAtEntity(target, target:GetArmy(),v):ScaleEmitter(target:GetFootPrintSize()/2)
        end
        
        DefaultBeamWeapon.PlayFxBeamStart(self, muzzle)

        if not self.TT1 then
            self.TT1 = self:ForkThread(self.TractorThread, target)
            self:ForkThread(self.TractorWatchThread, target)
        else
            WARN('TT1 already exists')
        end
    end,

    -- Check for recon blips (aeonweapons.lua only)
    -- Returns the unit creating the blip if the blip and the source are close enough together
    GetRealTarget = function(self, target)
        if target and not IsUnit(target) then
            local unitTarget = target:GetSource() -- Find the unit creating the blip
            local unitPos = unitTarget:GetPosition() -- Find the position of that unit
            local reconPos = target:GetPosition() -- Find the position of the blip
            local dist = VDist2(unitPos[1], unitPos[3], reconPos[1], reconPos[3])
            if dist < 10 then
                return unitTarget
            end
        end
        return target
    end,
    
    -- Override this function in the unit to check if another weapon already has this
    -- unit as a target.  Target argument should not be a recon blip
    IsTargetAlreadyUsed = function(self, target)        
        -- Make a table with one value for each weapon, in this case 3 (See unit script)
        local weaponTable = {1, 2, 3}
    
        for k, v in weaponTable do
            v = self.unit:GetWeapon(v)
            if v ~= self then
                if self:GetRealTarget(v:GetCurrentTarget()) == target then
                    return true
                end
            end
        end
        return false
    end,

    OnLostTarget = function(self)
        self:AimManipulatorSetEnabled(true)
        DefaultBeamWeapon.OnLostTarget(self)
        DefaultBeamWeapon.PlayFxBeamEnd(self,self.Beams[1].Beam)
    end,

    -- The actual weapon thread including sliders
    TractorThread = function(self, target)
        self.unit.Trash:Add(target)
        local beam = self.Beams[1].Beam
        if not beam then return end

        local muzzle = self:GetBlueprint().MuzzleSpecial
        if not muzzle then return end

        local pos0 = beam:GetPosition(0)
        local pos1 = beam:GetPosition(1)
        local dist = VDist3(pos0, pos1) -- Length of the beam
        
        target:SetDoNotTarget(true)
        self.Slider = CreateSlider(self.unit, muzzle, 0, 0, dist, -1, true)
        
        WaitTicks(1)
        WaitFor(self.Slider)
        
        -- Just in case attach fails
        target:SetDoNotTarget(false)
        target:AttachBoneTo(-1, self.unit, muzzle)
        target:SetDoNotTarget(true) -- Make sure other units cease firing at the captured one
        self.AimControl:SetResetPoseTime(10)

        self.Slider:SetSpeed(15)
        self.Slider:SetGoal(0,0,0)
        WaitTicks(1)
        WaitFor(self.Slider)

        if not target:IsDead() then
            target.DestructionExplosionWaitDelayMin = 0
            target.DestructionExplosionWaitDelayMax = 0
            
            for kEffect, vEffect in EffectTemplate.ACollossusTractorBeamCrush01 do
                CreateEmitterAtBone(self.unit, muzzle , self.unit:GetArmy(), vEffect)
            end
            
            target:Destroy()
        end
        
        self.AimControl:SetResetPoseTime(2)
    end,

    TractorWatchThread = function(self, target)
        while not target:IsDead() do
            WaitTicks(1)
        end
        KillThread(self.TT1)
        self.TT1 = nil
        if self.Slider then
            self.Slider:Destroy()
            self.Slider = nil
        end
        self.unit:DetachAll(self:GetBlueprint().MuzzleSpecial or 0)
        DefaultBeamWeapon.PlayFxBeamEnd(self,self.Beams[1].Beam)
        self:ResetTarget()
        self.AimControl:SetResetPoseTime(2)
    end,
    }
    ADFTractorClawStructure = Class(DefaultBeamWeapon) {
    BeamType = TractorClawCollisionBeam,
    FxMuzzleFlash = {},
    }
