--****************************************************************************
--**
--**  File     : /lua/wreckage.lua
--**
--**  Summary  : Class for wreckage so it can get pushed around
--**
--**  Copyright 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local OldWreckage = Wreckage

Wreckage = Class(OldWreckage) {
--we insert the flag in this function so we can catch it later.

    Rebuild = function(self, units)
        local rebuilders = {}
        local assisters = {}
        local bpid = self.AssociatedBP

        for _, u in units do
            if u:CanBuild(bpid) then
                table.insert(rebuilders, u)
            else
                table.insert(assisters, u)
            end
        end

        if not rebuilders[1] then return end
        local pos = self:GetPosition()
        for _, u in rebuilders do
            IssueBuildMobile({u}, pos, bpid, {})
            u.ShouldAssist = true --flag the units rebuilding the wreck as rebuilding it, so they can re-assist it when its finished.
        end
        if assisters[1] then
            IssueGuard(assisters, pos)
        end
    end,
}