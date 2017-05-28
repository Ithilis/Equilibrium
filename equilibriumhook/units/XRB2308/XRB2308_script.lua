--****************************************************************************
--**
--**  File     :  /cdimage/units/XRB2205/XRB2205_script.lua
--**  Author(s):  Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Cybran Heavy Torpedo Launcher Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CKrilTorpedoLauncherWeapon = import('/lua/cybranweapons.lua').CKrilTorpedoLauncherWeapon

local oldXRB2308 = XRB2308
XRB2308 = Class(oldXRB2308) {
    -- Sink to the bottom, or to a pre-set depth
    DepthWatcher = function(self)
        self.sinkingFromBuild = true

        local sinkFor = 5.2 -- Use this to set the depth - Basic maths required - EQ: we increase this to a sane amount
        while self.sinkProjectile and sinkFor > 0 do
            WaitTicks(1)
            sinkFor = sinkFor - 0.1
        end

        local bottom = true
        if not self.Dead then
            if self.sinkProjectile then
                bottom = false -- We must have timed out
                self.sinkProjectile:Destroy()
                self.sinkProjectile = nil
            end

            -- Stop the unit's momentum
            self:SetPosition(self:GetPosition(), true)
            self:FinalAnimation()
        end

        self.sinkingFromBuild = false
        self.Bottom = bottom
    end,
}
TypeClass = XRB2308
