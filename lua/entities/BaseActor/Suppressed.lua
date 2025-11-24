// Time UnTil Which We are so Suppressed We can Only BlindFire
ENT.flSuppressedTime = 0
ENT.flShootTimeMin = 2
ENT.flShootTimeMax = 12

function ENT:CanExpose() return self.GAME_flSuppression <= self:Health() * self.flSuppressionHide end
function ENT:IsSuppressed() return self.GAME_flSuppression > self:Health() * self.flSuppressionHide end
function ENT:GetExposedWeight() return self.GAME_flSuppression end
