#
# Terran Torpedo Bomb
#
local TTorpedoShipProjectile = import('/lua/terranprojectiles.lua').TTorpedoShipProjectile

TANAnglerTorpedo06 = Class(TTorpedoShipProjectile) 
{

    OnEnterWater = function(self)
        #TTorpedoShipProjectile.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 0.0) -- from 1 to stop aa from shooting it down, and its a depth charge anyway so no torp defense against it.
        local army = self:GetArmy()

        for k, v in self.FxEnterWater do #splash
            CreateEmitterAtEntity(self,army,v)
        end
        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(240)
        self:SetMaxSpeed(18)
        #self:SetVelocity(0)
        #self:ForkThread(self.MovementThread)
    end,

}

TypeClass = TANAnglerTorpedo06
