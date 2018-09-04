-----------------------------------------------------------------
-- File     :  /lua/sim/DefaultWeapons.lua
-- Author(s):  John Comes
-- Summary  :  Default definitions of weapons
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------


-- EQ: fixing weapon sounds not playing underwater
local oldDefaultProjectileWeapon = DefaultProjectileWeapon
DefaultProjectileWeapon = Class(oldDefaultProjectileWeapon) {
    -- This function creates the projectile, and happens when the unit is trying to fire
    -- Called from inside RackSalvoFiringState
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = self:CreateProjectileForWeapon(muzzle)
        if not proj or proj:BeenDestroyed() then
            return proj
        end

        local bp = self:GetBlueprint()
        if bp.DetonatesAtTargetHeight == true then
            local pos = self:GetCurrentTargetPos()
            if pos then
                local theight = GetSurfaceHeight(pos[1], pos[3])
                local hght = pos[2] - theight
                proj:ChangeDetonateAboveHeight(hght)
            end
        end
        if bp.Flare then
            proj:AddFlare(bp.Flare)
        end
        
        
        -- EQ:we assign the sound first then decide how to play it. this code could be refactored out in fa.
        -- only 2 units use FireUnderWater and neither are amphibious :/
        local sound
        local layer = self.unit:GetCurrentLayer()
        
        if  bp.Audio.FireUnderWater and (layer == 'Water' ) then
            sound = bp.Audio.FireUnderWater
        elseif bp.Audio.Fire then
            sound = bp.Audio.Fire
        end
        
        -- EQ: them being underwater makes the sounds not play, they have to be attached to some sound entity instead for that.
        if sound and (layer == 'Sub' or layer == 'Seabed') then
            local entity = self.unit:GetSoundEntity('WeaponSound')
            entity:PlaySound(sound)
        elseif sound then
            self:PlaySound(sound)
        end

        self:CheckBallisticAcceleration(proj)  -- Check weapon blueprint for trajectory fix request

        return proj
    end,

    --copy of the function in unit.lua maybe importing it is better instead?
    GetSoundEntity = function(self, type)
        if not self.Sounds then self.Sounds = {} end

        if not self.Sounds[type] then
            local sndEnt
            if self.SoundEntities[1] then
                sndEnt = table.remove(self.SoundEntities, 1)
            else
                sndEnt = Entity()
                Warp(sndEnt, self:GetPosition())
                sndEnt:AttachTo(self, -1)
                self.Trash:Add(sndEnt)
            end
            self.Sounds[type] = sndEnt
        end

        return self.Sounds[type]
    end,
}

--EQ: making compatible with released version, delete when faf beta OC is released.
local oldOverchargeWeapon = OverchargeWeapon
OverchargeWeapon = Class(oldOverchargeWeapon) {
    StartEconomyDrain = function(self) -- OverchargeWeapon drains energy on impact
    end,
}
