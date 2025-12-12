// Time until which we are so suppressed that we can only blindfire
ENT.flSuppressedTime = 0
ENT.flShootTimeMin = 2
ENT.flShootTimeMax = 12

function ENT:CanExpose() return self.GAME_flSuppression <= self:Health() * self.flSuppressionHide end
function ENT:IsSuppressed() return self.GAME_flSuppression > self:Health() * self.flSuppressionHide end
function ENT:GetExposedWeight() return self.GAME_flSuppression end
